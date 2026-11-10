import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/graph.dart';
import 'package:people_bubble/domain/hidden.dart';
import 'package:people_bubble/domain/style.dart';

import 'fixtures.dart';

GraphEdge e(String id, String from, String to, [String type = 'likes']) =>
    GraphEdge(id: id, sourceId: from, targetId: to, typeId: type);

GraphNode n(String id, {bool hidden = false}) => GraphNode(
  id: id,
  label: id,
  overrides: hidden ? const NodeStyle(hidden: true) : NodeStyle.empty,
);

GraphSnapshot graph(List<GraphNode> nodes, List<GraphEdge> edges) =>
    GraphSnapshot(
      nodes: nodes,
      edges: edges,
      nodeTypes: canonicalNodeTypes,
      edgeTypes: canonicalEdgeTypes,
    );

void main() {
  // Sam (hidden) → gift → wrap; Sam and Priya both like tea (shared);
  // gift and priya are Related (non-hierarchical).
  final s = graph(
    [n('sam', hidden: true), n('priya'), n('gift'), n('wrap'), n('tea')],
    [
      e('e1', 'sam', 'gift'),
      e('e2', 'gift', 'wrap'),
      e('e3', 'sam', 'tea'),
      e('e4', 'priya', 'tea'),
      e('e5', 'gift', 'priya', 'related'),
    ],
  );
  final groups = HiddenGroups.of(s);

  test('greys everything under the hidden bubble, not the bubble itself', () {
    expect(groups.under, {'gift', 'wrap'});
    final g = groups.greyed(s);
    expect(g.nodes, {'gift', 'wrap'});
    expect(g.edges, {'e1', 'e2', 'e5'}, reason: 'lines touching greyed ones');
  });

  test('something shared with a visible bubble stays visible', () {
    expect(groups.under, isNot(contains('tea')));
    expect(groups.groups['sam'], containsAll(['gift', 'wrap', 'tea']));
  });

  test(
    'selecting the hidden bubble or anything under it reveals the group',
    () {
      for (final pick in ['sam', 'gift', 'wrap', 'tea']) {
        expect(groups.greyed(s, selected: [pick]).nodes, isEmpty, reason: pick);
      }
      expect(groups.greyed(s, selected: ['priya']).nodes, {'gift', 'wrap'});
    },
  );

  test('Show hidden reveals everything', () {
    final g = groups.greyed(s, showHidden: true);
    expect(g.nodes, isEmpty);
    expect(g.edges, isEmpty);
  });

  test('nested hidden bubbles: the inner one is greyed with the rest', () {
    final s2 = graph(
      [n('a', hidden: true), n('b', hidden: true), n('c')],
      [e('e1', 'a', 'b'), e('e2', 'b', 'c')],
    );
    final g2 = HiddenGroups.of(s2);
    expect(g2.under, {'b', 'c'});
    expect(g2.greyed(s2, selected: ['c']).nodes, isEmpty);
    expect(g2.greyed(s2, selected: ['a']).nodes, isEmpty);
  });

  test('a type can hide, and an override can turn it back off', () {
    final types = canonicalNodeTypes.withType(
      canonicalNodeTypes.byId['friend']!.copyWith(
        style: const NodeStyle(outlineColor: 0xFF1E88E5, hidden: true),
      ),
    );
    GraphSnapshot with3(NodeStyle priyaOverrides) => GraphSnapshot(
      nodes: [
        GraphNode(
          id: 'priya',
          label: 'Priya',
          typeIds: const ['friend'],
          overrides: priyaOverrides,
        ),
        n('x'),
      ],
      edges: [e('e1', 'priya', 'x')],
      nodeTypes: types,
      edgeTypes: canonicalEdgeTypes,
    );
    expect(HiddenGroups.of(with3(NodeStyle.empty)).under, {'x'});
    expect(
      HiddenGroups.of(with3(const NodeStyle(hidden: false))).under,
      isEmpty,
    );
  });

  test('looped data does not hang', () {
    final loop = graph(
      [n('a', hidden: true), n('b'), n('c')],
      [e('e1', 'a', 'b'), e('e2', 'b', 'c'), e('e3', 'c', 'a')],
    );
    final g = HiddenGroups.of(loop);
    expect(g.groups['a'], {'b', 'c'});
  });

  test('no hidden bubbles: nothing greyed', () {
    final plain = graph([n('a'), n('b')], [e('e1', 'a', 'b')]);
    expect(HiddenGroups.of(plain).greyed(plain).nodes, isEmpty);
  });
}
