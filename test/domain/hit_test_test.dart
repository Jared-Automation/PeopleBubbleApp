import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/geometry.dart';
import 'package:people_bubble/domain/graph.dart';
import 'package:people_bubble/domain/hit_test.dart';
import 'package:people_bubble/domain/style.dart';

import 'fixtures.dart';

HitNode node(String id, Point<double> c, {double w = 100, double h = 50}) =>
    (id: id, shape: NodeShape.ellipse, box: boxAt(c, (width: w, height: h)));

void main() {
  final sam = node('sam', const Point(0, 0));
  final sushi = node('sushi', const Point(0, 300));
  final HitEdge line = (
    id: 'e1',
    points: const [Point(0.0, 25.0), Point(0.0, 275.0)],
  );

  CanvasHit? at(Point<double> p, {double minTarget = 48}) => hitTest(
    p,
    nodes: [sam, sushi],
    edges: [line],
    minTarget: minTarget,
    lineTolerance: 24,
  );

  test('inside a bubble hits it', () {
    expect(at(const Point(10, 5)), const NodeHit('sam'));
  });

  test("an ellipse's empty corner is not the bubble", () {
    // Inside the 100×50 box but outside the ellipse.
    expect(at(const Point(48, 23)), isNull);
  });

  test('near a line hits the line; far from it hits nothing', () {
    expect(at(const Point(20, 150)), const EdgeHit('e1'));
    expect(at(const Point(60, 150)), isNull);
  });

  test('bubbles win over lines', () {
    expect(at(const Point(0, 20)), const NodeHit('sam'));
  });

  test('zoomed out, small bubbles get a bigger target', () {
    // At 0.1× a 48 dp target is 480 world units: Sam is hit well outside its
    // shape, and the closer centre wins between Sam and Sushi.
    expect(at(const Point(150, 40), minTarget: 480), const NodeHit('sam'));
    expect(at(const Point(150, 260), minTarget: 480), const NodeHit('sushi'));
  });

  test('zoomed out, a line beats the padding around a small bubble', () {
    // (3, 150) is inside Sam's padded 480-unit target but 125 units from
    // Sam's edge, and only 3 from the line.
    expect(at(const Point(3, 150), minTarget: 480), const EdgeHit('e1'));
    // Next to Sam's edge, Sam still wins.
    expect(at(const Point(60, 30), minTarget: 480), const NodeHit('sam'));
  });

  test("a bubble's own shape beats another bubble's padding", () {
    final tiny = node('tiny', const Point(40, 30), w: 10, h: 10);
    final hit = hitTest(
      const Point(30, 10),
      nodes: [sam, tiny],
      edges: const [],
      minTarget: 480,
      lineTolerance: 24,
    );
    // Tiny's centre is closer (22 vs 32), but the point is on Sam's ellipse.
    expect(hit, const NodeHit('sam'));
  });

  test('distanceToSegment measures to the nearest point, ends included', () {
    const a = Point(0.0, 0.0), b = Point(10.0, 0.0);
    expect(distanceToSegment(const Point(5, 3), a, b), 3);
    expect(distanceToSegment(const Point(13, 4), a, b), 5);
  });

  test('snapToGrid rounds to the nearest grid point', () {
    expect(snapToGrid(const Point(59, -21)), const Point(40.0, -40.0));
  });

  test('neighborhoodOf keeps the item, its lines and their other ends', () {
    final s = GraphSnapshot(
      nodes: const [
        GraphNode(id: 'sam', label: 'Sam'),
        GraphNode(id: 'priya', label: 'Priya'),
        GraphNode(id: 'sushi', label: 'Sushi'),
        GraphNode(id: 'jazz', label: 'Jazz'),
      ],
      edges: const [
        GraphEdge(id: 'a', sourceId: 'sam', targetId: 'sushi', typeId: 'likes'),
        GraphEdge(
          id: 'b',
          sourceId: 'priya',
          targetId: 'sushi',
          typeId: 'likes',
        ),
        GraphEdge(
          id: 'c',
          sourceId: 'sam',
          targetId: 'priya',
          typeId: 'related',
        ),
      ],
      nodeTypes: canonicalNodeTypes,
      edgeTypes: canonicalEdgeTypes,
    );
    final n = neighborhoodOf(s, nodeId: 'sam');
    expect(n.nodes, {'sam', 'sushi', 'priya'});
    expect(n.edges, {'a', 'c'});
    expect(neighborhoodOf(s, edgeId: 'b').nodes, {'priya', 'sushi'});
  });

  group('bent lines and waypoints', () {
    // Sam → (200, 150) → Sushi.
    final HitEdge bent = (
      id: 'e2',
      points: const [Point(0.0, 25.0), Point(200.0, 150.0), Point(0.0, 275.0)],
    );
    CanvasHit? hit(Point<double> p, {bool handles = false}) => hitTest(
      p,
      nodes: [sam, sushi],
      edges: [bent],
      waypoints: handles ? [(id: 'w1', at: const Point(200.0, 150.0))] : [],
      minTarget: 48,
      lineTolerance: 24,
    );

    test('a bent line is hit along its bend, not its straight chord', () {
      expect(hit(const Point(195, 150)), const EdgeHit('e2'));
      expect(hit(const Point(0, 150)), isNull);
    });

    test('a visible waypoint handle wins over its line', () {
      expect(
        hit(const Point(210, 150), handles: true),
        const WaypointHit('w1'),
      );
      expect(hit(const Point(210, 150)), const EdgeHit('e2'));
    });

    test('a handle is hit within half the touch target', () {
      expect(
        hit(const Point(223, 150), handles: true),
        const WaypointHit('w1'),
      );
      // Past the handle's reach (and the line's): nothing.
      expect(hit(const Point(226, 150), handles: true), isNull);
    });
  });
}
