import 'dart:math';

import 'graph.dart';
import 'style.dart';

/// One copied bubble. [id] is the original's id, used only to match lines.
class CopiedNode {
  const CopiedNode({
    required this.id,
    required this.label,
    required this.typeIds,
    required this.overrides,
    this.x,
    this.y,
  });

  final String id;
  final String label;
  final List<String> typeIds;
  final NodeStyle overrides;
  final double? x;
  final double? y;
}

/// One copied line between two copied bubbles (original ids).
class CopiedEdge {
  const CopiedEdge({
    required this.sourceId,
    required this.targetId,
    required this.typeId,
    required this.label,
    required this.overrides,
    required this.waypointIds,
  });

  final String sourceId;
  final String targetId;
  final String typeId;
  final String? label;
  final EdgeStyle overrides;

  /// Original waypoint ids, in order; see [SubtreeCopy.waypoints].
  final List<String> waypointIds;
}

/// A bubble and everything under it, as plain data: what "Copy" holds and
/// "Paste" recreates as new bubbles. Lines to bubbles outside the group are
/// left out.
class SubtreeCopy {
  const SubtreeCopy({
    required this.rootId,
    required this.nodes,
    required this.edges,
    required this.waypoints,
    required this.outline,
  });

  final String rootId;

  /// Original id → copied bubble. The root is included.
  final Map<String, CopiedNode> nodes;
  final List<CopiedEdge> edges;

  /// Original waypoint id → position. A waypoint shared by two copied lines
  /// stays shared in the paste.
  final Map<String, Point<double>> waypoints;

  /// The names as an indented outline, for the system clipboard.
  final String outline;

  CopiedNode get root => nodes[rootId]!;

  /// How many bubbles are under the root.
  int get belowCount => nodes.length - 1;
}

/// Copies [rootId] and everything below it (through hierarchical lines),
/// with every line between those bubbles. Loop-safe.
SubtreeCopy copySubtree(GraphSnapshot s, String rootId) {
  final ids = subtreeOf(s, rootId);
  final edges = [
    for (final e in s.edges.values)
      if (ids.contains(e.sourceId) && ids.contains(e.targetId)) e,
  ];
  final waypoints = <String, Point<double>>{
    for (final e in edges)
      for (final w in e.waypointIds)
        if (s.waypoints[w] case final wp?) w: Point(wp.x, wp.y),
  };
  return SubtreeCopy(
    rootId: rootId,
    nodes: {
      for (final id in ids)
        id: () {
          final n = s.nodes[id]!;
          return CopiedNode(
            id: id,
            label: n.label,
            typeIds: n.typeIds,
            overrides: n.overrides,
            x: n.x,
            y: n.y,
          );
        }(),
    },
    edges: [
      for (final e in edges)
        CopiedEdge(
          sourceId: e.sourceId,
          targetId: e.targetId,
          typeId: e.typeId,
          label: e.label,
          overrides: e.overrides,
          waypointIds: [
            for (final w in e.waypointIds)
              if (waypoints.containsKey(w)) w,
          ],
        ),
    ],
    waypoints: waypoints,
    outline: _outline(s, rootId, ids),
  );
}

/// "Sam\n  Sushi\n    Salmon" – each bubble once, children A–Z.
String _outline(GraphSnapshot s, String rootId, Set<String> ids) {
  final childrenOf = <String, List<String>>{};
  for (final e in s.hierarchicalEdges) {
    if (ids.contains(e.sourceId) && ids.contains(e.targetId)) {
      (childrenOf[e.sourceId] ??= []).add(e.targetId);
    }
  }
  final lines = <String>[];
  final seen = <String>{};
  void walk(String id, int depth) {
    if (!seen.add(id)) return;
    lines.add('${'  ' * depth}${s.nodes[id]!.label}');
    final kids = [...?childrenOf[id]]
      ..sort(
        (a, b) => s.nodes[a]!.label.toLowerCase().compareTo(
          s.nodes[b]!.label.toLowerCase(),
        ),
      );
    for (final k in kids) {
      walk(k, depth + 1);
    }
  }

  walk(rootId, 0);
  return lines.join('\n');
}
