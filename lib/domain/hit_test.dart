/// What's under a finger on the canvas. Plain Dart: the caller converts the
/// screen point to world coordinates and passes touch sizes in world units.
library;

import 'dart:math';

import 'geometry.dart';
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

typedef HitNode = ({String id, NodeShape shape, Rectangle<double> box});
typedef HitEdge = ({String id, Point<double> from, Point<double> to});

/// The bubble or line at [p], or null for empty canvas.
///
/// - A bubble is hit inside its shape, or inside a box at least [minTarget]
///   across centred on it, so small or zoomed-out bubbles stay tappable.
///   Among several, the one whose centre is closest wins.
/// - A line is hit within [lineTolerance] of it; the closest wins.
/// - Bubbles win over lines.
CanvasHit? hitTest(
  Point<double> p, {
  required Iterable<HitNode> nodes,
  required Iterable<HitEdge> edges,
  required double minTarget,
  required double lineTolerance,
}) {
  String? bestNode;
  var bestNodeDistance = double.infinity;
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
    final d = p.distanceTo(centerOf(n.box));
    if (d < bestNodeDistance) (bestNode, bestNodeDistance) = (n.id, d);
  }
  if (bestNode != null) return NodeHit(bestNode);

  String? bestEdge;
  var bestEdgeDistance = lineTolerance;
  for (final e in edges) {
    final d = distanceToSegment(p, e.from, e.to);
    if (d <= bestEdgeDistance) (bestEdge, bestEdgeDistance) = (e.id, d);
  }
  return bestEdge == null ? null : EdgeHit(bestEdge);
}
