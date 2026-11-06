import 'package:flutter/material.dart';

import '../../domain/style.dart';
import '../../domain/types.dart';
import '../../services/graph_service.dart';

/// Types in tree order (parents before children, A–Z among siblings),
/// without the built-in base type.
List<TypeDef<S>> typesInTreeOrder<S extends Style<S>>(TypeHierarchy<S> h) {
  final byParent = <String?, List<TypeDef<S>>>{};
  for (final t in h.byId.values) {
    (byParent[t.parentId] ??= []).add(t);
  }
  for (final list in byParent.values) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
  final result = <TypeDef<S>>[];
  final seen = <String>{};
  void walk(String? parentId) {
    for (final t in byParent[parentId] ?? <TypeDef<S>>[]) {
      if (!seen.add(t.id)) continue;
      if (!t.isBase) result.add(t);
      walk(t.id);
    }
  }

  walk(null);
  return result;
}

/// Multi-select bubble types. Picking a type replaces its own ancestors or
/// subtypes (Person → Partner). Types that would conflict are greyed out with
/// the reason listed underneath.
class NodeTypePicker extends StatelessWidget {
  const NodeTypePicker({
    super.key,
    required this.types,
    required this.selected,
    required this.onChanged,
  });

  final TypeHierarchy<NodeStyle> types;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// [selected] minus anything [typeId] would replace.
  List<String> _without(String typeId) => [
    for (final s in selected)
      if (s != typeId &&
          !types.isAncestor(s, typeId) &&
          !types.isAncestor(typeId, s))
        s,
  ];

  @override
  Widget build(BuildContext context) {
    // Greyed-out types grouped by what they clash with, so one selected type
    // blocking five others reads as one line, not five.
    final blockedBy = <String, List<String>>{};
    final chips = <Widget>[];
    for (final type in typesInTreeOrder(types)) {
      final isSelected = selected.contains(type.id);
      final conflicts = isSelected
          ? const <TypeConflict>[]
          : types.conflictsIfAdded(type.id, _without(type.id));
      if (conflicts.isNotEmpty) {
        final c = conflicts.first;
        final other = types.byId[c.typeA == type.id ? c.typeB : c.typeA]!.name;
        final fields = c.fields.map((f) => styleFieldLabels[f] ?? f).join(', ');
        (blockedBy['$other (both set $fields)'] ??= []).add(type.name);
      }
      final outline = types.resolve([type.id]).outlineColor!;
      chips.add(
        FilterChip(
          label: Text(type.name),
          avatar: CircleAvatar(backgroundColor: Color(outline), radius: 6),
          selected: isSelected,
          onSelected: conflicts.isNotEmpty
              ? null
              : (on) => onChanged(
                  on ? [..._without(type.id), type.id] : _without(type.id),
                ),
        ),
      );
    }
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 4, children: chips),
        for (final MapEntry(key: clash, value: names) in blockedBy.entries)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "${names.join(', ')} can't be combined with $clash.",
              style: muted,
            ),
          ),
      ],
    );
  }
}

/// Single-select line type.
class EdgeTypePicker extends StatelessWidget {
  const EdgeTypePicker({
    super.key,
    required this.types,
    required this.selected,
    required this.onChanged,
  });

  final TypeHierarchy<EdgeStyle> types;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final type in typesInTreeOrder(types))
          ChoiceChip(
            label: Text(type.name),
            avatar: CircleAvatar(
              backgroundColor: Color(types.resolve([type.id]).color!),
              radius: 6,
            ),
            selected: type.id == selected,
            onSelected: (_) => onChanged(type.id),
          ),
      ],
    );
  }
}

/// Shows a refused write's message, or rethrows anything unexpected.
void showGraphError(BuildContext context, Object error) {
  if (error is! GraphRuleException) throw error;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(error.message)));
}
