import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/graph.dart';
import 'package:people_bubble/domain/list_tree.dart';

import 'fixtures.dart';

GraphEdge e(String id, String from, String to, String type) =>
    GraphEdge(id: id, sourceId: from, targetId: to, typeId: type);

GraphSnapshot graph(List<GraphNode> nodes, List<GraphEdge> edges) =>
    GraphSnapshot(
      nodes: nodes,
      edges: edges,
      nodeTypes: canonicalNodeTypes,
      edgeTypes: canonicalEdgeTypes,
    );

final order = ListOrder(
  rootGroup: (n) => n.typeIds.isEmpty ? 1 : 0,
  edgeTypeRank: (t) =>
      switch (const ['loves', 'likes', 'dislikes'].indexOf(t)) {
        -1 => 99,
        final i => i,
      },
);

/// Rows as readable strings: indentation + label, with markers.
List<String> render(GraphSnapshot s, ListTree tree) => [
  for (final r in tree.rows)
    '${'  ' * r.depth}${r.isShadow ? '~' : ''}'
        '${s.nodes[r.nodeId]!.label}'
        '${r.hasChildren && !r.expanded ? ' +' : ''}'
        '${r.parentCount > 1 ? ' [shared]' : ''}'
        '${r.loopCut ? ' [loop]' : ''}',
];

void main() {
  // Sam and Priya (people) share Sushi; Sushi has a child; Sam and Priya are
  // also Related (non-hierarchical); Cilantro is a lone root thing.
  final s = graph(
    const [
      GraphNode(id: 'sam', label: 'Sam', typeIds: ['partner']),
      GraphNode(id: 'priya', label: 'Priya', typeIds: ['friend']),
      GraphNode(id: 'sushi', label: 'Sushi'),
      GraphNode(id: 'salmon', label: 'Salmon nigiri'),
      GraphNode(id: 'coffee', label: 'Coffee'),
      GraphNode(id: 'cilantro', label: 'Cilantro'),
    ],
    [
      e('e1', 'sam', 'sushi', 'likes'),
      e('e2', 'sam', 'coffee', 'loves'),
      e('e3', 'priya', 'sushi', 'loves'),
      e('e4', 'sushi', 'salmon', 'likes'),
      e('e5', 'sam', 'priya', 'related'),
    ],
  );

  test('orders roots people-first and children by line type, then A–Z', () {
    final tree = buildListTree(s, order: order);
    expect(render(s, tree), [
      'Priya',
      '  Sushi [shared]',
      '    Salmon nigiri',
      '  ~Sam',
      'Sam',
      '  Coffee',
      '  Sushi + [shared]',
      '  ~Priya',
      'Cilantro',
    ]);
  });

  test('a shared bubble is expanded at its first appearance only', () {
    final tree = buildListTree(s, order: order);
    final sushiRows = tree.rows.where((r) => r.nodeId == 'sushi').toList();
    expect(sushiRows.map((r) => (r.isRepeat, r.expanded)), [
      (false, true),
      (true, false),
    ]);
    expect(tree.homeKeys['sushi'], 'r:priya/e3');
  });

  test('toggling a repeat expands its full subtree there too', () {
    final tree = buildListTree(s, order: order, toggled: {'r:sam/e1'});
    expect(
      render(s, tree),
      containsAllInOrder(['  Sushi [shared]', '    Salmon nigiri']),
    );
    expect(tree.rows.where((r) => r.nodeId == 'salmon'), hasLength(2));
  });

  test('toggling a normal row collapses it', () {
    final tree = buildListTree(s, order: order, toggled: {'r:priya'});
    expect(render(s, tree).first, 'Priya +');
    expect(render(s, tree), isNot(contains('    Salmon nigiri')));
  });

  test('shadow rows appear under both ends and have no children', () {
    final tree = buildListTree(s, order: order);
    final shadows = tree.rows.where((r) => r.isShadow).toList();
    expect(shadows.map((r) => (r.parentNodeId, r.nodeId)), [
      ('priya', 'sam'),
      ('sam', 'priya'),
    ]);
    expect(shadows.every((r) => !r.hasChildren), isTrue);
  });

  test('home keys cover hidden bubbles, and ancestors unlock them', () {
    final tree = buildListTree(s, order: order, toggled: {'r:priya'});
    final home = tree.homeKeys['salmon']!;
    expect(tree.indexOfKey(home), -1, reason: 'hidden under collapsed Priya');
    expect(ListTree.ancestorKeys(home), ['r:priya', 'r:priya/e3']);
  });

  test('bad data with a loop terminates and keeps every bubble', () {
    final looped = graph(
      const [
        GraphNode(id: 'a', label: 'A'),
        GraphNode(id: 'b', label: 'B'),
        GraphNode(id: 'c', label: 'C'),
      ],
      [e('ab', 'a', 'b', 'likes'), e('ba', 'b', 'a', 'likes')],
    );
    final tree = buildListTree(looped, order: order);
    // Real roots first, then bubbles stranded inside the loop.
    expect(render(looped, tree), ['C', 'A', '  B', '    A [loop]']);
    expect(tree.homeKeys.keys, unorderedEquals(['a', 'b', 'c']));
  });

  test('an empty graph has no rows', () {
    expect(
      buildListTree(graph(const [], const []), order: order).rows,
      isEmpty,
    );
  });
}
