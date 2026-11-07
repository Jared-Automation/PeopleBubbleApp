import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/graph.dart';
import 'package:people_bubble/domain/radial_menu.dart';

import 'fixtures.dart';

void main() {
  const g = RadialGeometry(); // dead zone 40, rings to 112 and 184

  /// The point [distance] from the centre at [angle] (0 = straight up,
  /// clockwise, in degrees).
  (double, double) at(double degrees, double distance) {
    final a = -pi / 2 + degrees * pi / 180;
    return (distance * cos(a), distance * sin(a));
  }

  WheelSlot? slot(
    double degrees,
    double distance, {
    int inner = 6,
    int? outer,
    int? more,
  }) {
    final (dx, dy) = at(degrees, distance);
    return g.slotAt(
      dx,
      dy,
      innerCount: inner,
      outerCount: outer,
      moreIndex: more,
    );
  }

  test('the centre is a dead zone', () {
    expect(slot(0, 10), isNull);
    expect(slot(90, 39), isNull);
  });

  test('six slices: 0 straight up, then clockwise', () {
    expect(slot(0, 80), (ring: 0, index: 0));
    expect(slot(60, 80), (ring: 0, index: 1));
    expect(slot(180, 80), (ring: 0, index: 3));
    expect(slot(300, 80), (ring: 0, index: 5));
    // Slice edges are ±30° from centre.
    expect(slot(29, 80), (ring: 0, index: 0));
    expect(slot(31, 80), (ring: 0, index: 1));
    expect(slot(-29, 80), (ring: 0, index: 0));
  });

  test('a flick past the ring still picks the slice in that direction', () {
    expect(slot(120, 400), (ring: 0, index: 2));
  });

  test('three slices split the circle into thirds', () {
    expect(slot(0, 80, inner: 3), (ring: 0, index: 0));
    expect(slot(120, 80, inner: 3), (ring: 0, index: 1));
    expect(slot(240, 80, inner: 3), (ring: 0, index: 2));
  });

  group('More ring', () {
    // More is slice 5 (at 300°); three outer slots centred on it: 240°,
    // 300°, 360°.
    WheelSlot? outerSlot(double degrees, double distance) =>
        slot(degrees, distance, outer: 3, more: 5);

    test('outer band inside the arc picks outer slots', () {
      expect(outerSlot(240, 150), (ring: 1, index: 0));
      expect(outerSlot(300, 150), (ring: 1, index: 1));
      expect(outerSlot(0, 150), (ring: 1, index: 2));
    });

    test('the main ring still works while More is open', () {
      expect(outerSlot(300, 80), (ring: 0, index: 5));
      expect(outerSlot(120, 80), (ring: 0, index: 2));
    });

    test('outer band outside the arc falls back to the main slice', () {
      expect(outerSlot(120, 150), (ring: 0, index: 2));
    });
  });

  test('clampCenter keeps the wheel on screen', () {
    expect(
      RadialGeometry.clampCenter(
        const Point(10, 500),
        radius: 112,
        width: 400,
        height: 800,
      ),
      const Point(120.0, 500.0),
    );
    // Screen narrower than the wheel: centre it.
    expect(
      RadialGeometry.clampCenter(
        const Point(10, 10),
        radius: 300,
        width: 400,
        height: 800,
      ).x,
      200,
    );
  });

  test('subtreeOf follows hierarchical lines only and survives loops', () {
    final s = GraphSnapshot(
      nodes: const [
        GraphNode(id: 'sam', label: 'Sam'),
        GraphNode(id: 'coffee', label: 'Coffee'),
        GraphNode(id: 'latte', label: 'Latte'),
        GraphNode(id: 'priya', label: 'Priya'),
        GraphNode(id: 'a', label: 'A'),
        GraphNode(id: 'b', label: 'B'),
      ],
      edges: const [
        GraphEdge(
          id: '1',
          sourceId: 'sam',
          targetId: 'coffee',
          typeId: 'likes',
        ),
        GraphEdge(
          id: '2',
          sourceId: 'coffee',
          targetId: 'latte',
          typeId: 'likes',
        ),
        GraphEdge(
          id: '3',
          sourceId: 'sam',
          targetId: 'priya',
          typeId: 'related',
        ),
        GraphEdge(id: '4', sourceId: 'a', targetId: 'b', typeId: 'likes'),
        GraphEdge(id: '5', sourceId: 'b', targetId: 'a', typeId: 'likes'),
      ],
      nodeTypes: canonicalNodeTypes,
      edgeTypes: canonicalEdgeTypes,
    );
    expect(subtreeOf(s, 'sam'), {'sam', 'coffee', 'latte'});
    expect(subtreeOf(s, 'a'), {'a', 'b'});
  });
}
