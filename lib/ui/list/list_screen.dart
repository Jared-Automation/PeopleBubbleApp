import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../data/providers.dart';
import '../../domain/graph.dart';
import '../../domain/list_tree.dart';
import '../../services/sample_data.dart';
import '../common/confirm_delete.dart';
import '../common/type_pickers.dart';
import 'add_sheet.dart';
import 'edit_sheet.dart';
import 'list_row_tile.dart';
import 'list_state.dart';
import '../common/app_menu.dart';

/// The collapsible outline of everyone and everything.
class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey();
  String? _highlightKey;
  Timer? _highlightTimer;

  // Auto-scroll while dragging a row near the top or bottom edge.
  Timer? _autoScroll;
  double? _dragY;

  @override
  void dispose() {
    _scroll.dispose();
    _highlightTimer?.cancel();
    _autoScroll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(listTreeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [if (kDebugMode) const _DebugMenu(), const AppMenuButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Both screens live in one IndexedStack: no hero, or opening a page
        // finds two buttons with the same default hero tag.
        heroTag: null,
        onPressed: () => showAddSheet(context, parentId: null),
        icon: const Icon(Icons.person_add),
        label: const Text('Add person'),
      ),
      body: switch (tree) {
        AsyncData(value: (final snapshot, final tree)) =>
          tree.rows.isEmpty
              ? _EmptyState(onAdd: () => showAddSheet(context, parentId: null))
              : _buildList(snapshot, tree),
        AsyncError(:final error) => Center(
          child: Text('Database error: $error'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildList(GraphSnapshot snapshot, ListTree tree) {
    final actions = ListRowActions(
      onToggle: (row) => ref.read(expansionProvider.notifier).toggle(row.key),
      onJumpTo: _jumpTo,
      onShowParents: (row) => _showParents(snapshot, row),
      onAdd: (row) => showAddSheet(context, parentId: row.nodeId),
      onEdit: (row) =>
          showEditSheet(context, nodeId: row.nodeId, edgeId: row.viaEdgeId),
      onUnlink: (row) =>
          _run(() => ref.read(graphServiceProvider).deleteEdge(row.viaEdgeId!)),
      onDelete: (row) => confirmAndDeleteNode(context, ref, row.nodeId),
      onDrop: _drop,
      onDragStart: _startAutoScroll,
      onDragUpdate: (pos) => _dragY = pos.dy,
      onDragEnd: _stopAutoScroll,
    );
    // SlidableAutoCloseBehavior keeps only one row's actions open at a time.
    return SlidableAutoCloseBehavior(
      child: ListView.builder(
        key: _listKey,
        controller: _scroll,
        itemExtent: listRowHeight,
        // Room so the floating button never covers the last row.
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: tree.rows.length,
        itemBuilder: (context, i) => ListRowTile(
          key: ValueKey(tree.rows[i].key),
          row: tree.rows[i],
          snapshot: snapshot,
          actions: actions,
          highlighted: tree.rows[i].key == _highlightKey,
        ),
      ),
    );
  }

  /// Expands the way to [nodeId]'s first appearance, scrolls to it and
  /// flashes it.
  void _jumpTo(String nodeId) {
    final current = ref.read(listTreeProvider).value?.$2;
    final home = current?.homeKeys[nodeId];
    if (home == null) return;
    ref.read(expansionProvider.notifier).reveal(home);
    final tree = ref.read(listTreeProvider).value!.$2;
    final index = tree.indexOfKey(home);
    setState(() => _highlightKey = home);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _highlightKey = null);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients || index < 0) return;
      final viewport = _scroll.position.viewportDimension;
      final target = (index * listRowHeight - viewport / 3).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showParents(GraphSnapshot snapshot, ListRow row) {
    final parents = [
      for (final e in snapshot.hierarchicalEdges)
        if (e.targetId == row.nodeId) e,
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${snapshot.nodes[row.nodeId]!.label} is under',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final e in parents)
              ListTile(
                leading: Icon(
                  e.sourceId == row.parentNodeId
                      ? Icons.subdirectory_arrow_right
                      : Icons.north_west,
                ),
                title: Text(snapshot.nodes[e.sourceId]!.label),
                subtitle: Text(
                  snapshot.edgeTypes.byId[e.typeId]?.name.toLowerCase() ?? '',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _jumpTo(e.sourceId);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// A row dropped onto another: move its line under the target, or give a
  /// root row a parent using the last line type.
  void _drop(ListRow dragged, ListRow target) {
    final service = ref.read(graphServiceProvider);
    final edgeId = dragged.viaEdgeId;
    _run(
      () => edgeId != null
          ? service.moveEdge(edgeId, target.nodeId)
          : service.createEdge(
              sourceId: target.nodeId,
              targetId: dragged.nodeId,
              typeId: ref.read(lastEdgeTypeProvider),
            ),
    );
  }

  Future<void> _run(Future<Object?> Function() write) async {
    try {
      await write();
    } catch (e) {
      if (mounted) showGraphError(context, e);
    }
  }

  void _startAutoScroll() {
    _autoScroll?.cancel();
    _autoScroll = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
      final y = _dragY;
      if (box == null || y == null || !_scroll.hasClients) return;
      final local = box.globalToLocal(Offset(0, y)).dy;
      const edge = 72.0, maxSpeed = 14.0;
      double delta = 0;
      if (local < edge) delta = -maxSpeed * (1 - local / edge);
      if (local > box.size.height - edge) {
        delta = maxSpeed * (1 - (box.size.height - local) / edge);
      }
      if (delta == 0) return;
      final position = _scroll.position;
      _scroll.jumpTo(
        (position.pixels + delta).clamp(0.0, position.maxScrollExtent),
      );
    });
  }

  void _stopAutoScroll() {
    _autoScroll?.cancel();
    _autoScroll = null;
    _dragY = null;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No one here yet.', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add),
            label: const Text('Add your first person'),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            const Text(
              'Debug: ⋮ → Load sample data',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
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
    } catch (e) {
      if (context.mounted) showGraphError(context, e);
    }
  }
}
