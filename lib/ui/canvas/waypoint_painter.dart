import 'package:flutter/widgets.dart';

import '../../domain/hit_test.dart';
import 'canvas_scene.dart';

/// Waypoint handles, clamp dots and drop targets, drawn in screen space over
/// the canvas so they stay finger-sized at any zoom. Like the grid, it
/// repaints on every pan/zoom, but it only draws a handful of circles.
class WaypointPainter extends CustomPainter {
  WaypointPainter({
    required this.transform,
    required this.origin,
    required this.scene,
    required this.color,
    required this.background,
    this.selection,
    this.handles = const {},
    this.mergeTarget,
    this.showAll = false,
  }) : super(repaint: transform);

  final TransformationController transform;

  /// Where world (0, 0) sits inside the viewer's child.
  final Offset origin;
  final CanvasScene scene;
  final Color color, background;
  final CanvasHit? selection;

  /// Waypoints drawn as grab handles (see [CanvasScene.handlesFor]).
  final Set<String> handles;

  /// The waypoint a dragged one would clamp onto if dropped now.
  final String? mergeTarget;

  /// While a waypoint is dragged, every waypoint shows as a possible target.
  final bool showAll;

  @override
  void paint(Canvas canvas, Size size) {
    final m = transform.value;
    final fill = Paint()..color = color;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final faint = Paint()..color = color.withValues(alpha: 0.3);
    final back = Paint()..color = background;
    final bounds = (Offset.zero & size).inflate(24);

    for (final MapEntry(key: id, value: p) in scene.waypoints.entries) {
      final at = MatrixUtils.transformPoint(
        m,
        Offset(p.x + origin.dx, p.y + origin.dy),
      );
      if (!bounds.contains(at)) continue;
      final isSelected = selection is WaypointHit && selection!.id == id;
      if (id == mergeTarget) {
        canvas.drawCircle(at, 22, faint);
        canvas.drawCircle(at, 22, ring);
      }
      if (handles.contains(id) || isSelected) {
        final r = isSelected ? 11.0 : 9.0;
        canvas.drawCircle(at, r, back);
        canvas.drawCircle(at, r, isSelected ? fill : ring);
      } else if (scene.isShared(id)) {
        canvas.drawCircle(at, 5, fill);
      } else if (showAll) {
        canvas.drawCircle(at, 6, faint);
      }
    }
  }

  @override
  bool shouldRepaint(WaypointPainter old) =>
      old.scene != scene ||
      old.selection != selection ||
      old.mergeTarget != mergeTarget ||
      old.showAll != showAll ||
      old.color != color ||
      old.handles.length != handles.length ||
      !old.handles.containsAll(handles);
}
