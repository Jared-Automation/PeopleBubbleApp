/// Geometry for the radial wheel: which slice a finger is over, and where to
/// put the wheel so it fits on screen. Plain Dart, so it can be unit-tested.
///
/// Angles are in radians with y pointing down (screen coordinates). Slice 0
/// is centred straight up and slices go clockwise.
library;

import 'dart:math';

/// A slot on the wheel: [ring] 0 is the main ring, 1 the "More" ring.
typedef WheelSlot = ({int ring, int index});

class RadialGeometry {
  const RadialGeometry({
    this.deadZone = 40,
    this.innerRadius = 112,
    this.outerRadius = 184,
  });

  /// Lifting inside this radius picks nothing (cancel / keep the wheel open).
  final double deadZone;

  /// Outer edge of the main ring.
  final double innerRadius;

  /// Outer edge of the "More" ring.
  final double outerRadius;

  /// Width of one main-ring slice.
  static double sliceAngle(int count) => 2 * pi / count;

  /// Centre angle of main-ring slice [index] of [count] (0 = straight up).
  static double sliceCenter(int index, int count) =>
      -pi / 2 + index * sliceAngle(count);

  /// Centre angle of outer slot [index]: the More ring is an arc centred on
  /// the More slice, with slots as wide as the main ring's slices.
  static double outerCenter(
    int index, {
    required int outerCount,
    required int moreIndex,
    required int innerCount,
  }) {
    final width = sliceAngle(innerCount);
    final start =
        sliceCenter(moreIndex, innerCount) - width * (outerCount - 1) / 2;
    return start + index * width;
  }

  /// The slot under a finger at ([dx], [dy]) from the wheel centre, or null
  /// in the dead zone.
  ///
  /// Beyond the main ring the direction still counts, so a quick flick past
  /// a slice selects it. When the More ring is open ([outerCount] given),
  /// the outer band inside its arc selects an outer slot instead.
  WheelSlot? slotAt(
    double dx,
    double dy, {
    required int innerCount,
    int? outerCount,
    int? moreIndex,
  }) {
    final distance = sqrt(dx * dx + dy * dy);
    if (distance < deadZone || innerCount == 0) return null;
    final angle = atan2(dy, dx);

    if (distance > innerRadius && outerCount != null && moreIndex != null) {
      final width = sliceAngle(innerCount);
      for (var i = 0; i < outerCount; i++) {
        final center = outerCenter(
          i,
          outerCount: outerCount,
          moreIndex: moreIndex,
          innerCount: innerCount,
        );
        if (_angleBetween(angle, center).abs() <= width / 2) {
          return (ring: 1, index: i);
        }
      }
    }

    final width = sliceAngle(innerCount);
    final fromFirst = _normalize(
      angle - sliceCenter(0, innerCount) + width / 2,
    );
    return (ring: 0, index: (fromFirst / width).floor() % innerCount);
  }

  /// Moves [center] so a wheel of [radius] (plus [margin]) stays inside a
  /// [width]×[height] screen.
  static Point<double> clampCenter(
    Point<double> center, {
    required double radius,
    required double width,
    required double height,
    double margin = 8,
  }) {
    double clamp(double v, double size) {
      final lo = radius + margin, hi = size - radius - margin;
      return lo > hi ? size / 2 : v.clamp(lo, hi);
    }

    return Point(clamp(center.x, width), clamp(center.y, height));
  }

  /// [a] − [b] wrapped into (−π, π].
  static double _angleBetween(double a, double b) {
    var d = _normalize(a - b);
    if (d > pi) d -= 2 * pi;
    return d;
  }

  /// [a] wrapped into [0, 2π).
  static double _normalize(double a) {
    final r = a % (2 * pi);
    return r < 0 ? r + 2 * pi : r;
  }
}
