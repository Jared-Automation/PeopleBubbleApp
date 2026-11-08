/// Geometry for lines that bend through waypoints. Plain Dart.
///
/// A line's "points" run from its source end, through each waypoint in
/// order, to its target end, so a line with n waypoints has n + 2 points.
library;

import 'dart:math';

import 'geometry.dart';

/// Shortest distance from [p] to the polyline through [points].
double distanceToPolyline(Point<double> p, List<Point<double>> points) {
  if (points.isEmpty) return double.infinity;
  if (points.length == 1) return p.distanceTo(points.first);
  var best = double.infinity;
  for (var i = 0; i + 1 < points.length; i++) {
    best = min(best, distanceToSegment(p, points[i], points[i + 1]));
  }
  return best;
}

/// Where a new waypoint at [p] belongs in the line's waypoint list: the
/// index of the segment nearest [p]. Segment i runs from points[i] to
/// points[i + 1], and a waypoint inserted at index i sits between them.
int insertionIndex(List<Point<double>> points, Point<double> p) {
  var best = 0;
  var bestDistance = double.infinity;
  for (var i = 0; i + 1 < points.length; i++) {
    final d = distanceToSegment(p, points[i], points[i + 1]);
    if (d < bestDistance) (best, bestDistance) = (i, d);
  }
  return best;
}

/// Where a line's label goes: the middle of its longest segment.
Point<double> labelAnchor(List<Point<double>> points) {
  if (points.length < 2) return points.isEmpty ? const Point(0, 0) : points[0];
  var best = 0;
  var bestLength = -1.0;
  for (var i = 0; i + 1 < points.length; i++) {
    final length = points[i].distanceTo(points[i + 1]);
    if (length > bestLength) (best, bestLength) = (i, length);
  }
  final a = points[best], b = points[best + 1];
  return Point((a.x + b.x) / 2, (a.y + b.y) / 2);
}

/// A smooth curve through every one of [points] (a uniform Catmull-Rom
/// spline), sampled [perSegment] times per segment.
/// The first and last points are kept exactly. Two or fewer points come
/// back unchanged.
List<Point<double>> smoothPolyline(
  List<Point<double>> points, {
  int perSegment = 12,
}) {
  if (points.length <= 2) return points;
  final out = <Point<double>>[points.first];
  for (var i = 0; i + 1 < points.length; i++) {
    final p0 = points[max(0, i - 1)];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = points[min(points.length - 1, i + 2)];
    for (var s = 1; s <= perSegment; s++) {
      final t = s / perSegment, t2 = t * t, t3 = t2 * t;
      double at(double a, double b, double c, double d) =>
          0.5 *
          (2 * b +
              (-a + c) * t +
              (2 * a - 5 * b + 4 * c - d) * t2 +
              (-a + 3 * b - 3 * c + d) * t3);
      out.add(Point(at(p0.x, p1.x, p2.x, p3.x), at(p0.y, p1.y, p2.y, p3.y)));
    }
  }
  return out;
}
