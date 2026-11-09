import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/graph.dart';
import '../../domain/style.dart';
import '../../domain/types.dart';
import 'style_fields.dart';
import 'type_editor_screen.dart';

/// Every bubble and line type as an indented tree, with a preview and how
/// many items use each. Tap a type to edit it; + adds a subtype under it.
class TypesScreen extends ConsumerWidget {
  const TypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(graphSnapshotProvider).value;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Types'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bubble types'),
              Tab(text: 'Line types'),
            ],
          ),
        ),
        body: snapshot == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _TypeTree(snapshot: snapshot, isEdge: false),
                  _TypeTree(snapshot: snapshot, isEdge: true),
                ],
              ),
      ),
    );
  }
}

/// Types of one kind, base first, then parents before children, A–Z.
List<(TypeDef<S>, int)> typeTreeRows<S extends Style<S>>(TypeHierarchy<S> h) {
  final byParent = <String?, List<TypeDef<S>>>{};
  for (final t in h.byId.values) {
    (byParent[t.parentId] ??= []).add(t);
  }
  for (final list in byParent.values) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
  final rows = <(TypeDef<S>, int)>[];
  final seen = <String>{};
  void walk(String? parentId, int depth) {
    for (final t in byParent[parentId] ?? <TypeDef<S>>[]) {
      if (!seen.add(t.id)) continue;
      rows.add((t, depth));
      walk(t.id, depth + 1);
    }
  }

  walk(null, 0);
  return rows;
}

class _TypeTree extends StatelessWidget {
  const _TypeTree({required this.snapshot, required this.isEdge});

  final GraphSnapshot snapshot;
  final bool isEdge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = isEdge
        ? typeTreeRows(snapshot.edgeTypes)
        : typeTreeRows(snapshot.nodeTypes);
    final usage = <String, int>{};
    if (isEdge) {
      for (final e in snapshot.edges.values) {
        usage[e.typeId] = (usage[e.typeId] ?? 0) + 1;
      }
    } else {
      for (final n in snapshot.nodes.values) {
        for (final t in n.typeIds) {
          usage[t] = (usage[t] ?? 0) + 1;
        }
      }
    }
    final noun = isEdge ? 'line' : 'bubble';

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final (type, depth) in rows)
          ListTile(
            contentPadding: EdgeInsets.only(left: 16.0 + 24 * depth, right: 4),
            leading: SizedBox(
              width: 72,
              child: Center(
                child: isEdge
                    ? LinePreview(style: snapshot.edgeTypes.resolve([type.id]))
                    : FittedBox(
                        child: BubblePreview(
                          style: snapshot.nodeTypes.resolve([type.id]),
                          label: type.name,
                        ),
                      ),
              ),
            ),
            title: Text(type.name),
            subtitle: Text(
              [
                if (type.isBase) 'base type',
                switch (usage[type.id] ?? 0) {
                  0 => 'unused',
                  1 => '1 $noun',
                  final n => '$n ${noun}s',
                },
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    TypeEditorScreen(isEdge: isEdge, typeId: type.id),
              ),
            ),
            trailing: IconButton(
              tooltip: 'New subtype of ${type.name}',
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      TypeEditorScreen(isEdge: isEdge, parentId: type.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
