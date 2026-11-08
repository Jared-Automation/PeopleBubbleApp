import 'dart:math';

import '../../domain/geometry.dart';
import '../../domain/graph.dart';
import '../../domain/hit_test.dart';
import '../../domain/polyline.dart';
import '../../domain/style.dart';
import 'canvas_layout_cache.dart';

typedef SceneNode = ({GraphNode node, NodeStyle style, Rectangle<double> box});

/// A line as drawn.
/// - [corners]: its source end, its waypoints, its target end.
/// - [path]: what gets stroked, the same as [corners] unless lines are
///   smoothed.
/// - [label]: where its label sits.
typedef SceneEdge = ({
  GraphEdge edge,
  List<Point<double>> corners,
  List<Point<double>> path,
  Point<double> label,
});

/// A waypoint being added by dragging a selected line: drawn as if it were
/// already saved, [index]-th along line [edgeId].
typedef PendingBend = ({String edgeId, int index, Point<double> at});

/// Id used for a [PendingBend]'s waypoint while it's being dragged.
const pendingWaypointId = '_pending';

/// Where everything is on the canvas right now: each placed bubble's box,
/// each line's path and each waypoint, in world coordinates. Built once per
/// change and shared by the painter and hit testing, so what you see is
/// what you tap.
class CanvasScene {
  CanvasScene._(
    this.snapshot,
    this.nodes,
    this.edges,
    this.waypoints,
    this.waypointUse,
  );

  /// [overrides] and [waypointOverrides] are live positions (something
  /// being dragged) that win over the saved ones.
  factory CanvasScene.build(
    GraphSnapshot snapshot,
    CanvasLayoutCache cache, {
    Map<String, Point<double>> overrides = const {},
    Map<String, Point<double>> waypointOverrides = const {},
    PendingBend? bend,
    bool smooth = false,
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

    final waypoints = <String, Point<double>>{
      for (final w in snapshot.waypoints.values)
        w.id: waypointOverrides[w.id] ?? Point(w.x, w.y),
      if (bend != null) pendingWaypointId: bend.at,
    };
    final use = <String, int>{};

    final edges = <SceneEdge>[];
    for (final edge in snapshot.edges.values) {
      final a = nodes[edge.sourceId], b = nodes[edge.targetId];
      if (a == null || b == null) continue;
      final ids = [...edge.waypointIds];
      if (bend != null && bend.edgeId == edge.id) {
        ids.insert(bend.index.clamp(0, ids.length), pendingWaypointId);
      }
      final bends = [for (final id in ids) ?waypoints[id]];
      for (final id in ids.toSet()) {
        use[id] = (use[id] ?? 0) + 1;
      }
      final first = bends.isEmpty ? centerOf(b.box) : bends.first;
      final last = bends.isEmpty ? centerOf(a.box) : bends.last;
      final corners = [
        borderPoint(a.style.shape!, a.box, first),
        ...bends,
        borderPoint(b.style.shape!, b.box, last),
      ];
      final path = smooth ? smoothPolyline(corners) : corners;
      final anchor = labelAnchor(corners);
      edges.add((
        edge: edge,
        corners: corners,
        path: path,
        label: smooth ? _nearestOn(path, anchor) : anchor,
      ));
    }
    return CanvasScene._(snapshot, nodes, edges, waypoints, use);
  }

  final GraphSnapshot snapshot;

  /// Placed bubbles in paint order (later ones on top).
  final Map<String, SceneNode> nodes;
  final List<SceneEdge> edges;

  /// Every waypoint's current position (including a pending one).
  final Map<String, Point<double>> waypoints;

  /// How many drawn lines bend through each waypoint.
  final Map<String, int> waypointUse;

  bool isShared(String waypointId) => (waypointUse[waypointId] ?? 0) > 1;

  /// Waypoints shown as grab handles for [selection]: those of a selected
  /// line, or of every line through a selected waypoint. Shared waypoints
  /// (clamps) are always shown.
  Set<String> handlesFor(CanvasHit? selection) => {
    for (final id in waypoints.keys)
      if (isShared(id)) id,
    ...switch (selection) {
      EdgeHit(:final id) => snapshot.edges[id]?.waypointIds ?? const [],
      WaypointHit(:final id) => {
        id,
        for (final e in snapshot.edges.values)
          if (e.waypointIds.contains(id)) ...e.waypointIds,
      },
      _ => const <String>[],
    },
  };

  SceneEdge? edgeById(String id) {
    for (final e in edges) {
      if (e.edge.id == id) return e;
    }
    return null;
  }

  Rectangle<double>? get bounds => boundsOf(nodes.values.map((n) => n.box));

  /// What's at world point [p]. Touch sizes are in screen pixels and get
  /// converted with the current zoom [scale]. Only the waypoints visible for
  /// [selection] can be hit.
  CanvasHit? hitAt(
    Point<double> p, {
    required double scale,
    CanvasHit? selection,
    double minTargetPx = 48,
    double lineTolerancePx = 24,
  }) => hitTest(
    p,
    nodes: [
      for (final n in nodes.values)
        (id: n.node.id, shape: n.style.shape!, box: n.box),
    ],
    edges: [for (final e in edges) (id: e.edge.id, points: e.path)],
    waypoints: [
      for (final id in handlesFor(selection))
        if (waypoints[id] case final at?) (id: id, at: at),
    ],
    minTarget: minTargetPx / scale,
    lineTolerance: lineTolerancePx / scale,
  );

  /// The waypoint (other than [except]) within [radius] of [p], closest
  /// first: where a dragged waypoint would clamp.
  String? waypointNear(Point<double> p, double radius, {String? except}) {
    String? best;
    var bestDistance = radius;
    for (final MapEntry(key: id, value: at) in waypoints.entries) {
      if (id == except || id == pendingWaypointId) continue;
      final d = p.distanceTo(at);
      if (d <= bestDistance) (best, bestDistance) = (id, d);
    }
    return best;
  }

  static Point<double> _nearestOn(List<Point<double>> path, Point<double> p) {
    var best = path.first;
    for (final q in path) {
      if (q.distanceTo(p) < best.distanceTo(p)) best = q;
    }
    return best;
  }
}
