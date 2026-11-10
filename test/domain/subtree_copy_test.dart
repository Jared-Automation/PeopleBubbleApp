import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/graph.dart';
import 'package:people_bubble/domain/style.dart';
import 'package:people_bubble/domain/subtree_copy.dart';

import 'fixtures.dart';

GraphEdge e(
  String id,
  String from,
  String to, {
  String type = 'likes',
  List<String> bends = const [],
}) => GraphEdge(
  id: id,
  sourceId: from,
  targetId: to,
  typeId: type,
  waypointIds: bends,
);

void main() {
  // Sam → {Sushi → Salmon, Tea}; Sushi → Tea too (Tea shared inside);
  // Priya → Tea (outside parent); Salmon ~ Priya (Related, to outside).
  final s = GraphSnapshot(
    nodes: const [
      GraphNode(
        id: 'sam',
        label: 'Sam',
        typeIds: ['partner'],
        x: 0,
        y: 0,
        overrides: NodeStyle(hidden: true),
      ),
      GraphNode(id: 'sushi', label: 'Sushi', x: 0, y: 100),
      GraphNode(id: 'salmon', label: 'Salmon', x: 0, y: 200),
      GraphNode(id: 'tea', label: 'tea', x: 100, y: 100),
      GraphNode(id: 'priya', label: 'Priya', x: 300, y: 0),
    ],
    edges: [
      e('e1', 'sam', 'sushi', bends: ['w1']),
      e('e2', 'sushi', 'salmon'),
      e('e3', 'sam', 'tea'),
      e('e4', 'sushi', 'tea', bends: ['w1']),
      e('e5', 'priya', 'tea'),
      e('e6', 'salmon', 'priya', type: 'related'),
    ],
    waypoints: const [GraphWaypoint(id: 'w1', x: 10, y: 50)],
    nodeTypes: canonicalNodeTypes,
    edgeTypes: canonicalEdgeTypes,
  );

  test('copies the bubble, everything under it, and the lines between', () {
    final copy = copySubtree(s, 'sam');
    expect(copy.nodes.keys, unorderedEquals(['sam', 'sushi', 'salmon', 'tea']));
    expect(copy.belowCount, 3);
    expect(
      copy.edges.map((c) => '${c.sourceId}>${c.targetId}'),
      unorderedEquals(['sam>sushi', 'sushi>salmon', 'sam>tea', 'sushi>tea']),
      reason: 'lines to Priya (outside) are left behind',
    );
    expect(copy.root.typeIds, ['partner']);
    expect(copy.root.overrides, const NodeStyle(hidden: true));
  });

  test('keeps shared bends shared', () {
    final copy = copySubtree(s, 'sam');
    expect(copy.waypoints.keys, ['w1']);
    expect(copy.edges.where((c) => c.waypointIds.contains('w1')).length, 2);
  });

  test('outline lists each bubble once, children A–Z', () {
    expect(copySubtree(s, 'sam').outline, 'Sam\n  Sushi\n    Salmon\n    tea');
  });

  test('a leaf copies alone', () {
    final copy = copySubtree(s, 'salmon');
    expect(copy.nodes.keys, ['salmon']);
    expect(copy.edges, isEmpty);
    expect(copy.outline, 'Salmon');
  });

  test('looped data does not hang', () {
    final loop = GraphSnapshot(
      nodes: const [
        GraphNode(id: 'a', label: 'A'),
        GraphNode(id: 'b', label: 'B'),
      ],
      edges: [e('e1', 'a', 'b'), e('e2', 'b', 'a')],
      nodeTypes: canonicalNodeTypes,
      edgeTypes: canonicalEdgeTypes,
    );
    final copy = copySubtree(loop, 'a');
    expect(copy.nodes.length, 2);
    expect(copy.outline, 'A\n  B');
  });
}
