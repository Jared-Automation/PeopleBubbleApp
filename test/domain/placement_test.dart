import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/geometry.dart';
import 'package:people_bubble/domain/graph.dart';
import 'package:people_bubble/domain/placement.dart';

import 'fixtures.dart';

const placer = Placer();
const person = (width: 140.0, height: 64.0);
const thing = (width: 96.0, height: 48.0);

void main() {
  group('placeChild', () {
    test('first child of a lone parent goes just below it, no overlap', () {
      final parent = boxAt(const Point(0, 0), person);
      final p = placer.placeChild(
        parentCenters: const [Point(0, 0)],
        parentSize: person,
        size: thing,
        obstacles: [parent],
      );
      expect(p.x, closeTo(0, 1e-6));
      expect(p.y, greaterThan(0));
      expect(gapBetween(boxAt(p, thing), parent), greaterThanOrEqualTo(16));
      expect(p.y, lessThan(250), reason: 'stays close');
    });

    test('fans away from the grandparent', () {
      // Grandparent to the left of the parent → child to the right.
      final p = placer.placeChild(
        parentCenters: const [Point(0, 0)],
        grandparentCenters: const [Point(-300, 0)],
        parentSize: thing,
        size: thing,
        obstacles: [
          boxAt(const Point(-300, 0), person),
          boxAt(const Point(0, 0), thing),
        ],
      );
      expect(p.x, greaterThan(0));
      expect(p.y.abs(), lessThan(1e-6));
    });

    test('a root parent fills the widest gap between existing children', () {
      // Children above and to the right → widest gap faces down-left.
      final children = [const Point(0.0, -200.0), const Point(200.0, 0.0)];
      final p = placer.placeChild(
        parentCenters: const [Point(0, 0)],
        siblingCenters: children,
        parentSize: person,
        size: thing,
        obstacles: [
          boxAt(const Point(0, 0), person),
          for (final c in children) boxAt(c, thing),
        ],
      );
      expect(p.x, lessThan(0));
      expect(p.y, greaterThan(0));
    });

    test('a shared child goes near the average of its parents', () {
      final p = placer.placeChild(
        parentCenters: const [Point(-200, 0), Point(200, 0)],
        parentSize: person,
        size: thing,
        obstacles: [
          boxAt(const Point(-200, 0), person),
          boxAt(const Point(200, 0), person),
        ],
      );
      expect(p.x.abs(), lessThan(1e-6));
    });

    test('steps around crowding but never fully covers a bubble', () {
      // Fill the whole first ring with small bubbles.
      final parent = boxAt(const Point(0, 0), person);
      final crowd = [
        for (var a = 0.0; a < 2 * pi; a += pi / 12)
          boxAt(Point(170 * cos(a), 170 * sin(a)), (width: 30, height: 30)),
      ];
      final p = placer.placeChild(
        parentCenters: const [Point(0, 0)],
        parentSize: person,
        size: thing,
        obstacles: [parent, ...crowd],
      );
      final box = boxAt(p, thing);
      for (final o in [parent, ...crowd]) {
        expect(box.containsRectangle(o), isFalse);
      }
    });
  });

  group('placeRoot', () {
    test('an empty canvas uses the search centre', () {
      expect(
        placer.placeRoot(
          searchCenter: const Point(5, 5),
          searchArea: const Rectangle(-500, -500, 1000, 1000),
          size: person,
          obstacles: const [],
        ),
        const Point(5, 5),
      );
    });

    test('keeps three widths of clearance', () {
      final existing = boxAt(const Point(0, 0), person);
      final p = placer.placeRoot(
        searchCenter: const Point(0, 0),
        searchArea: const Rectangle(-2000, -2000, 4000, 4000),
        size: person,
        obstacles: [existing],
      );
      expect(
        gapBetween(boxAt(p, person), existing),
        greaterThanOrEqualTo(3 * person.width),
      );
    });

    test('falls back to just outside everything when the area is full', () {
      final existing = boxAt(const Point(0, 0), person);
      final p = placer.placeRoot(
        searchCenter: const Point(0, 0),
        searchArea: const Rectangle(-100, -100, 200, 200),
        size: person,
        obstacles: [existing],
      );
      expect(boxAt(p, person).left, greaterThan(existing.right));
    });
  });

  group('placeUnplaced', () {
    GraphSnapshot graph(List<GraphNode> nodes, List<GraphEdge> edges) =>
        GraphSnapshot(
          nodes: nodes,
          edges: edges,
          nodeTypes: canonicalNodeTypes,
          edgeTypes: canonicalEdgeTypes,
        );
    GraphEdge e(String id, String from, String to) =>
        GraphEdge(id: id, sourceId: from, targetId: to, typeId: 'likes');

    test('places every unplaced node without overlaps, keeps placed ones', () {
      final s = graph(
        [
          const GraphNode(id: 'sam', label: 'Sam', x: 0, y: 0),
          const GraphNode(id: 'priya', label: 'Priya'),
          for (var i = 0; i < 12; i++) GraphNode(id: 't$i', label: 'Thing $i'),
        ],
        [
          for (var i = 0; i < 6; i++) e('a$i', 'sam', 't$i'),
          for (var i = 4; i < 12; i++) e('b$i', 'priya', 't$i'),
        ],
      );
      final placed = placeUnplaced(
        s,
        sizeOf: (_) => thing,
        viewCenter: const Point(0, 0),
      );
      expect(placed.keys, isNot(contains('sam')));
      expect(placed.length, 13);
      final boxes = [
        boxAt(const Point(0, 0), thing),
        for (final p in placed.values) boxAt(p, thing),
      ];
      for (var i = 0; i < boxes.length; i++) {
        for (var j = i + 1; j < boxes.length; j++) {
          expect(
            overlapArea(boxes[i], boxes[j]),
            0,
            reason: 'boxes $i and $j overlap',
          );
        }
      }
    });

    test('a shared thing lands between all the people who have it', () {
      final s = graph(
        const [
          GraphNode(id: 'sam', label: 'Sam'),
          GraphNode(id: 'priya', label: 'Priya'),
          GraphNode(id: 'sushi', label: 'Sushi'),
        ],
        [e('a', 'sam', 'sushi'), e('b', 'priya', 'sushi')],
      );
      final placed = placeUnplaced(
        s,
        sizeOf: (_) => thing,
        viewCenter: const Point(0, 0),
      );
      final sushi = placed['sushi']!;
      final mid = Point(
        (placed['sam']!.x + placed['priya']!.x) / 2,
        (placed['sam']!.y + placed['priya']!.y) / 2,
      );
      final spread = placed['sam']!.distanceTo(placed['priya']!);
      expect(sushi.distanceTo(mid), lessThan(spread / 2));
    });

    test('terminates on looped data', () {
      final s = graph(
        const [GraphNode(id: 'a', label: 'A'), GraphNode(id: 'b', label: 'B')],
        [e('ab', 'a', 'b'), e('ba', 'b', 'a')],
      );
      expect(
        placeUnplaced(
          s,
          sizeOf: (_) => thing,
          viewCenter: const Point(0, 0),
        ).keys,
        unorderedEquals(['a', 'b']),
      );
    });

    test('places bubbles below a loop that a real root also reaches', () {
      // R → A, and A ↔ B loop: A waits on B forever in the normal pass.
      final s = graph(
        const [
          GraphNode(id: 'r', label: 'R'),
          GraphNode(id: 'a', label: 'A'),
          GraphNode(id: 'b', label: 'B'),
        ],
        [e('ra', 'r', 'a'), e('ab', 'a', 'b'), e('ba', 'b', 'a')],
      );
      expect(
        placeUnplaced(
          s,
          sizeOf: (_) => thing,
          viewCenter: const Point(0, 0),
        ).keys,
        unorderedEquals(['r', 'a', 'b']),
      );
    });

    test('nothing to do when everything is placed', () {
      final s = graph(const [GraphNode(id: 'a', label: 'A', x: 1, y: 1)], []);
      expect(
        placeUnplaced(s, sizeOf: (_) => thing, viewCenter: const Point(0, 0)),
        isEmpty,
      );
    });
  });
}
