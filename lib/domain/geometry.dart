/// Plain-Dart geometry for the canvas and auto-placement. Uses `dart:math`'s
/// [Point] and [Rectangle] so the domain layer stays free of Flutter.
///
/// Coordinates are canvas ("world") units with y pointing down, matching the
/// screen. A node's saved x/y is the centre of its box.
library;

import 'dart:math';

import 'style.dart';

/// Width and height of a node's box.
typedef BoxSize = ({double width, double height});

/// The box of a node of [size] centred on [center].
Rectangle<double> boxAt(Point<double> center, BoxSize size) => Rectangle(
  center.x - size.width / 2,
  center.y - size.height / 2,
  size.width,
  size.height,
);

Point<double> centerOf(Rectangle<double> r) =>
    Point(r.left + r.width / 2, r.top + r.height / 2);

/// Corner radius used for [NodeShape.roundedRect]; the painter uses the same.
double roundedCornerRadius(Rectangle<double> box) =>
    min(16.0, min(box.width, box.height) / 2);

/// Where the ray from the centre of [box] toward [toward] leaves the shape.
/// Lines are drawn between these points so they (and arrowheads) stop at the
/// outline instead of running under the bubble.
Point<double> borderPoint(
  NodeShape shape,
  Rectangle<double> box,
  Point<double> toward,
) {
  final c = centerOf(box);
  final dx = toward.x - c.x, dy = toward.y - c.y;
  if (dx == 0 && dy == 0) return c;
  final a = box.width / 2, b = box.height / 2;

  switch (shape) {
    case NodeShape.ellipse:
    case NodeShape.circle:
      final t = 1 / sqrt((dx / a) * (dx / a) + (dy / b) * (dy / b));
      return Point(c.x + dx * t, c.y + dy * t);
    case NodeShape.rectangle:
      return _rectExit(c, dx, dy, a, b);
    case NodeShape.roundedRect:
      final p = _rectExit(c, dx, dy, a, b);
      final r = roundedCornerRadius(box);
      final innerA = a - r, innerB = b - r;
      // Inside a corner square? Then intersect with that corner's circle.
      if ((p.x - c.x).abs() <= innerA || (p.y - c.y).abs() <= innerB) {
        return p;
      }
      final cc = Point(c.x + innerA * dx.sign, c.y + innerB * dy.sign);
      // Solve |c + d·t − cc| = r for the larger t.
      final fx = c.x - cc.x, fy = c.y - cc.y;
      final qa = dx * dx + dy * dy;
      final qb = 2 * (fx * dx + fy * dy);
      final qc = fx * fx + fy * fy - r * r;
      final disc = max(0.0, qb * qb - 4 * qa * qc);
      final t = (-qb + sqrt(disc)) / (2 * qa);
      return Point(c.x + dx * t, c.y + dy * t);
  }
}

Point<double> _rectExit(
  Point<double> c,
  double dx,
  double dy,
  double a,
  double b,
) {
  final tx = dx == 0 ? double.infinity : a / dx.abs();
  final ty = dy == 0 ? double.infinity : b / dy.abs();
  final t = min(tx, ty);
  return Point(c.x + dx * t, c.y + dy * t);
}

/// The smallest rectangle containing all of [boxes], or null if empty.
Rectangle<double>? boundsOf(Iterable<Rectangle<double>> boxes) {
  Rectangle<double>? result;
  for (final box in boxes) {
    result = result == null ? box : result.boundingBox(box);
  }
  return result;
}

/// [r] grown by [by] on every side.
Rectangle<double> inflate(Rectangle<double> r, double by) =>
    Rectangle(r.left - by, r.top - by, r.width + 2 * by, r.height + 2 * by);

double overlapArea(Rectangle<double> a, Rectangle<double> b) {
  final i = a.intersection(b);
  return i == null ? 0 : i.width * i.height;
}

/// Shortest distance between two boxes (0 if they touch or overlap).
double gapBetween(Rectangle<double> a, Rectangle<double> b) {
  final dx = max(0.0, max(a.left - b.right, b.left - a.right));
  final dy = max(0.0, max(a.top - b.bottom, b.top - a.bottom));
  return sqrt(dx * dx + dy * dy);
}
