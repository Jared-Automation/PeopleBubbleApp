import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/graph.dart';

import 'fixtures.dart';

void main() {
  group('edgeWouldCreateCycle', () {
    const edges = [('sam', 'coffee'), ('coffee', 'latte')];

    test('blocks a self-loop', () {
      expect(
        edgeWouldCreateCycle(parentId: 'a', childId: 'a', edges: const []),
        isTrue,
      );
    });

    test('blocks closing a loop through descendants', () {
      expect(
        edgeWouldCreateCycle(parentId: 'latte', childId: 'sam', edges: edges),
        isTrue,
      );
    });

    test('allows a shared child (multiple parents)', () {
      expect(
        edgeWouldCreateCycle(
          parentId: 'priya',
          childId: 'coffee',
          edges: edges,
        ),
        isFalse,
      );
    });

    test('terminates on data that already has a cycle', () {
      const looped = [('a', 'b'), ('b', 'a')];
      expect(
        edgeWouldCreateCycle(parentId: 'x', childId: 'a', edges: looped),
        isFalse,
      );
    });
  });

  group('graphHasCycle', () {
    test('false for a DAG with shared children', () {
      expect(
        graphHasCycle(const [('a', 'c'), ('b', 'c'), ('c', 'd')]),
        isFalse,
      );
    });

    test('true for a loop', () {
      expect(graphHasCycle(const [('a', 'b'), ('b', 'c'), ('c', 'a')]), isTrue);
    });
  });

  group('GraphSnapshot', () {
    final snapshot = GraphSnapshot(
      nodes: const [
        GraphNode(id: 'sam', label: 'Sam', typeIds: ['partner']),
        GraphNode(id: 'priya', label: 'Priya'),
        GraphNode(id: 'sushi', label: 'Sushi'),
      ],
      edges: const [
        GraphEdge(
          id: 'e1',
          sourceId: 'sam',
          targetId: 'sushi',
          typeId: 'loves',
        ),
        GraphEdge(
          id: 'e2',
          sourceId: 'sam',
          targetId: 'priya',
          typeId: 'related',
        ),
      ],
      nodeTypes: canonicalNodeTypes,
      edgeTypes: canonicalEdgeTypes,
    );

    test('non-hierarchical edges do not make a node a child', () {
      expect(
        snapshot.roots.map((n) => n.id),
        unorderedEquals(['sam', 'priya']),
      );
    });

    test('styleOf resolves types', () {
      expect(snapshot.styleOf(snapshot.nodes['sam']!).outlineColor, pink);
    });
  });
}
