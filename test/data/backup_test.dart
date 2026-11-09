import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/app_database.dart';
import 'package:people_bubble/data/graph_dump.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/services/graph_service.dart';
import 'package:people_bubble/services/sample_data.dart';

/// A phone: its own database and service.
class Device {
  Device() : db = AppDatabase(NativeDatabase.memory()) {
    g = GraphService(db);
  }

  final AppDatabase db;
  late final GraphService g;

  Future<GraphDump> dump() => readDump(db);
  Future<void> close() => db.close();
}

void expectSameRows(GraphDump a, GraphDump b) {
  final diff = diffDumps(a, b);
  expect(diff.isEmpty, isTrue, reason: '${diff.tables}');
}

void main() {
  // Two phones means two in-memory databases at once, on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Device phone, other;
  setUp(() {
    phone = Device();
    other = Device();
  });
  tearDown(() async {
    await phone.close();
    await other.close();
  });

  Future<Map<String, Object?>> exportJson(Device d) async =>
      jsonDecode(await d.g.exportBackup()) as Map<String, Object?>;

  test('export, then replace on another phone: identical rows', () async {
    await loadSampleData(phone.g);
    final ids = (await phone.dump())['edges'].keys.take(2).toList();
    await phone.g.addWaypoint(ids[0], index: 0, at: const Point(1, 2));
    await other.g.createNode(label: 'Only here');

    final file = other.g.readBackup(await phone.g.exportBackup());
    expect(file.badRows, 0);
    final report = await other.g.importBackup(file, replace: true);

    expectSameRows(await other.dump(), await phone.dump());
    expect(report.changes['nodes']!.removed, 1, reason: 'Only here went');
    expect(report.summary, contains('bubbles added'));
  });

  test('the file is readable JSON with styles as objects', () async {
    await phone.g.createNode(label: 'Sam', typeIds: [SeedIds.person]);
    final json = await exportJson(phone);
    expect(json['app'], 'people_bubble');
    expect(json['schemaVersion'], phone.db.schemaVersion);
    final tables = json['tables']! as Map<String, Object?>;
    final types = tables['node_types']! as List<Object?>;
    final person =
        types.firstWhere((t) => (t! as Map)['id'] == SeedIds.person)! as Map;
    expect(person['style'], isA<Map<String, Object?>>());
    expect((person['style'] as Map)['shape'], 'roundedRect');
  });

  test('an import is one undoable step', () async {
    await other.g.createNode(label: 'Mine');
    final before = await other.dump();
    await phone.g.createNode(label: 'Theirs');
    final file = other.g.readBackup(await phone.g.exportBackup());

    await other.g.importBackup(file, replace: true);
    expect(other.g.history.state.value.undoLabel, 'replace with backup');
    await other.g.undo();
    expectSameRows(await other.dump(), before);
  });

  group('merge', () {
    test('keeps local-only items and adds new ones', () async {
      final mine = await other.g.createNode(label: 'Mine');
      final theirs = await phone.g.createNode(label: 'Theirs');
      final file = other.g.readBackup(await phone.g.exportBackup());

      final report = await other.g.importBackup(file, replace: false);
      final nodes = (await other.dump())['nodes'];
      expect(nodes.keys, containsAll([mine, theirs]));
      expect(report.summary, '1 bubble added');
    });

    test('the newer edit of the same bubble wins, with its types', () async {
      // Same bubble on both phones (copied over), then edited on each.
      final sam = await phone.g.createNode(label: 'Sam');
      await other.g.importBackup(
        other.g.readBackup(await phone.g.exportBackup()),
        replace: true,
      );
      await other.g.updateNode(sam, label: 'Sam (old edit)');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await phone.g.updateNode(
        sam,
        label: 'Sam (new edit)',
        typeIds: [SeedIds.person],
      );

      await other.g.importBackup(
        other.g.readBackup(await phone.g.exportBackup()),
        replace: false,
      );
      final s = await other.dump();
      expect(s['nodes'][sam]!['label'], 'Sam (new edit)');
      expect(s['node_type_links'].values.map((l) => l['type_id']), [
        SeedIds.person,
      ]);

      // Merging the older copy back the other way changes nothing.
      await other.g.updateNode(sam, label: 'Sam (newest)');
      final report = await other.g.importBackup(
        other.g.readBackup(await phone.g.exportBackup()),
        replace: false,
      );
      expect((await other.dump())['nodes'][sam]!['label'], 'Sam (newest)');
      expect(report.summary, startsWith('Nothing new'));
    });
  });

  group('checks', () {
    BackupFile read(Object json) =>
        phone.g.readBackup(json is String ? json : jsonEncode(json));

    test('refuses files that aren\'t backups', () {
      expect(() => read('not json {'), throwsA(isA<BackupRejected>()));
      expect(() => read({'hello': 1}), throwsA(isA<BackupRejected>()));
    });

    test('refuses a backup from a newer schema', () async {
      final json = await exportJson(phone);
      json['schemaVersion'] = phone.db.schemaVersion + 1;
      expect(
        () => read(json),
        throwsA(
          isA<BackupRejected>().having(
            (e) => e.message,
            'message',
            contains('newer'),
          ),
        ),
      );
    });

    test('drops malformed rows and rows pointing at missing items', () async {
      final sam = await phone.g.createNode(label: 'Sam');
      await phone.g.createChildNode(
        parentId: sam,
        label: 'Tea',
        edgeTypeId: SeedIds.likes,
      );
      final json = await exportJson(phone);
      final tables = json['tables']! as Map<String, Object?>;
      final nodes = tables['nodes']! as List<Object?>;
      // A bubble with no label, and the line from Sam to a missing bubble.
      nodes.add({'id': 'broken', 'x': 'left'});
      nodes.removeWhere((n) => (n! as Map)['label'] == 'Tea');

      final file = read(json);
      expect(file.badRows, 1);
      final report = await other.g.importBackup(file, replace: true);
      expect(report.skipped, 1, reason: 'the line to Tea');
      expect(report.summary, contains('2 items skipped'));
      final s = await other.dump();
      expect(s['nodes'].values.map((n) => n['label']), ['Sam']);
      expect(s['edges'], isEmpty);
    });

    test('replace keeps built-in types even if the file lacks them', () async {
      final json = await exportJson(phone);
      (json['tables']! as Map)['edge_types'] = <Object?>[];
      await other.g.importBackup(read(json), replace: true);
      expect((await other.dump())['edge_types'], isNotEmpty);
    });
  });
}
