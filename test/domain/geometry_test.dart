import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/geometry.dart';
import 'package:people_bubble/domain/style.dart';

void main() {
  // A 100×50 box centred on the origin.
  final box = boxAt(const Point(0, 0), (width: 100, height: 50));

  Matcher near(num x, num y) => isA<Point<double>>()
      .having((p) => p.x, 'x', closeTo(x, 1e-6))
      .having((p) => p.y, 'y', closeTo(y, 1e-6));

  group('borderPoint', () {
    test('rectangle exits through the side the ray hits', () {
      expect(
        borderPoint(NodeShape.rectangle, box, const Point(500, 0)),
        near(50, 0),
      );
      expect(
        borderPoint(NodeShape.rectangle, box, const Point(0, -500)),
        near(0, -25),
      );
      // 45° hits the top edge first (it's closer than the side).
      expect(
        borderPoint(NodeShape.rectangle, box, const Point(100, 100)),
        near(25, 25),
      );
    });

    test('ellipse points satisfy the ellipse equation', () {
      for (final target in const [Point(300.0, 70.0), Point(-10.0, 90.0)]) {
        final p = borderPoint(NodeShape.ellipse, box, target);
        expect(
          (p.x / 50) * (p.x / 50) + (p.y / 25) * (p.y / 25),
          closeTo(1, 1e-9),
        );
      }
    });

    test('rounded rect matches the rectangle away from corners', () {
      expect(
        borderPoint(NodeShape.roundedRect, box, const Point(500, 0)),
        near(50, 0),
      );
    });

    test('rounded rect cuts the corner on a diagonal', () {
      final square = boxAt(const Point(0, 0), (width: 100, height: 100));
      final p = borderPoint(NodeShape.roundedRect, square, const Point(1, 1));
      // Corner radius 16: the corner circle is centred at (34, 34).
      final r = roundedCornerRadius(square);
      expect(p.distanceTo(Point(50 - r, 50 - r)), closeTo(r, 1e-6));
      expect(p.x, lessThan(50));
    });

    test('a target at the centre returns the centre', () {
      expect(
        borderPoint(NodeShape.ellipse, box, const Point(0, 0)),
        near(0, 0),
      );
    });
  });

  test('gapBetween is 0 for overlapping boxes, else edge distance', () {
    final a = boxAt(const Point(0, 0), (width: 10, height: 10));
    final b = boxAt(const Point(20, 0), (width: 10, height: 10));
    final c = boxAt(const Point(3, 3), (width: 10, height: 10));
    expect(gapBetween(a, b), 10);
    expect(gapBetween(a, c), 0);
  });

  test('boundsOf covers every box, null when empty', () {
    expect(boundsOf(const []), isNull);
    final bounds = boundsOf([
      boxAt(const Point(0, 0), (width: 10, height: 10)),
      boxAt(const Point(100, 50), (width: 10, height: 10)),
    ])!;
    expect(
      (bounds.left, bounds.top, bounds.right, bounds.bottom),
      (-5, -5, 105, 55),
    );
  });
}
