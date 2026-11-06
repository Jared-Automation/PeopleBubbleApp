import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../domain/geometry.dart';

/// A faint dot grid behind the canvas, in screen space. Repaints whenever the
/// pan/zoom changes, and fades out when zoomed far out (where it would just
/// be noise and thousands of dots).
class GridPainter extends CustomPainter {
  GridPainter(this.transform, this.color) : super(repaint: transform);

  final TransformationController transform;
  final Color color;

  static const _worldSpacing = gridSpacing, _minSpacing = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final m = transform.value;
    final scale = m.getMaxScaleOnAxis();
    final spacing = _worldSpacing * scale;
    if (spacing < _minSpacing) return;
    final fade = ((spacing - _minSpacing) / _minSpacing).clamp(0.0, 1.0);
    final translation = m.getTranslation();
    final ox = translation.x % spacing, oy = translation.y % spacing;

    final points = <Offset>[
      for (var x = ox; x < size.width; x += spacing)
        for (var y = oy; y < size.height; y += spacing) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = color.withValues(alpha: color.a * fade)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(GridPainter old) => old.color != color;
}
