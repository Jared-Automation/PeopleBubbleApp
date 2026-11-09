import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/app_database.dart';
import 'package:people_bubble/data/graph_dump.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/services/graph_service.dart';
import 'package:people_bubble/services/sample_data.dart';

void main() {
  late AppDatabase db;
  late GraphService g;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    g = GraphService(db);
  });
  tearDown(() => db.close());

  /// Every row in the database, for before/after comparisons.
  Future<GraphDump> dump() => readDump(db);

  void expectSameRows(GraphDump a, GraphDump b) => expect(
    diffDumps(a, b).isEmpty,
    isTrue,
    reason: '${diffDumps(a, b).tables}',
  );

  test('a write is recorded with a label; undo and redo replay it', () async {
    final start = await dump();
    final sam = await g.createNode(label: 'Sam', typeIds: [SeedIds.person]);
    final afterAdd = await dump();
    expect(g.history.state.value.undoLabel, 'add “Sam”');

    expect(await g.undo(), 'add “Sam”');
    expectSameRows(await dump(), start);
    expect(g.history.state.value.canUndo, isFalse);
    expect(g.history.state.value.redoLabel, 'add “Sam”');

    expect(await g.redo(), 'add “Sam”');
    expectSameRows(await dump(), afterAdd);
    expect((await dump())['nodes'].containsKey(sam), isTrue);
  });

  test(
    'undoing a delete brings back the bubble, its lines and waypoints',
    () async {
      final sam = await g.createNode(label: 'Sam', x: 0, y: 0);
      final tea = await g.createChildNode(
        parentId: sam,
        label: 'Tea',
        edgeTypeId: SeedIds.likes,
      );
      await g.addWaypoint(tea.edgeId, index: 0, at: const Point(5, 5));
      await g.updateNode(tea.nodeId, typeIds: [SeedIds.thing]);
      final before = await dump();

      await g.deleteNode(sam);
      expect((await dump())['edges'], isEmpty);
      expect(g.history.state.value.undoLabel, 'delete “Sam”');

      await g.undo();
      expectSameRows(await dump(), before);
    },
  );

  test('every step can be undone back to the start, then redone', () async {
    final start = await dump();
    final sam = await g.createNode(label: 'Sam', x: 0, y: 0);
    final pie = await g.createChildNode(
      parentId: sam,
      label: 'Pie',
      edgeTypeId: SeedIds.likes,
    );
    await g.moveNode(sam, 40, 50);
    await g.reverseEdge(pie.edgeId);
    final w = await g.addWaypoint(pie.edgeId, index: 0, at: const Point(1, 2));
    await g.moveWaypoint(w, const Point(3, 4));
    final gamer = await g.createNodeType(
      name: 'Gamer',
      parentId: SeedIds.person,
    );
    await g.updateNode(sam, label: 'Samantha', typeIds: [gamer]);
    await g.deleteNodeType(gamer);
    final end = await dump();

    while (await g.undo() != null) {}
    expectSameRows(await dump(), start);
    while (await g.redo() != null) {}
    expectSameRows(await dump(), end);
  });

  test('a new write clears redo', () async {
    await g.createNode(label: 'A');
    await g.undo();
    expect(g.history.state.value.canRedo, isTrue);
    await g.createNode(label: 'B');
    expect(g.history.state.value.canRedo, isFalse);
  });

  test('refused writes and no-op writes add no step', () async {
    await expectLater(g.createNode(label: '  '), throwsA(isA<InvalidInput>()));
    expect(g.history.state.value.canUndo, isFalse);
  });

  test('history keeps only the newest 50 steps', () async {
    for (var i = 0; i < 55; i++) {
      await g.createNode(label: 'N$i');
    }
    var count = 0;
    while (await g.undo() != null) {
      count++;
    }
    expect(count, 50);
    expect((await dump())['nodes'].length, 5);
  });

  test('a group is one step', () async {
    final start = await dump();
    await g.group('paste 3 bubbles', () async {
      for (final name in ['A', 'B', 'C']) {
        await g.createNode(label: name);
      }
    });
    expect(g.history.state.value.undoLabel, 'paste 3 bubbles');
    await g.undo();
    expectSameRows(await dump(), start);
    expect(g.history.state.value.canUndo, isFalse);
  });

  test('loading the sample as a group can be undone in one step', () async {
    final start = await dump();
    await g.group('load sample data', () => loadSampleData(g));
    expect((await dump())['nodes'], isNotEmpty);
    await g.undo();
    expectSameRows(await dump(), start);
  });

  test('auto-placement folds into the step that made the bubble', () async {
    final sam = await g.createNode(label: 'Sam');
    await g.placeNodes({sam: const Point(10, 20)});
    expect(g.history.state.value.undoLabel, 'add “Sam”');

    await g.undo();
    expect((await dump())['nodes'], isEmpty);
    await g.redo();
    final row = (await dump())['nodes'][sam]!;
    expect([row['x'], row['y']], [10.0, 20.0], reason: 'redo keeps the spot');
  });

  test('undo refuses (and clears history) if the rows changed since', () async {
    final sam = await g.createNode(label: 'Sam');
    // A write that bypasses the service, as a stand-in for any surprise.
    await db.customUpdate("UPDATE nodes SET label = 'X' WHERE id = '$sam'");
    await expectLater(g.undo(), throwsA(isA<InvalidInput>()));
    expect(g.history.state.value.canUndo, isFalse);
    expect((await dump())['nodes'][sam]!['label'], 'X', reason: 'untouched');
  });
}
