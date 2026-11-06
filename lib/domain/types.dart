import 'style.dart';

/// A node type or edge type: a name, one parent, and the style fields it sets.
///
/// Like a class with single inheritance. The one type with no parent is the
/// built-in base (`Node` or `Edge`), which holds the default style.
class TypeDef<S extends Style<S>> {
  const TypeDef({
    required this.id,
    required this.name,
    required this.parentId,
    required this.style,
    this.builtIn = false,
  });

  final String id;
  final String name;
  final String? parentId;
  final S style;
  final bool builtIn;

  bool get isBase => parentId == null;

  TypeDef<S> copyWith({String? name, String? parentId, S? style}) => TypeDef(
    id: id,
    name: name ?? this.name,
    parentId: parentId ?? this.parentId,
    style: style ?? this.style,
    builtIn: builtIn,
  );
}

typedef NodeTypeDef = TypeDef<NodeStyle>;
typedef EdgeTypeDef = TypeDef<EdgeStyle>;

/// Two assigned types that set the same field to different values.
class TypeConflict {
  const TypeConflict(this.typeA, this.typeB, this.fields);

  final String typeA;
  final String typeB;

  /// Names of the fields that differ, e.g. `['outlineColor']`.
  final List<String> fields;

  @override
  String toString() => 'TypeConflict($typeA, $typeB, $fields)';
}

/// All types of one kind (node or edge), with inheritance queries.
///
/// Every walk up the tree stops on a repeat, so bad imported data (a type that
/// is its own ancestor) can't hang the app.
class TypeHierarchy<S extends Style<S>> {
  TypeHierarchy(
    Iterable<TypeDef<S>> types, {
    required this.appDefaults,
    required this.empty,
  }) : byId = {for (final t in types) t.id: t};

  static TypeHierarchy<NodeStyle> nodes(Iterable<NodeTypeDef> types) =>
      TypeHierarchy(
        types,
        appDefaults: NodeStyle.appDefaults,
        empty: NodeStyle.empty,
      );

  static TypeHierarchy<EdgeStyle> edges(Iterable<EdgeTypeDef> types) =>
      TypeHierarchy(
        types,
        appDefaults: EdgeStyle.appDefaults,
        empty: EdgeStyle.empty,
      );

  final Map<String, TypeDef<S>> byId;

  /// Fallback for every field, applied under the base type.
  final S appDefaults;

  /// A style with no fields set.
  final S empty;

  /// The base type (the root with no parent), if present.
  TypeDef<S>? get base {
    for (final t in byId.values) {
      if (t.isBase) return t;
    }
    return null;
  }

  /// [id] and its ancestors, top ancestor first. Unknown ids are skipped.
  List<TypeDef<S>> chain(String id) {
    final reversed = <TypeDef<S>>[];
    final seen = <String>{};
    String? current = id;
    while (current != null && seen.add(current)) {
      final type = byId[current];
      if (type == null) break;
      reversed.add(type);
      current = type.parentId;
    }
    return reversed.reversed.toList();
  }

  /// Whether [ancestorId] is a strict ancestor of [id].
  bool isAncestor(String ancestorId, String id) =>
      ancestorId != id && chain(id).any((t) => t.id == ancestorId);

  /// Whether giving [typeId] the parent [newParentId] would make a type its
  /// own ancestor.
  bool parentWouldCreateCycle(String typeId, String newParentId) =>
      newParentId == typeId || isAncestor(typeId, newParentId);

  /// The fields [id] sets itself or through its ancestors, excluding the base
  /// type's defaults. This is what the conflict check compares.
  S ownFields(String id) {
    var result = empty;
    for (final type in chain(id)) {
      if (!type.isBase) result = type.style.mergeOver(result);
    }
    return result;
  }

  /// Drops duplicates, unknown ids, and any type that is an ancestor of
  /// another assigned type (assigning Person and Partner keeps Partner).
  /// Keeps the original order. An empty result means "just the base type".
  List<String> normalize(Iterable<String> typeIds) {
    final unique = <String>[];
    for (final id in typeIds) {
      if (byId.containsKey(id) && !unique.contains(id)) unique.add(id);
    }
    return [
      for (final id in unique)
        if (!unique.any((other) => isAncestor(id, other))) id,
    ];
  }

  /// Every pair of [typeIds] that conflicts, after [normalize].
  List<TypeConflict> conflicts(Iterable<String> typeIds) {
    final ids = normalize(typeIds);
    final result = <TypeConflict>[];
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final conflict = _conflictBetween(ids[i], ids[j]);
        if (conflict != null) result.add(conflict);
      }
    }
    return result;
  }

  /// Why [candidateId] can't be added to [assignedIds], or an empty list if
  /// it can. Used to grey out types in the picker with a reason.
  List<TypeConflict> conflictsIfAdded(
    String candidateId,
    Iterable<String> assignedIds,
  ) => [
    for (final c in conflicts([...assignedIds, candidateId]))
      if (c.typeA == candidateId || c.typeB == candidateId) c,
  ];

  /// The final style: app defaults, then each assigned type from its top
  /// ancestor down, then [overrides]. With no types, the base type applies.
  S resolve(Iterable<String> typeIds, {S? overrides}) {
    var ids = normalize(typeIds);
    if (ids.isEmpty && base != null) ids = [base!.id];
    var result = appDefaults;
    final applied = <String>{};
    for (final id in ids) {
      for (final type in chain(id)) {
        // A shared ancestor gives the same values each time; apply it once.
        if (applied.add(type.id)) result = type.style.mergeOver(result);
      }
    }
    return overrides == null ? result : overrides.mergeOver(result);
  }

  /// A sentence for the UI, e.g. "Partner and Friend both set outline color".
  String describe(TypeConflict conflict) {
    final a = byId[conflict.typeA]?.name ?? conflict.typeA;
    final b = byId[conflict.typeB]?.name ?? conflict.typeB;
    final fields = conflict.fields.map((f) => styleFieldLabels[f] ?? f);
    return '$a and $b both set ${fields.join(', ')}';
  }

  /// This hierarchy with [type] added or replaced.
  TypeHierarchy<S> withType(TypeDef<S> type) => TypeHierarchy(
    [...byId.values.where((t) => t.id != type.id), type],
    appDefaults: appDefaults,
    empty: empty,
  );

  TypeConflict? _conflictBetween(String a, String b) {
    final fieldsA = ownFields(a).setFields;
    final fieldsB = ownFields(b).setFields;
    final differing = [
      for (final entry in fieldsA.entries)
        if (fieldsB.containsKey(entry.key) && fieldsB[entry.key] != entry.value)
          entry.key,
    ];
    return differing.isEmpty ? null : TypeConflict(a, b, differing);
  }
}

/// Nodes whose assigned types would conflict if [edited] replaced its current
/// definition. [nodeTypeIds] maps node id to its assigned type ids.
///
/// Returns node id → the conflicts it would have. Empty means the edit is safe.
Map<String, List<TypeConflict>> nodesBrokenByTypeEdit<S extends Style<S>>(
  TypeHierarchy<S> hierarchy,
  TypeDef<S> edited,
  Map<String, List<String>> nodeTypeIds,
) {
  final after = hierarchy.withType(edited);
  return {
    for (final MapEntry(key: nodeId, value: typeIds) in nodeTypeIds.entries)
      if (typeIds.length > 1 && after.conflicts(typeIds).isNotEmpty)
        nodeId: after.conflicts(typeIds),
  };
}
