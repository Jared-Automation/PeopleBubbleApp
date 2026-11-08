/// What's under a finger on the canvas. Plain Dart: the caller converts the
/// screen point to world coordinates and passes touch sizes in world units.
library;

import 'dart:math';

import 'geometry.dart';
import 'polyline.dart';
import 'style.dart';

sealed class CanvasHit {
  const CanvasHit(this.id);

  final String id;
}

final class NodeHit extends CanvasHit {
  const NodeHit(super.id);

  @override
  bool operator ==(Object other) => other is NodeHit && other.id == id;

  @override
  int get hashCode => Object.hash(NodeHit, id);

  @override
  String toString() => 'NodeHit($id)';
}

final class EdgeHit extends CanvasHit {
  const EdgeHit(super.id);

  @override
  bool operator ==(Object other) => other is EdgeHit && other.id == id;

  @override
  int get hashCode => Object.hash(EdgeHit, id);

  @override
  String toString() => 'EdgeHit($id)';
}

final class WaypointHit extends CanvasHit {
  const WaypointHit(super.id);

  @override
  bool operator ==(Object other) => other is WaypointHit && other.id == id;

  @override
  int get hashCode => Object.hash(WaypointHit, id);

  @override
  String toString() => 'WaypointHit($id)';
}

typedef HitNode = ({String id, NodeShape shape, Rectangle<double> box});

/// A line as drawn: its points from source end to target end.
typedef HitEdge = ({String id, List<Point<double>> points});
typedef HitWaypoint = ({String id, Point<double> at});

/// The waypoint, bubble or line at [p], or null for empty canvas.
///
/// - A waypoint handle is hit within [minTarget] / 2 of it; the closest
///   wins. Only the [waypoints] passed in (the visible handles) count, and
///   they win over everything else: they're small and grabbed on purpose.
/// - A bubble is hit inside its shape, or inside a box at least [minTarget]
///   across centred on it, so small or zoomed-out bubbles stay tappable.
///   Among several, the one whose centre is closest wins.
/// - A line is hit within [lineTolerance] of it; the closest wins.
/// - Inside a bubble's actual shape, the bubble wins. In the padding around
///   a small bubble, a line wins if it's nearer than the bubble's edge, so
///   lines stay selectable when zoomed out among tiny bubbles.
CanvasHit? hitTest(
  Point<double> p, {
  required Iterable<HitNode> nodes,
  required Iterable<HitEdge> edges,
  Iterable<HitWaypoint> waypoints = const [],
  required double minTarget,
  required double lineTolerance,
}) {
  String? bestWaypoint;
  var bestWaypointDistance = minTarget / 2;
  for (final w in waypoints) {
    final d = p.distanceTo(w.at);
    if (d <= bestWaypointDistance) {
      (bestWaypoint, bestWaypointDistance) = (w.id, d);
    }
  }
  if (bestWaypoint != null) return WaypointHit(bestWaypoint);

  String? bestNode;
  var bestNodeDistance = double.infinity;
  var bestNodeInShape = false;
  var bestNodeGap = 0.0;
  for (final n in nodes) {
    final padX = max(0.0, (minTarget - n.box.width) / 2);
    final padY = max(0.0, (minTarget - n.box.height) / 2);
    final target = Rectangle(
      n.box.left - padX,
      n.box.top - padY,
      n.box.width + 2 * padX,
      n.box.height + 2 * padY,
    );
    final inside = (padX > 0 || padY > 0)
        ? target.containsPoint(p)
        : shapeContains(n.shape, n.box, p);
    if (!inside) continue;
    final inShape = shapeContains(n.shape, n.box, p);
    final d = p.distanceTo(centerOf(n.box));
    // A hit on the shape itself beats one in another bubble's padding.
    if ((inShape && !bestNodeInShape) ||
        (inShape == bestNodeInShape && d < bestNodeDistance)) {
      bestNode = n.id;
      bestNodeDistance = d;
      bestNodeInShape = inShape;
      bestNodeGap = gapBetween(Rectangle(p.x, p.y, 0, 0), n.box);
    }
  }
  if (bestNode != null && bestNodeInShape) return NodeHit(bestNode);

  String? bestEdge;
  var bestEdgeDistance = lineTolerance;
  for (final e in edges) {
    final d = distanceToPolyline(p, e.points);
    if (d <= bestEdgeDistance) (bestEdge, bestEdgeDistance) = (e.id, d);
  }
  if (bestNode != null &&
      (bestEdge == null || bestNodeGap <= bestEdgeDistance)) {
    return NodeHit(bestNode);
  }
  return bestEdge == null ? null : EdgeHit(bestEdge);
}
