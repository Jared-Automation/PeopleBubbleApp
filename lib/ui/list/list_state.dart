import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/providers.dart';
import '../../data/seed.dart';
import '../../domain/graph.dart';
import '../../domain/list_tree.dart';

/// Loaded once in `main()` and injected with an override, so reads are
/// synchronous everywhere else.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main() / tests'),
);

/// The line type the add sheet starts on: the last one used, across launches.
class LastEdgeTypeNotifier extends Notifier<String> {
  static const _key = 'lastEdgeTypeId';

  @override
  String build() =>
      ref.watch(sharedPreferencesProvider).getString(_key) ?? SeedIds.likes;

  void set(String edgeTypeId) {
    state = edgeTypeId;
    ref.read(sharedPreferencesProvider).setString(_key, edgeTypeId);
  }
}

final lastEdgeTypeProvider = NotifierProvider<LastEdgeTypeNotifier, String>(
  LastEdgeTypeNotifier.new,
);

/// Row keys whose expanded state differs from the default. In memory only.
class ExpansionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String key) =>
      state = state.contains(key) ? ({...state}..remove(key)) : {...state, key};

  /// Expands every ancestor of the row [key] so it becomes visible. Ancestors
  /// of a home row are never repeats, so "expanded" is their default.
  void reveal(String key) =>
      state = {...state}..removeAll(ListTree.ancestorKeys(key));
}

final expansionProvider = NotifierProvider<ExpansionNotifier, Set<String>>(
  ExpansionNotifier.new,
);

/// Roots: people first. Children: Loves, Likes, Dislikes, then the rest.
ListOrder listOrderFor(GraphSnapshot s) {
  const edgeOrder = [SeedIds.loves, SeedIds.likes, SeedIds.dislikes];
  bool isPerson(String typeId) =>
      typeId == SeedIds.person ||
      s.nodeTypes.isAncestor(SeedIds.person, typeId);
  return ListOrder(
    rootGroup: (node) => node.typeIds.any(isPerson) ? 0 : 1,
    edgeTypeRank: (typeId) => switch (edgeOrder.indexOf(typeId)) {
      -1 => edgeOrder.length,
      final i => i,
    },
  );
}

/// The snapshot and the rows built from it, rebuilt when either the data or
/// the expanded rows change.
final listTreeProvider = Provider<AsyncValue<(GraphSnapshot, ListTree)>>((ref) {
  final toggled = ref.watch(expansionProvider);
  return ref
      .watch(graphSnapshotProvider)
      .whenData(
        (s) => (s, buildListTree(s, order: listOrderFor(s), toggled: toggled)),
      );
});
