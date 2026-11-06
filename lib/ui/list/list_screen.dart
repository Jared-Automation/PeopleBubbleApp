import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/graph.dart';
import '../../services/graph_service.dart';
import '../../services/sample_data.dart';

/// Phase 2 stand-in for the list view: a flat list of every node with its
/// resolved style, so the data layer can be checked on the phone.
/// Phase 3 replaces it with the real collapsible tree.
class ListScreen extends ConsumerWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(graphSnapshotProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [if (kDebugMode) const _DebugMenu()],
      ),
      body: switch (snapshot) {
        AsyncData(:final value) => _NodeList(snapshot: value),
        AsyncError(:final error) => Center(
          child: Text('Database error: $error'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _NodeList extends StatelessWidget {
  const _NodeList({required this.snapshot});

  final GraphSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final nodes = snapshot.nodes.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    final summary =
        '${snapshot.nodes.length} bubbles · ${snapshot.edges.length} lines · '
        '${snapshot.nodeTypes.byId.length} bubble types · '
        '${snapshot.edgeTypes.byId.length} line types';

    if (nodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No bubbles yet.\n\n$summary'
            '${kDebugMode ? '\n\nUse ⋮ → Load sample data.' : ''}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: nodes.length + 1,
      itemBuilder: (context, i) => i == 0
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                summary,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          : _NodeTile(snapshot: snapshot, node: nodes[i - 1]),
    );
  }
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({required this.snapshot, required this.node});

  final GraphSnapshot snapshot;
  final GraphNode node;

  @override
  Widget build(BuildContext context) {
    final style = snapshot.styleOf(node);
    final typeNames = node.typeIds.isEmpty
        ? 'Node'
        : node.typeIds
              .map((t) => snapshot.nodeTypes.byId[t]?.name ?? t)
              .join(', ');
    final outgoing = [
      for (final e in snapshot.edges.values.where((e) => e.sourceId == node.id))
        '${snapshot.edgeTypes.byId[e.typeId]?.name.toLowerCase()} '
            '${snapshot.nodes[e.targetId]?.label}'
            '${e.label == null ? '' : ' (${e.label})'}',
    ];
    return ListTile(
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Color(style.fillColor!),
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(style.outlineColor!),
            width: style.outlineWidth!,
          ),
        ),
      ),
      title: Text(
        node.label,
        style: TextStyle(
          fontWeight: style.bold! ? FontWeight.bold : FontWeight.normal,
          fontFamily: style.fontFamily,
        ),
      ),
      subtitle: Text(
        [typeNames, ...outgoing].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Debug-only tools: never shown in release builds.
class _DebugMenu extends ConsumerWidget {
  const _DebugMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(graphServiceProvider);
    return PopupMenuButton<Future<void> Function()>(
      tooltip: 'Debug tools',
      onSelected: (action) => _run(context, action),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: () => loadSampleData(service),
          child: const Text('Load sample data'),
        ),
        PopupMenuItem(
          value: () => loadLargeSample(service),
          child: const Text('Load 300 bubbles'),
        ),
        PopupMenuItem(
          value: service.clearAllData,
          child: const Text('Clear all data'),
        ),
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final watch = Stopwatch()..start();
    try {
      await action();
      messenger.showSnackBar(
        SnackBar(content: Text('Done in ${watch.elapsedMilliseconds} ms')),
      );
    } on GraphRuleException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
