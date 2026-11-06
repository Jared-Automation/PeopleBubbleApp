/// Builds the list view's rows from a [GraphSnapshot]: a flat list in display
/// order, so the UI can lazily build only what's on screen.
///
/// The same bubble can appear in several places (a shared child), so a row is
/// identified by its *path* from the top, not by the node id:
/// - a root row is `r:<nodeId>`
/// - a child row is `<parent key>/<edgeId>`
/// - a shadow row is `<parent key>~<edgeId>`
library;

import 'graph.dart';

enum ListRowKind {
  /// A bubble reached through a hierarchical line (or a root).
  node,

  /// A faded stand-in for a non-hierarchical link. No children; tapping it
  /// jumps to the real bubble.
  shadow,
}

class ListRow {
  const ListRow({
    required this.key,
    required this.kind,
    required this.nodeId,
    required this.depth,
    this.viaEdgeId,
    this.parentNodeId,
    this.hasChildren = false,
    this.expanded = false,
    this.isRepeat = false,
    this.parentCount = 0,
    this.loopCut = false,
  });

  final String key;
  final ListRowKind kind;
  final String nodeId;
  final int depth;

  /// The line linking this row to the row above; null for roots.
  final String? viaEdgeId;
  final String? parentNodeId;
  final bool hasChildren;
  final bool expanded;

  /// A shared bubble shown somewhere other than its first appearance.
  final bool isRepeat;

  /// How many hierarchical parents the bubble has (2+ shows a link marker).
  final int parentCount;

  /// The bubble is already above this row: bad data formed a loop, so the
  /// walk stops here instead of repeating forever.
  final bool loopCut;

  bool get isRoot => viaEdgeId == null;
  bool get isShadow => kind == ListRowKind.shadow;
}

class ListTree {
  const ListTree({required this.rows, required this.homeKeys});

  /// Visible rows, in display order.
  final List<ListRow> rows;

  /// Node id → key of the bubble's first appearance (its "home"), used when
  /// jumping to a bubble. Covers every node, visible or not.
  final Map<String, String> homeKeys;

  /// Keys that must be expanded for [key] to be visible: every ancestor row.
  static List<String> ancestorKeys(String key) {
    final parts = key.split('/');
    return [
      for (var i = 1; i < parts.length; i++) parts.sublist(0, i).join('/'),
    ];
  }

  int indexOfKey(String key) => rows.indexWhere((r) => r.key == key);
}

/// Sorting rules for [buildListTree], passed in so this file doesn't need to
/// know the seeded type ids.
class ListOrder {
  const ListOrder({required this.rootGroup, required this.edgeTypeRank});

  /// Lower groups first among roots (e.g. people 0, everything else 1).
  final int Function(GraphNode node) rootGroup;

  /// Lower ranks first among children (e.g. Loves 0, Likes 1, Dislikes 2).
  final int Function(String edgeTypeId) edgeTypeRank;
}

/// Builds the visible rows.
///
/// A row is expanded by default unless it is a repeat of a shared bubble;
/// keys in [toggled] flip that default.
ListTree buildListTree(
  GraphSnapshot snapshot, {
  required ListOrder order,
  Set<String> toggled = const {},
}) {
  final hierarchical = <String, List<GraphEdge>>{};
  final linked = <String, List<GraphEdge>>{};
  final parentCount = <String, int>{};
  for (final edge in snapshot.edges.values) {
    if (!snapshot.nodes.containsKey(edge.sourceId) ||
        !snapshot.nodes.containsKey(edge.targetId)) {
      continue;
    }
    if (snapshot.isHierarchical(edge)) {
      (hierarchical[edge.sourceId] ??= []).add(edge);
      parentCount[edge.targetId] = (parentCount[edge.targetId] ?? 0) + 1;
    } else {
      (linked[edge.sourceId] ??= []).add(edge);
      (linked[edge.targetId] ??= []).add(edge);
    }
  }

  String labelOf(String nodeId) => snapshot.nodes[nodeId]!.label.toLowerCase();

  int compareChildren(GraphEdge a, GraphEdge b) {
    final rank = order
        .edgeTypeRank(a.typeId)
        .compareTo(order.edgeTypeRank(b.typeId));
    return rank != 0
        ? rank
        : labelOf(a.targetId).compareTo(labelOf(b.targetId));
  }

  for (final list in hierarchical.values) {
    list.sort(compareChildren);
  }
  for (final MapEntry(key: nodeId, value: list) in linked.entries) {
    String other(GraphEdge e) => e.sourceId == nodeId ? e.targetId : e.sourceId;
    list.sort((a, b) => labelOf(other(a)).compareTo(labelOf(other(b))));
  }

  int compareRoots(GraphNode a, GraphNode b) {
    final group = order.rootGroup(a).compareTo(order.rootGroup(b));
    return group != 0 ? group : labelOf(a.id).compareTo(labelOf(b.id));
  }

  // Pass 1: find each node's home (first appearance). Repeats aren't walked
  // again, so this stays linear even with many shared bubbles.
  final homeKeys = <String, String>{};
  void findHomes(String nodeId, String key, Set<String> path) {
    if (homeKeys.containsKey(nodeId) || path.contains(nodeId)) return;
    homeKeys[nodeId] = key;
    path.add(nodeId);
    for (final edge in hierarchical[nodeId] ?? const <GraphEdge>[]) {
      findHomes(edge.targetId, '$key/${edge.id}', path);
    }
    path.remove(nodeId);
  }

  final roots = snapshot.roots.toList()..sort(compareRoots);
  for (final root in roots) {
    findHomes(root.id, 'r:${root.id}', {});
  }
  // Nodes caught only inside a loop (bad import) have no root above them;
  // show them at the top level so nothing disappears.
  final stranded =
      snapshot.nodes.values.where((n) => !homeKeys.containsKey(n.id)).toList()
        ..sort(compareRoots);
  for (final node in stranded) {
    if (homeKeys.containsKey(node.id)) continue;
    roots.add(node);
    findHomes(node.id, 'r:${node.id}', {});
  }

  // Pass 2: emit visible rows, descending only into expanded rows.
  final rows = <ListRow>[];
  void emit(
    String nodeId,
    String key,
    int depth,
    GraphEdge? via,
    Set<String> path,
  ) {
    final loopCut = path.contains(nodeId);
    final children = loopCut
        ? const <GraphEdge>[]
        : hierarchical[nodeId] ?? const <GraphEdge>[];
    final links = loopCut
        ? const <GraphEdge>[]
        : linked[nodeId] ?? const <GraphEdge>[];
    final isRepeat = homeKeys[nodeId] != key;
    final hasChildren = children.isNotEmpty || links.isNotEmpty;
    final expanded = hasChildren && (!isRepeat ^ toggled.contains(key));
    rows.add(
      ListRow(
        key: key,
        kind: ListRowKind.node,
        nodeId: nodeId,
        depth: depth,
        viaEdgeId: via?.id,
        parentNodeId: via?.sourceId,
        hasChildren: hasChildren,
        expanded: expanded,
        isRepeat: isRepeat,
        parentCount: parentCount[nodeId] ?? 0,
        loopCut: loopCut,
      ),
    );
    if (!expanded) return;
    path.add(nodeId);
    for (final edge in children) {
      emit(edge.targetId, '$key/${edge.id}', depth + 1, edge, path);
    }
    for (final edge in links) {
      final other = edge.sourceId == nodeId ? edge.targetId : edge.sourceId;
      rows.add(
        ListRow(
          key: '$key~${edge.id}',
          kind: ListRowKind.shadow,
          nodeId: other,
          depth: depth + 1,
          viaEdgeId: edge.id,
          parentNodeId: nodeId,
          parentCount: parentCount[other] ?? 0,
        ),
      );
    }
    path.remove(nodeId);
  }

  for (final root in roots) {
    emit(root.id, 'r:${root.id}', 0, null, {});
  }
  return ListTree(rows: rows, homeKeys: homeKeys);
}
