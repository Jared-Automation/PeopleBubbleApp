import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/seed.dart';
import '../../domain/graph.dart';
import '../../services/graph_service.dart';
import '../common/type_pickers.dart';
import 'list_state.dart';

/// Opens the add sheet: under [parentId], or a new top-level person if null.
/// [existingTab] opens on "Existing". A top-level bubble goes at [position]
/// (world coordinates) if given, otherwise it's auto-placed.
Future<void> showAddSheet(
  BuildContext context, {
  required String? parentId,
  bool existingTab = false,
  Point<double>? position,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => AddSheet(
    parentId: parentId,
    existingTab: existingTab,
    position: position,
  ),
);

/// Two tabs: **New** makes a bubble (and its line), **Existing** links one
/// that's already there. The sheet stays open after each add for quick runs.
class AddSheet extends ConsumerStatefulWidget {
  const AddSheet({
    super.key,
    required this.parentId,
    this.existingTab = false,
    this.position,
  });

  final String? parentId;
  final bool existingTab;
  final Point<double>? position;

  @override
  ConsumerState<AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<AddSheet> {
  final _label = TextEditingController();
  final _labelFocus = FocusNode();
  final _search = TextEditingController();
  late List<String> _types = [
    widget.parentId == null ? SeedIds.person : SeedIds.thing,
  ];
  late String _edgeType = ref.read(lastEdgeTypeProvider);

  /// Feedback under the buttons: what was just added, or why it wasn't.
  String? _message;
  bool _messageIsError = false;

  bool get _hasParent => widget.parentId != null;

  /// Top-level bubbles added at a spot so far, so a quick run stacks them
  /// downward instead of on top of each other.
  int _addedAtPosition = 0;

  @override
  void dispose() {
    _label.dispose();
    _labelFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(graphSnapshotProvider).value;
    if (snapshot == null) return const SizedBox(height: 200);
    final parentLabel = _hasParent
        ? snapshot.nodes[widget.parentId]?.label
        : null;
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        parentLabel == null ? 'Add person' : 'Add under $parentLabel',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );

    // Keep the sheet above the keyboard and below the status bar; the
    // content scrolls inside whatever height is left.
    final media = MediaQuery.of(context);
    final maxHeight =
        media.size.height - media.viewInsets.bottom - media.padding.top - 64;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: !_hasParent
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    Flexible(
                      child: SingleChildScrollView(child: _newTab(snapshot)),
                    ),
                  ],
                )
              : DefaultTabController(
                  length: 2,
                  initialIndex: widget.existingTab ? 1 : 0,
                  child: SizedBox(
                    height: maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        const TabBar(
                          tabs: [
                            Tab(text: 'New'),
                            Tab(text: 'Existing'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              SingleChildScrollView(child: _newTab(snapshot)),
                              _existingTab(snapshot),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _newTab(GraphSnapshot snapshot) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _label,
          focusNode: _labelFocus,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _addNew(),
        ),
        const SizedBox(height: 16),
        _sectionLabel('Type'),
        NodeTypePicker(
          types: snapshot.nodeTypes,
          selected: _types,
          onChanged: (t) => setState(() => _types = t),
        ),
        if (_hasParent) ...[
          const SizedBox(height: 16),
          _sectionLabel('Line'),
          _edgePicker(snapshot),
        ],
        const SizedBox(height: 16),
        _buttons(onAdd: _addNew),
      ],
    ),
  );

  Widget _existingTab(GraphSnapshot snapshot) {
    final parentId = widget.parentId!;
    final query = _search.text.trim().toLowerCase();
    final alreadyLinked = {
      for (final e in snapshot.edges.values)
        if (e.sourceId == parentId) e.targetId,
    };
    final hierarchical =
        snapshot.edgeTypes.resolve([_edgeType]).hierarchical ?? true;
    final pairs = [
      for (final e in snapshot.hierarchicalEdges) (e.sourceId, e.targetId),
    ];
    final candidates =
        snapshot.nodes.values
            .where(
              (n) =>
                  n.id != parentId &&
                  !alreadyLinked.contains(n.id) &&
                  n.label.toLowerCase().contains(query),
            )
            .toList()
          ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search bubbles',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _edgePicker(snapshot),
          if (_message != null) _messageText(),
          Expanded(
            child: ListView(
              children: [
                for (final node in candidates.take(100))
                  Builder(
                    builder: (context) {
                      final loops =
                          hierarchical &&
                          edgeWouldCreateCycle(
                            parentId: parentId,
                            childId: node.id,
                            edges: pairs,
                          );
                      return ListTile(
                        title: Text(node.label),
                        subtitle: loops
                            ? const Text('Would make a loop')
                            : null,
                        enabled: !loops,
                        trailing: const Icon(Icons.add_link),
                        onTap: () => _linkExisting(node),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _edgePicker(GraphSnapshot snapshot) => EdgeTypePicker(
    types: snapshot.edgeTypes,
    selected: _edgeType,
    onChanged: (t) => setState(() => _edgeType = t),
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );

  Widget _buttons({required VoidCallback onAdd}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onAdd, child: const Text('Add')),
        ],
      ),
      if (_message != null) _messageText(),
    ],
  );

  Widget _messageText() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      _message!,
      style: TextStyle(
        color: _messageIsError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Future<void> _addNew() async {
    final service = ref.read(graphServiceProvider);
    final label = _label.text.trim();
    await _attempt(() async {
      if (_hasParent) {
        await service.createChildNode(
          parentId: widget.parentId!,
          label: label,
          typeIds: _types,
          edgeTypeId: _edgeType,
        );
        ref.read(lastEdgeTypeProvider.notifier).set(_edgeType);
      } else {
        final at = widget.position;
        await service.createNode(
          label: label,
          typeIds: _types,
          x: at?.x,
          y: at == null ? null : at.y + 80.0 * _addedAtPosition,
        );
        if (at != null) _addedAtPosition++;
      }
      _label.clear();
      return 'Added “$label”';
    });
    _labelFocus.requestFocus();
  }

  Future<void> _linkExisting(GraphNode node) => _attempt(() async {
    await ref
        .read(graphServiceProvider)
        .createEdge(
          sourceId: widget.parentId!,
          targetId: node.id,
          typeId: _edgeType,
        );
    ref.read(lastEdgeTypeProvider.notifier).set(_edgeType);
    return 'Linked “${node.label}”';
  });

  /// Runs a write and shows its outcome inside the sheet (a snackbar would be
  /// hidden behind it).
  Future<void> _attempt(Future<String> Function() write) async {
    String message;
    var isError = false;
    try {
      message = await write();
    } on GraphRuleException catch (e) {
      message = e.message;
      isError = true;
    }
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }
}
