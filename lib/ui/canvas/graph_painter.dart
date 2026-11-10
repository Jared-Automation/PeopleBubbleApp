import 'dart:math';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/rendering.dart';

import '../../domain/geometry.dart';
import '../../domain/graph.dart';
import '../../domain/hit_test.dart';
import '../../domain/style.dart';
import 'canvas_layout_cache.dart';
import 'canvas_scene.dart';

/// Draws every placed bubble and the lines between them, from a
/// [CanvasScene].
///
/// Paints in world coordinates shifted by [origin], so world (0, 0) sits at
/// [origin] inside the (very large) canvas child of the `InteractiveViewer`.
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.scene,
    required this.cache,
    required this.origin,
    required this.labelBackground,
    required this.highlight,
    this.selection,
    this.dimUnrelated = true,
    this.group = const {},
    this.greyedNodes = const {},
    this.greyedEdges = const {},
    this.hiders = const {},
  });

  final CanvasScene scene;
  final CanvasLayoutCache cache;
  final Offset origin;

  /// Behind line labels, so they stay readable over lines and the grid.
  final Color labelBackground;

  /// Selection ring / glow colour.
  final Color highlight;
  final CanvasHit? selection;

  /// Fade everything not connected to [selection].
  final bool dimUnrelated;

  /// A multi-bubble selection ("Select subtree"), ringed like [selection].
  final Set<String> group;

  /// Bubbles and lines under a hidden bubble, drawn faint.
  final Set<String> greyedNodes;
  final Set<String> greyedEdges;

  /// Bubbles marked hidden; they get an eye-off badge.
  final Set<String> hiders;

  GraphSnapshot get snapshot => scene.snapshot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    final selected = selection;
    final focus = (selected == null && group.isEmpty) || !dimUnrelated
        ? null
        : _focusOf(selected);
    bool nodeBright(String id) =>
        !greyedNodes.contains(id) &&
        (focus == null || focus.nodes.contains(id));
    bool edgeBright(String id) =>
        !greyedEdges.contains(id) &&
        (focus == null || focus.edges.contains(id));

    // Faded items go into translucent layers: far cheaper than fading
    // hundreds of items one by one. Hidden groups are the faintest, and
    // drawn without any text, so they can't be read until revealed.
    if (greyedNodes.isNotEmpty || greyedEdges.isNotEmpty) {
      canvas.saveLayer(null, Paint()..color = const Color(0x33000000));
      for (final e in scene.edges) {
        if (greyedEdges.contains(e.edge.id)) {
          _paintEdge(canvas, e, withLabel: false);
        }
      }
      for (final n in scene.nodes.values) {
        if (greyedNodes.contains(n.node.id)) {
          _paintNode(canvas, n.node, n.style, n.box, withText: false);
        }
      }
      canvas.restore();
    }
    if (focus != null) {
      canvas.saveLayer(null, Paint()..color = const Color(0x40000000));
      for (final e in scene.edges) {
        final id = e.edge.id;
        if (!edgeBright(id) && !greyedEdges.contains(id)) _paintEdge(canvas, e);
      }
      for (final n in scene.nodes.values) {
        final id = n.node.id;
        if (!nodeBright(id) && !greyedNodes.contains(id)) {
          _paintNode(canvas, n.node, n.style, n.box);
        }
      }
      canvas.restore();
    }

    // Lines first, so bubbles sit on top of them.
    for (final e in scene.edges) {
      if (!edgeBright(e.edge.id)) continue;
      if (selected is EdgeHit && selected.id == e.edge.id) {
        _paintEdgeGlow(canvas, e);
      }
      _paintEdge(canvas, e);
    }
    for (final n in scene.nodes.values) {
      if (!nodeBright(n.node.id)) continue;
      _paintNode(canvas, n.node, n.style, n.box);
      if ((selected is NodeHit && selected.id == n.node.id) ||
          group.contains(n.node.id)) {
        _paintSelectionRing(canvas, n.style, n.box);
      }
    }
    canvas.restore();
  }

  /// What stays bright for [selected] (and the group).
  ({Set<String> nodes, Set<String> edges}) _focusOf(CanvasHit? selected) {
    if (selected is! WaypointHit) {
      return neighborhoodOf(
        snapshot,
        nodeId: selected is NodeHit ? selected.id : null,
        edgeId: selected is EdgeHit ? selected.id : null,
        group: group,
      );
    }
    // A waypoint: the lines through it and their ends.
    final nodes = <String>{...group}, edges = <String>{};
    for (final e in snapshot.edges.values) {
      if (!e.waypointIds.contains(selected.id)) continue;
      edges.add(e.id);
      nodes.addAll([e.sourceId, e.targetId]);
    }
    return (nodes: nodes, edges: edges);
  }

  void _paintEdgeGlow(Canvas canvas, SceneEdge e) {
    canvas.drawPath(
      _pathThrough(e.path),
      Paint()
        ..color = highlight.withValues(alpha: 0.35)
        ..strokeWidth = snapshot.edgeStyleOf(e.edge).width! + 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static Path _pathThrough(List<Point<double>> points) {
    final path = Path()..moveTo(points.first.x, points.first.y);
    for (final p in points.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    return path;
  }

  void _paintSelectionRing(
    Canvas canvas,
    NodeStyle style,
    Rectangle<double> box,
  ) {
    const gap = 5.0;
    canvas.drawPath(
      shapePath(style.shape!, inflate(box, gap)),
      Paint()
        ..color = highlight
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintEdge(Canvas canvas, SceneEdge e, {bool withLabel = true}) {
    final edge = e.edge;
    final points = e.path;
    final to = points.last;
    // The arrow points along the line's last stretch: from the last point
    // that's at least an arrow's length back (a smoothed line's final
    // sample can be very close to its end).
    final style = snapshot.edgeStyleOf(edge);
    final arrowSize = 6 + 2 * style.width!;
    var back = points.length - 2;
    while (back > 0 && points[back].distanceTo(to) < arrowSize) {
      back--;
    }
    final from = points[back];
    final length = from.distanceTo(to);
    if (length < 1 && points.length == 2) return;
    final width = style.width!;
    final color = Color(style.color!);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = style.lineStyle == LineStyle.dotted
          ? StrokeCap.round
          : StrokeCap.butt;

    final hasArrow = style.arrowhead == Arrowhead.end && length >= 1;
    final ux = length < 1 ? 0.0 : (to.x - from.x) / length;
    final uy = length < 1 ? 0.0 : (to.y - from.y) / length;
    // Stop the line at the arrow's base so the tip stays sharp.
    final end = hasArrow && length > arrowSize
        ? Point(to.x - ux * arrowSize, to.y - uy * arrowSize)
        : to;
    final line = _pathThrough([...points.take(back + 1), end]);
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

    final label = withLabel ? edge.label : null;
    if (label != null) {
      final text = cache.edgeLabel(label, style.color!);
      final mid = Offset(e.label.x, e.label.y);
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
    Rectangle<double> box, {
    bool withText = true,
  }) {
    paintBubble(
      canvas,
      style,
      box,
      withText ? cache.node(node.label, style).text : null,
    );
    if (hiders.contains(node.id)) _paintHiddenBadge(canvas, box);
  }

  static final _eyeOff = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.visibility_off.codePoint),
      style: TextStyle(
        fontFamily: Icons.visibility_off.fontFamily,
        package: Icons.visibility_off.fontPackage,
        fontSize: 12,
        color: const Color(0xFF616161),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  /// A small eye-off disc on the top-right corner: "what's under this is
  /// hidden".
  void _paintHiddenBadge(Canvas canvas, Rectangle<double> box) {
    final c = Offset(box.left + box.width - 4, box.top + 4);
    canvas.drawCircle(c, 10, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(
      c,
      10,
      Paint()
        ..color = const Color(0xFF9E9E9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _eyeOff.paint(canvas, c - Offset(_eyeOff.width / 2, _eyeOff.height / 2));
  }

  @override
  bool shouldRepaint(GraphPainter old) =>
      old.scene != scene ||
      old.selection != selection ||
      old.dimUnrelated != dimUnrelated ||
      old.group != group ||
      !setEquals(old.greyedNodes, greyedNodes) ||
      !setEquals(old.greyedEdges, greyedEdges) ||
      !setEquals(old.hiders, hiders) ||
      old.labelBackground != labelBackground ||
      old.highlight != highlight;
}

/// Draws one bubble: its shape filled, its outline, and its laid-out
/// [text] centred (none for a hidden one). Shared by the canvas and the type previews.
void paintBubble(
  Canvas canvas,
  NodeStyle style,
  Rectangle<double> box,
  TextPainter? text,
) {
  final rect = Rect.fromLTWH(box.left, box.top, box.width, box.height);
  final shape = shapePath(style.shape!, box);
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
  text?.paint(canvas, rect.center - Offset(text.width / 2, text.height / 2));
}

/// A straight line sample in [style] from [from] to [to], with its
/// arrowhead. For the type previews.
void paintLineSample(Canvas canvas, EdgeStyle style, Offset from, Offset to) {
  final width = style.width!;
  final color = Color(style.color!);
  final hasArrow = style.arrowhead == Arrowhead.end;
  final arrowSize = 6 + 2 * width;
  final d = to - from;
  final u = d / d.distance;
  final end = hasArrow ? to - u * arrowSize : to;
  canvas.drawPath(
    dashed(
      Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(end.dx, end.dy),
      style.lineStyle!,
      width,
    ),
    Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = style.lineStyle == LineStyle.dotted
          ? StrokeCap.round
          : StrokeCap.butt,
  );
  if (hasArrow) {
    final side = Offset(-u.dy, u.dx) * (arrowSize / 2);
    canvas.drawPath(
      Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(end.dx + side.dx, end.dy + side.dy)
        ..lineTo(end.dx - side.dx, end.dy - side.dy)
        ..close(),
      Paint()..color = color,
    );
  }
}

/// The outline of [shape] drawn in [box].
Path shapePath(NodeShape shape, Rectangle<double> box) {
  final rect = Rect.fromLTWH(box.left, box.top, box.width, box.height);
  return switch (shape) {
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
