import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/app_database.dart';
import 'package:people_bubble/data/graph_dump.dart';
import 'package:people_bubble/data/graph_reader.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/domain/graph.dart';
import 'package:people_bubble/domain/style.dart';
import 'package:people_bubble/domain/subtree_copy.dart';
import 'package:people_bubble/services/graph_service.dart';

void main() {
  late AppDatabase db;
  late GraphService g;
  late String sam, sushi, tea, jade;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    g = GraphService(db);
    // Sam (0,0) → Sushi (0,100) [bent at (20,50), labelled] and Tea
    // (100,100); Jade (500,0) on her own.
    sam = await g.createNode(
      label: 'Sam',
      typeIds: [SeedIds.person],
      x: 0,
      y: 0,
    );
    await g.setNodeOverrides(sam, const NodeStyle(fillColor: 0xFFFFEB3B));
    sushi = await g.createNode(label: 'Sushi', x: 0, y: 100);
    tea = await g.createNode(label: 'Tea', x: 100, y: 100);
    final e1 = await g.createEdge(
      sourceId: sam,
      targetId: sushi,
      typeId: SeedIds.loves,
      label: 'so much',
    );
    await g.addWaypoint(e1, index: 0, at: const Point(20, 50));
    await g.createEdge(sourceId: sam, targetId: tea, typeId: SeedIds.likes);
    jade = await g.createNode(label: 'Jade', x: 500, y: 0);
  });
  tearDown(() => db.close());

  Future<GraphSnapshot> snap() => GraphReader(db).load();

  GraphNode only(GraphSnapshot s, String label, {String? not}) =>
      s.nodes.values.where((n) => n.label == label && n.id != not).single;

  test('paste at a spot: new bubbles, same layout moved there', () async {
    final copy = copySubtree(await snap(), sam);
    final newSam = await g.pasteSubtree(copy, at: const Point(1000, 1000));

    final s = await snap();
    expect(s.nodes.length, 7, reason: '4 + Sam, Sushi, Tea copies');
    final samCopy = s.nodes[newSam]!;
    expect([samCopy.x, samCopy.y], [1000, 1000]);
    expect(samCopy.typeIds, [SeedIds.person]);
    expect(samCopy.overrides, const NodeStyle(fillColor: 0xFFFFEB3B));
    final sushiCopy = only(s, 'Sushi', not: sushi);
    expect([sushiCopy.x, sushiCopy.y], [1000, 1100]);

    final line = s.edges.values.singleWhere(
      (e) => e.sourceId == newSam && e.targetId == sushiCopy.id,
    );
    expect(line.typeId, SeedIds.loves);
    expect(line.label, 'so much');
    final bend = s.waypoints[line.waypointIds.single]!;
    expect([bend.x, bend.y], [1020, 1050]);
    expect(s.roots.map((n) => n.id), contains(newSam), reason: 'top level');
  });

  test('paste under a bubble: linked, and left for auto-placement', () async {
    final copy = copySubtree(await snap(), sam);
    final newSam = await g.pasteSubtree(
      copy,
      parentId: jade,
      edgeTypeId: SeedIds.likes,
    );

    final s = await snap();
    final link = s.edges.values.singleWhere((e) => e.targetId == newSam);
    expect(link.sourceId, jade);
    expect(link.typeId, SeedIds.likes);
    for (final id in subtreeOf(s, newSam)) {
      expect(s.nodes[id]!.isPlaced, isFalse, reason: s.nodes[id]!.label);
    }
    final copiedLines = s.edges.values.where((e) => e.sourceId == newSam);
    expect(copiedLines.length, 2);
    expect(copiedLines.every((e) => e.waypointIds.isEmpty), isTrue);
    // The originals are untouched.
    expect(s.nodes[sam]!.x, 0);
    expect(s.edges.values.where((e) => e.sourceId == sam).length, 2);
  });

  test('a paste is one undo step', () async {
    final before = await readDump(db);
    await g.pasteSubtree(copySubtree(await snap(), sam), at: const Point(9, 9));
    expect(g.history.state.value.undoLabel, 'paste “Sam”');
    await g.undo();
    expect(diffDumps(before, await readDump(db)).isEmpty, isTrue);
  });

  test('types deleted since the copy are dropped', () async {
    final gamer = await g.createNodeType(
      name: 'Gamer',
      parentId: SeedIds.person,
    );
    await g.updateNode(tea, typeIds: [gamer]);
    final copy = copySubtree(await snap(), sam);
    await g.deleteNodeType(gamer);

    await g.pasteSubtree(copy, parentId: jade, edgeTypeId: SeedIds.likes);
    final teaCopy = only(await snap(), 'Tea', not: tea);
    expect(teaCopy.typeIds, isEmpty);
  });

  test('refused under a bubble that no longer exists', () async {
    final copy = copySubtree(await snap(), sam);
    await g.deleteNode(jade);
    await expectLater(
      g.pasteSubtree(copy, parentId: jade, edgeTypeId: SeedIds.likes),
      throwsA(isA<InvalidInput>()),
    );
    expect((await snap()).nodes.length, 3, reason: 'nothing half-pasted');
  });
}
