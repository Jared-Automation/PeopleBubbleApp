import 'dart:math';

import '../../domain/geometry.dart';
import '../../domain/graph.dart';
import '../../domain/hit_test.dart';
import '../../domain/style.dart';
import 'canvas_layout_cache.dart';

typedef SceneNode = ({GraphNode node, NodeStyle style, Rectangle<double> box});
typedef SceneEdge = ({GraphEdge edge, Point<double> from, Point<double> to});

/// Where everything is on the canvas right now: each placed bubble's box and
/// each line's end points, in world coordinates. Built once per change and
/// shared by the painter and hit testing, so what you see is what you tap.
class CanvasScene {
  CanvasScene._(this.snapshot, this.nodes, this.edges);

  /// [overrides] are live positions (a bubble being dragged) that win over
  /// the saved ones.
  factory CanvasScene.build(
    GraphSnapshot snapshot,
    CanvasLayoutCache cache, {
    Map<String, Point<double>> overrides = const {},
  }) {
    final nodes = <String, SceneNode>{};
    for (final node in snapshot.nodes.values) {
      final center =
          overrides[node.id] ??
          (node.isPlaced ? Point(node.x!, node.y!) : null);
      if (center == null) continue;
      final style = snapshot.styleOf(node);
      nodes[node.id] = (
        node: node,
        style: style,
        box: boxAt(center, cache.node(node.label, style).size),
      );
    }
    final edges = <SceneEdge>[];
    for (final edge in snapshot.edges.values) {
      final a = nodes[edge.sourceId], b = nodes[edge.targetId];
      if (a == null || b == null) continue;
      edges.add((
        edge: edge,
        from: borderPoint(a.style.shape!, a.box, centerOf(b.box)),
        to: borderPoint(b.style.shape!, b.box, centerOf(a.box)),
      ));
    }
    return CanvasScene._(snapshot, nodes, edges);
  }

  final GraphSnapshot snapshot;

  /// Placed bubbles in paint order (later ones on top).
  final Map<String, SceneNode> nodes;
  final List<SceneEdge> edges;

  Rectangle<double>? get bounds => boundsOf(nodes.values.map((n) => n.box));

  /// What's at world point [p]. Touch sizes are in screen pixels and get
  /// converted with the current zoom [scale].
  CanvasHit? hitAt(
    Point<double> p, {
    required double scale,
    double minTargetPx = 48,
    double lineTolerancePx = 24,
  }) => hitTest(
    p,
    nodes: [
      for (final n in nodes.values)
        (id: n.node.id, shape: n.style.shape!, box: n.box),
    ],
    edges: [for (final e in edges) (id: e.edge.id, from: e.from, to: e.to)],
    minTarget: minTargetPx / scale,
    lineTolerance: lineTolerancePx / scale,
  );
}
