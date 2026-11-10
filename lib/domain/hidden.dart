import 'graph.dart';

/// Which bubbles sit under a "hidden" bubble (one whose resolved style has
/// `hidden: true`), worked out once per snapshot.
///
/// A bubble is *under* a hidden one when every way down to it from the top
/// passes through a hidden bubble. So a thing shared with someone who isn't
/// hidden stays visible. The hidden bubble itself stays visible (unless it
/// is itself under another hidden bubble). All walks stop on repeats, so
/// looped data from an import can't hang them.
class HiddenGroups {
  HiddenGroups._(this.hiders, this.groups, this.under);

  factory HiddenGroups.of(GraphSnapshot s) {
    final hiders = {
      for (final n in s.nodes.values)
        if (s.styleOf(n).hidden ?? false) n.id,
    };
    if (hiders.isEmpty) return HiddenGroups._(const {}, const {}, const {});

    final childrenOf = <String, List<String>>{};
    for (final e in s.hierarchicalEdges) {
      (childrenOf[e.sourceId] ??= []).add(e.targetId);
    }

    // Everything reachable from the top without going *through* a hidden
    // bubble (reaching one is fine; its children are not).
    final open = <String>{};
    final stack = [for (final r in s.roots) r.id];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      if (!open.add(id) || hiders.contains(id)) continue;
      stack.addAll(childrenOf[id] ?? const []);
    }

    // Each hidden bubble's group: everything below it.
    final groups = <String, Set<String>>{};
    for (final h in hiders) {
      final below = <String>{};
      final todo = [...?childrenOf[h]];
      while (todo.isNotEmpty) {
        final id = todo.removeLast();
        if (id == h || !below.add(id)) continue;
        todo.addAll(childrenOf[id] ?? const []);
      }
      groups[h] = below;
    }

    final under = {
      for (final below in groups.values)
        for (final id in below)
          if (!open.contains(id)) id,
    };
    return HiddenGroups._(hiders, groups, under);
  }

  /// Bubbles marked hidden.
  final Set<String> hiders;

  /// Hidden bubble → every bubble below it.
  final Map<String, Set<String>> groups;

  /// Bubbles greyed out when nothing is revealed.
  final Set<String> under;

  bool get isEmpty => under.isEmpty;

  /// The bubbles and lines to grey out. Selecting a hidden bubble, or any
  /// bubble in its group, reveals that whole group: pass those ids as
  /// [selected]. [showHidden] reveals everything.
  ({Set<String> nodes, Set<String> edges}) greyed(
    GraphSnapshot s, {
    Iterable<String> selected = const [],
    bool showHidden = false,
  }) {
    if (showHidden || under.isEmpty) return (nodes: const {}, edges: const {});
    final picked = selected.toSet();
    final revealed = <String>{};
    for (final MapEntry(key: h, value: below) in groups.entries) {
      if (picked.contains(h) || below.any(picked.contains)) {
        revealed.addAll(below);
      }
    }
    final nodes = under.difference(revealed);
    if (nodes.isEmpty) return (nodes: const {}, edges: const {});
    return (
      nodes: nodes,
      edges: {
        for (final e in s.edges.values)
          if (nodes.contains(e.sourceId) || nodes.contains(e.targetId)) e.id,
      },
    );
  }
}
