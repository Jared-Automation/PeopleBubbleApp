import 'dart:math';

import 'package:flutter/rendering.dart';

import '../../domain/geometry.dart';
import '../../domain/graph.dart';
import '../../domain/style.dart';
import 'canvas_layout_cache.dart';

/// Draws every placed bubble and the lines between them.
///
/// Paints in world coordinates shifted by [origin], so world (0, 0) sits at
/// [origin] inside the (very large) canvas child of the `InteractiveViewer`.
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.snapshot,
    required this.cache,
    required this.origin,
    required this.labelBackground,
  });

  final GraphSnapshot snapshot;
  final CanvasLayoutCache cache;
  final Offset origin;

  /// Behind line labels, so they stay readable over lines and the grid.
  final Color labelBackground;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    final boxes = <String, Rectangle<double>>{};
    final styles = <String, NodeStyle>{};
    for (final node in snapshot.nodes.values) {
      if (!node.isPlaced) continue;
      final style = snapshot.styleOf(node);
      styles[node.id] = style;
      boxes[node.id] = boxAt(
        Point(node.x!, node.y!),
        cache.node(node.label, style).size,
      );
    }

    // Lines first, so bubbles sit on top of them.
    for (final edge in snapshot.edges.values) {
      final a = boxes[edge.sourceId], b = boxes[edge.targetId];
      if (a == null || b == null) continue;
      _paintEdge(
        canvas,
        edge,
        borderPoint(styles[edge.sourceId]!.shape!, a, centerOf(b)),
        borderPoint(styles[edge.targetId]!.shape!, b, centerOf(a)),
      );
    }
    for (final MapEntry(key: id, value: box) in boxes.entries) {
      _paintNode(canvas, snapshot.nodes[id]!, styles[id]!, box);
    }
    canvas.restore();
  }

  void _paintEdge(
    Canvas canvas,
    GraphEdge edge,
    Point<double> from,
    Point<double> to,
  ) {
    final length = from.distanceTo(to);
    if (length < 1) return;
    final style = snapshot.edgeStyleOf(edge);
    final width = style.width!;
    final color = Color(style.color!);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = style.lineStyle == LineStyle.dotted
          ? StrokeCap.round
          : StrokeCap.butt;

    final hasArrow = style.arrowhead == Arrowhead.end;
    final arrowSize = 6 + 2 * width;
    final ux = (to.x - from.x) / length, uy = (to.y - from.y) / length;
    // Stop the line at the arrow's base so the tip stays sharp.
    final end = hasArrow && length > arrowSize
        ? Point(to.x - ux * arrowSize, to.y - uy * arrowSize)
        : to;
    final line = Path()
      ..moveTo(from.x, from.y)
      ..lineTo(end.x, end.y);
    canvas.drawPath(dashed(line, style.lineStyle!, width), paint);

    if (hasArrow) {
      final px = -uy * arrowSize / 2, py = ux * arrowSize / 2;
      canvas.drawPath(
        Path()
          ..moveTo(to.x, to.y)
          ..lineTo(end.x + px, end.y + py)
          ..lineTo(end.x - px, end.y - py)
          ..close(),
        Paint()..color = color,
      );
    }

    final label = edge.label;
    if (label != null) {
      final text = cache.edgeLabel(label, style.color!);
      final mid = Offset((from.x + to.x) / 2, (from.y + to.y) / 2);
      final pill = Rect.fromCenter(
        center: mid,
        width: text.width + 10,
        height: text.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pill, const Radius.circular(8)),
        Paint()..color = labelBackground,
      );
      text.paint(canvas, mid - Offset(text.width / 2, text.height / 2));
    }
  }

  void _paintNode(
    Canvas canvas,
    GraphNode node,
    NodeStyle style,
    Rectangle<double> box,
  ) {
    final rect = Rect.fromLTWH(box.left, box.top, box.width, box.height);
    final shape = switch (style.shape!) {
      NodeShape.roundedRect =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(roundedCornerRadius(box)),
          ),
        ),
      NodeShape.rectangle => Path()..addRect(rect),
      NodeShape.ellipse || NodeShape.circle => Path()..addOval(rect),
    };
    canvas.drawPath(shape, Paint()..color = Color(style.fillColor!));
    final outlineWidth = style.outlineWidth!;
    if (outlineWidth > 0) {
      canvas.drawPath(
        dashed(shape, style.outlineStyle!, outlineWidth),
        Paint()
          ..color = Color(style.outlineColor!)
          ..strokeWidth = outlineWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = style.outlineStyle == LineStyle.dotted
              ? StrokeCap.round
              : StrokeCap.butt,
      );
    }
    final text = cache.node(node.label, style).text;
    text.paint(canvas, rect.center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(GraphPainter old) =>
      old.snapshot != snapshot || old.labelBackground != labelBackground;
}

/// [source] broken into dashes or dots. `Canvas` has no dash support, so
/// this walks the path with `PathMetrics` and copies out the visible pieces.
/// Dots are near-zero-length dashes drawn with a round stroke cap.
Path dashed(Path source, LineStyle style, double strokeWidth) {
  if (style == LineStyle.solid) return source;
  final (dash, gap) = style == LineStyle.dotted
      ? (0.01, strokeWidth * 2.5 + 2)
      : (strokeWidth * 4 + 4, strokeWidth * 3 + 3);
  final out = Path();
  for (final metric in source.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += dash + gap) {
      out.addPath(
        metric.extractPath(d, min(d + dash, metric.length)),
        Offset.zero,
      );
    }
  }
  return out;
}
