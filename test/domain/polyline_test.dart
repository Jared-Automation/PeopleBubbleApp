import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/polyline.dart';

void main() {
  const square = [
    Point(0.0, 0.0),
    Point(100.0, 0.0),
    Point(100.0, 100.0),
    Point(0.0, 100.0),
  ];

  test('distance to a polyline is to its nearest segment', () {
    expect(distanceToPolyline(const Point(50, 10), square), closeTo(10, 1e-9));
    expect(distanceToPolyline(const Point(90, 50), square), closeTo(10, 1e-9));
    expect(distanceToPolyline(const Point(50, 50), square), closeTo(50, 1e-9));
  });

  test('a new waypoint goes into the segment nearest the press', () {
    expect(insertionIndex(square, const Point(50, -5)), 0);
    expect(insertionIndex(square, const Point(105, 50)), 1);
    expect(insertionIndex(square, const Point(50, 104)), 2);
    // A straight line has one segment: the first waypoint is index 0.
    expect(
      insertionIndex(const [
        Point(0.0, 0.0),
        Point(0.0, 300.0),
      ], const Point(9, 150)),
      0,
    );
  });

  test('the label sits mid-way along the longest segment', () {
    const points = [Point(0.0, 0.0), Point(10.0, 0.0), Point(10.0, 200.0)];
    expect(labelAnchor(points), const Point(10.0, 100.0));
    expect(
      labelAnchor(const [Point(0.0, 0.0), Point(40.0, 20.0)]),
      const Point(20.0, 10.0),
    );
  });

  group('smoothPolyline', () {
    test('two points stay a straight line', () {
      const line = [Point(0.0, 0.0), Point(50.0, 50.0)];
      expect(smoothPolyline(line), line);
    });

    test('passes through every original point and keeps the ends', () {
      final curve = smoothPolyline(square, perSegment: 8);
      expect(curve.first, square.first);
      expect(curve.last, square.last);
      expect(curve.length, 1 + 3 * 8);
      for (final (i, p) in square.indexed) {
        final q = curve[i * 8];
        expect(q.distanceTo(p), lessThan(1e-9), reason: 'point $i');
      }
    });

    test('bends smoothly instead of cornering', () {
      final curve = smoothPolyline(square, perSegment: 8);
      // Half-way along the first segment the curve already leans toward
      // the next corner, so it isn't exactly on y = 0.
      expect(curve[4].y, isNot(0));
    });
  });
}
