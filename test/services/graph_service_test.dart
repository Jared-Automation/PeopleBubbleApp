import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/app_database.dart';
import 'package:people_bubble/data/graph_reader.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/domain/graph.dart';
import 'package:people_bubble/domain/style.dart';
import 'package:people_bubble/services/graph_service.dart';
import 'package:people_bubble/services/sample_data.dart';

void main() {
  late AppDatabase db;
  late GraphService g;
  late GraphReader reader;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    g = GraphService(db);
    reader = GraphReader(db);
  });
  tearDown(() => db.close());

  Future<GraphSnapshot> snap() => reader.load();

  test('a new database has the seed types and no nodes', () async {
    final s = await snap();
    expect(s.nodes, isEmpty);
    expect(s.nodeTypes.base?.id, SeedIds.nodeBase);
    expect(s.edgeTypes.base?.id, SeedIds.edgeBase);
    expect(s.edgeTypes.isAncestor(SeedIds.likes, SeedIds.loves), isTrue);
    expect(s.edgeTypes.resolve([SeedIds.related]).hierarchical, isFalse);
  });

  group('nodes', () {
    test('created without types fall back to base Node, unplaced', () async {
      final id = await g.createNode(label: '  Sam ');
      final s = await snap();
      expect(s.nodes[id]!.label, 'Sam');
      expect(s.nodes[id]!.typeIds, isEmpty);
      expect(s.nodes[id]!.isPlaced, isFalse);
      expect(s.styleOf(s.nodes[id]!), NodeStyle.appDefaults);
    });

    test('empty labels are refused', () {
      expect(g.createNode(label: '  '), throwsA(isA<InvalidInput>()));
    });

    test('redundant ancestor types are dropped', () async {
      final id = await g.createNode(
        label: 'Sam',
        typeIds: [SeedIds.nodeBase, SeedIds.person],
      );
      expect((await snap()).nodes[id]!.typeIds, [SeedIds.person]);
    });

    test('conflicting types are refused with a readable reason', () async {
      final partner = await g.createNodeType(
        name: 'Partner',
        parentId: SeedIds.person,
        style: const NodeStyle(outlineColor: 1),
      );
      final friend = await g.createNodeType(
        name: 'Friend',
        parentId: SeedIds.person,
        style: const NodeStyle(outlineColor: 2),
      );
      await expectLater(
        g.createNode(label: 'X', typeIds: [partner, friend]),
        throwsA(
          isA<TypeConflictBlocked>().having(
            (e) => e.message,
            'message',
            contains('Partner and Friend both set outline color'),
          ),
        ),
      );
      expect((await snap()).nodes, isEmpty, reason: 'nothing half-written');
    });
  });

  group('edges', () {
    late String sam, coffee, latte;
    setUp(() async {
      sam = await g.createNode(label: 'Sam');
      coffee = await g.createNode(label: 'Coffee');
      latte = await g.createNode(label: 'Latte');
      await g.createEdge(
        sourceId: sam,
        targetId: coffee,
        typeId: SeedIds.loves,
      );
      await g.createEdge(
        sourceId: coffee,
        targetId: latte,
        typeId: SeedIds.likes,
      );
    });

    test('a hierarchical loop is blocked', () async {
      await expectLater(
        g.createEdge(sourceId: latte, targetId: sam, typeId: SeedIds.likes),
        throwsA(isA<CycleBlocked>()),
      );
    });

    test('a non-hierarchical edge may point back up', () async {
      await g.createEdge(
        sourceId: latte,
        targetId: sam,
        typeId: SeedIds.related,
      );
      expect((await snap()).edges, hasLength(3));
    });

    test('a self-link is refused', () async {
      await expectLater(
        g.createEdge(sourceId: sam, targetId: sam, typeId: SeedIds.related),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('changing a Related edge to Likes is checked for loops', () async {
      final back = await g.createEdge(
        sourceId: latte,
        targetId: sam,
        typeId: SeedIds.related,
      );
      await expectLater(
        g.setEdgeType(back, SeedIds.likes),
        throwsA(isA<CycleBlocked>()),
      );
    });

    test('a shared child is allowed', () async {
      final priya = await g.createNode(label: 'Priya');
      await g.createEdge(
        sourceId: priya,
        targetId: coffee,
        typeId: SeedIds.likes,
      );
      final s = await snap();
      expect(s.roots.map((n) => n.label), unorderedEquals(['Sam', 'Priya']));
    });

    test('per-edge overrides cannot change hierarchy', () async {
      final id = (await snap()).edges.keys.first;
      await g.setEdgeOverrides(
        id,
        const EdgeStyle(width: 5, hierarchical: false),
      );
      final s = await snap();
      expect(s.edges[id]!.overrides, const EdgeStyle(width: 5));
      expect(s.isHierarchical(s.edges[id]!), isTrue);
    });
  });

  group('delete', () {
    test(
      'deleting a node removes its edges, links and orphan waypoints',
      () async {
        final a = await g.createNode(label: 'A', typeIds: [SeedIds.person]);
        final b = await g.createNode(label: 'B');
        final c = await g.createNode(label: 'C');
        final ab = await g.createEdge(
          sourceId: a,
          targetId: b,
          typeId: SeedIds.likes,
        );
        final cb = await g.createEdge(
          sourceId: c,
          targetId: b,
          typeId: SeedIds.likes,
        );
        // Waypoints arrive in Phase 7; insert directly. w1 is used only by a→b,
        // w2 is shared (clamped) by both edges.
        await db.batch((batch) {
          batch.insertAll(db.waypoints, [
            WaypointsCompanion.insert(id: const Value('w1'), x: 0, y: 0),
            WaypointsCompanion.insert(id: const Value('w2'), x: 1, y: 1),
          ]);
          batch.insertAll(db.edgeWaypoints, [
            EdgeWaypointsCompanion.insert(
              edgeId: ab,
              waypointId: 'w1',
              position: 0,
            ),
            EdgeWaypointsCompanion.insert(
              edgeId: ab,
              waypointId: 'w2',
              position: 1,
            ),
            EdgeWaypointsCompanion.insert(
              edgeId: cb,
              waypointId: 'w2',
              position: 0,
            ),
          ]);
        });

        await g.deleteNode(a);

        final s = await snap();
        expect(s.nodes.keys, unorderedEquals([b, c]));
        expect(s.edges.keys, [cb]);
        expect(s.waypoints.keys, ['w2']);
        expect(await db.select(db.nodeTypeLinks).get(), isEmpty);
      },
    );
  });

  group('type edits', () {
    test(
      'an edit that would break existing nodes is blocked and lists them',
      () async {
        final partner = await g.createNodeType(
          name: 'Partner',
          parentId: SeedIds.person,
          style: const NodeStyle(outlineColor: 1),
        );
        final gamer = await g.createNodeType(
          name: 'Board Gamer',
          parentId: SeedIds.person,
          style: const NodeStyle(outlineStyle: LineStyle.dotted),
        );
        final sam = await g.createNode(label: 'Sam', typeIds: [partner, gamer]);

        await expectLater(
          g.updateNodeType(gamer, style: const NodeStyle(outlineColor: 2)),
          throwsA(
            isA<TypeEditBlocked>()
                .having((e) => e.affectedNodeIds, 'nodes', [sam])
                .having((e) => e.message, 'message', contains('Sam')),
          ),
        );
        // A harmless edit goes through.
        await g.updateNodeType(gamer, style: const NodeStyle(bold: true));
      },
    );

    test('a type cannot become its own ancestor', () async {
      await expectLater(
        g.updateNodeType(SeedIds.person, parentId: SeedIds.person),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
      'making Related hierarchical is blocked if it would form a loop',
      () async {
        final a = await g.createNode(label: 'A');
        final b = await g.createNode(label: 'B');
        await g.createEdge(sourceId: a, targetId: b, typeId: SeedIds.likes);
        await g.createEdge(sourceId: b, targetId: a, typeId: SeedIds.related);
        await expectLater(
          g.updateEdgeType(
            SeedIds.related,
            style: const EdgeStyle(hierarchical: true),
          ),
          throwsA(isA<CycleBlocked>()),
        );
      },
    );
  });

  group('sample data', () {
    test('loads through the service and can be cleared', () async {
      await loadSampleData(g);
      var s = await snap();
      expect(s.nodes.length, 21);
      final sushi = s.nodes.values.firstWhere((n) => n.label == 'Sushi');
      final parents = s.hierarchicalEdges.where((e) => e.targetId == sushi.id);
      expect(parents, hasLength(2), reason: 'Sushi is shared');
      expect(
        graphHasCycle([
          for (final e in s.hierarchicalEdges) (e.sourceId, e.targetId),
        ]),
        isFalse,
      );

      await g.clearAllData();
      s = await snap();
      expect(s.nodes, isEmpty);
      expect(
        s.nodeTypes.byId.keys,
        unorderedEquals([SeedIds.nodeBase, SeedIds.person, SeedIds.thing]),
      );
    });

    test('large sample has about 300 nodes', () async {
      await loadLargeSample(g);
      expect((await snap()).nodes.length, 300);
    });
  });
}
