import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../services/graph_service.dart';
import '../common/type_pickers.dart';
import '../types/item_style_sheet.dart';

/// Opens the edit sheet for a bubble and, if given, the line above it.
Future<void> showEditSheet(
  BuildContext context, {
  required String nodeId,
  String? edgeId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => EditSheet(nodeId: nodeId, edgeId: edgeId),
);

class EditSheet extends ConsumerStatefulWidget {
  const EditSheet({super.key, required this.nodeId, this.edgeId});

  final String nodeId;
  final String? edgeId;

  @override
  ConsumerState<EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<EditSheet> {
  late final _snapshot = ref.read(graphSnapshotProvider).requireValue;
  late final _node = _snapshot.nodes[widget.nodeId]!;
  late final _edge = widget.edgeId == null
      ? null
      : _snapshot.edges[widget.edgeId];

  late final _label = TextEditingController(text: _node.label);
  late final _edgeLabel = TextEditingController(text: _edge?.label ?? '');
  late List<String> _types = _node.typeIds;
  late String? _edgeType = _edge?.typeId;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _edgeLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget section(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: theme.textTheme.labelLarge),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit ${_node.label}', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _label,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              section('Type'),
              NodeTypePicker(
                types: _snapshot.nodeTypes,
                selected: _types,
                onChanged: (t) => setState(() => _types = t),
              ),
              if (_edge != null) ...[
                section(
                  'Line from ${_snapshot.nodes[_edge.sourceId]?.label ?? ''}',
                ),
                EdgeTypePicker(
                  types: _snapshot.edgeTypes,
                  selected: _edgeType!,
                  onChanged: (t) => setState(() => _edgeType = t),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _edgeLabel,
                  decoration: const InputDecoration(
                    labelText: 'Line label (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Bubble style…'),
                    onPressed: () =>
                        showItemStyleSheet(context, nodeId: _node.id),
                  ),
                  if (_edge != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text('Line style…'),
                      onPressed: () =>
                          showItemStyleSheet(context, edgeId: _edge.id),
                    ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final service = ref.read(graphServiceProvider);
    try {
      // The line first: it's the change most likely to be refused (a loop),
      // and refusing it before touching the bubble keeps the edit all-or-
      // nothing in practice.
      if (_edge != null) {
        await service.updateEdge(
          _edge.id,
          typeId: _edgeType!,
          label: _edgeLabel.text,
        );
      }
      await service.updateNode(
        widget.nodeId,
        label: _label.text,
        typeIds: _types,
      );
      if (mounted) Navigator.pop(context);
    } on GraphRuleException catch (e) {
      setState(() => _error = e.message);
    }
  }
}
