import 'style.dart';
import 'types.dart';

class GraphNode {
  const GraphNode({
    required this.id,
    required this.label,
    this.x,
    this.y,
    this.typeIds = const [],
    this.overrides = NodeStyle.empty,
  });

  final String id;
  final String label;

  /// Canvas position; null until the node is first placed.
  final double? x;
  final double? y;

  /// Assigned node types; empty means the base `Node` type.
  final List<String> typeIds;
  final NodeStyle overrides;

  bool get isPlaced => x != null && y != null;
}

class GraphEdge {
  const GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.typeId,
    this.label,
    this.waypointIds = const [],
    this.overrides = EdgeStyle.empty,
  });

  final String id;

  /// The parent end, for hierarchical edges.
  final String sourceId;

  /// The child end, for hierarchical edges.
  final String targetId;
  final String typeId;
  final String? label;

  /// Waypoints the line bends through, in order from source to target.
  final List<String> waypointIds;
  final EdgeStyle overrides;
}

class GraphWaypoint {
  const GraphWaypoint({required this.id, required this.x, required this.y});

  final String id;
  final double x;
  final double y;
}

/// An immutable copy of everything in the database, plus the queries the UI
/// and the service need. Cheap enough to rebuild on every change at the sizes
/// this app deals with (hundreds of nodes).
class GraphSnapshot {
  GraphSnapshot({
    required Iterable<GraphNode> nodes,
    required Iterable<GraphEdge> edges,
    Iterable<GraphWaypoint> waypoints = const [],
    required this.nodeTypes,
    required this.edgeTypes,
  }) : nodes = {for (final n in nodes) n.id: n},
       edges = {for (final e in edges) e.id: e},
       waypoints = {for (final w in waypoints) w.id: w};

  final Map<String, GraphNode> nodes;
  final Map<String, GraphEdge> edges;
  final Map<String, GraphWaypoint> waypoints;
  final TypeHierarchy<NodeStyle> nodeTypes;
  final TypeHierarchy<EdgeStyle> edgeTypes;

  NodeStyle styleOf(GraphNode node) =>
      nodeTypes.resolve(node.typeIds, overrides: node.overrides);

  EdgeStyle edgeStyleOf(GraphEdge edge) =>
      edgeTypes.resolve([edge.typeId], overrides: edge.overrides);

  /// Whether [edge] is part of the parent/child structure. Decided by its
  /// type alone; per-edge overrides can't change it.
  bool isHierarchical(GraphEdge edge) =>
      edgeTypes.resolve([edge.typeId]).hierarchical ?? true;

  Iterable<GraphEdge> get hierarchicalEdges =>
      edges.values.where(isHierarchical);

  /// Nodes with no incoming hierarchical edge.
  Iterable<GraphNode> get roots {
    final children = {for (final e in hierarchicalEdges) e.targetId};
    return nodes.values.where((n) => !children.contains(n.id));
  }
}

/// [rootId] and everything below it through hierarchical lines (shared
/// things included). Stops on repeats, so looped data can't hang it.
Set<String> subtreeOf(GraphSnapshot snapshot, String rootId) {
  final childrenOf = <String, List<String>>{};
  for (final e in snapshot.hierarchicalEdges) {
    (childrenOf[e.sourceId] ??= []).add(e.targetId);
  }
  final result = <String>{};
  final stack = [rootId];
  while (stack.isNotEmpty) {
    final id = stack.removeLast();
    if (!snapshot.nodes.containsKey(id) || !result.add(id)) continue;
    stack.addAll(childrenOf[id] ?? const []);
  }
  return result;
}

/// What to keep bright when something is selected: the item, its lines and
/// the bubbles at their other ends (all line types, hierarchical or not).
///
/// A [group] (e.g. a selected subtree) stays bright along with the lines
/// inside it.
({Set<String> nodes, Set<String> edges}) neighborhoodOf(
  GraphSnapshot snapshot, {
  String? nodeId,
  String? edgeId,
  Set<String> group = const {},
}) {
  final nodes = <String>{...group}, edges = <String>{};
  if (group.isNotEmpty) {
    for (final e in snapshot.edges.values) {
      if (group.contains(e.sourceId) && group.contains(e.targetId)) {
        edges.add(e.id);
      }
    }
  }
  if (nodeId != null) {
    nodes.add(nodeId);
    for (final e in snapshot.edges.values) {
      if (e.sourceId == nodeId || e.targetId == nodeId) {
        edges.add(e.id);
        nodes
          ..add(e.sourceId)
          ..add(e.targetId);
      }
    }
  }
  final edge = edgeId == null ? null : snapshot.edges[edgeId];
  if (edge != null) {
    edges.add(edge.id);
    nodes
      ..add(edge.sourceId)
      ..add(edge.targetId);
  }
  return (nodes: nodes, edges: edges);
}

/// Whether adding a hierarchical edge [parentId] → [childId] would form a loop,
/// given the existing hierarchical [edges] as (parent, child) pairs.
///
/// A loop exists if the parent is already reachable from the child. The walk
/// tracks visited nodes, so it terminates even if [edges] already has a cycle.
bool edgeWouldCreateCycle({
  required String parentId,
  required String childId,
  required Iterable<(String parent, String child)> edges,
}) {
  if (parentId == childId) return true;
  final childrenOf = <String, List<String>>{};
  for (final (parent, child) in edges) {
    (childrenOf[parent] ??= []).add(child);
  }
  final visited = <String>{};
  final stack = [childId];
  while (stack.isNotEmpty) {
    final current = stack.removeLast();
    if (current == parentId) return true;
    if (!visited.add(current)) continue;
    stack.addAll(childrenOf[current] ?? const []);
  }
  return false;
}

/// Whether the hierarchical [edges] already contain a loop anywhere.
/// Used before changing an edge type to hierarchical, and on import.
bool graphHasCycle(Iterable<(String parent, String child)> edges) {
  final childrenOf = <String, List<String>>{};
  for (final (parent, child) in edges) {
    (childrenOf[parent] ??= []).add(child);
  }
  // Iterative three-colour DFS: a grey node reached again means a back edge.
  const white = 0, grey = 1, black = 2;
  final colour = <String, int>{};
  for (final start in childrenOf.keys) {
    if ((colour[start] ?? white) != white) continue;
    final stack = <(String, Iterator<String>)>[
      (start, (childrenOf[start] ?? const <String>[]).iterator),
    ];
    colour[start] = grey;
    while (stack.isNotEmpty) {
      final (node, children) = stack.last;
      if (children.moveNext()) {
        final next = children.current;
        final c = colour[next] ?? white;
        if (c == grey) return true;
        if (c == white) {
          colour[next] = grey;
          stack.add((next, (childrenOf[next] ?? const <String>[]).iterator));
        }
      } else {
        colour[node] = black;
        stack.removeLast();
      }
    }
  }
  return false;
}
