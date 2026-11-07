import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../services/graph_service.dart';
import 'type_pickers.dart';

/// Edits a line's type and label.
Future<void> showLineSheet(BuildContext context, {required String edgeId}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LineSheet(edgeId: edgeId),
    );

class _LineSheet extends ConsumerStatefulWidget {
  const _LineSheet({required this.edgeId});

  final String edgeId;

  @override
  ConsumerState<_LineSheet> createState() => _LineSheetState();
}

class _LineSheetState extends ConsumerState<_LineSheet> {
  late final _snapshot = ref.read(graphSnapshotProvider).requireValue;
  late final _edge = _snapshot.edges[widget.edgeId]!;
  late String _type = _edge.typeId;
  late final _label = TextEditingController(text: _edge.label ?? '');
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = _snapshot.nodes[_edge.sourceId]?.label ?? '';
    final to = _snapshot.nodes[_edge.targetId]?.label ?? '';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$from → $to', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              EdgeTypePicker(
                types: _snapshot.edgeTypes,
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _label,
                decoration: const InputDecoration(
                  labelText: 'Line label (optional)',
                  border: OutlineInputBorder(),
                ),
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
    try {
      await ref
          .read(graphServiceProvider)
          .updateEdge(widget.edgeId, typeId: _type, label: _label.text);
      if (mounted) Navigator.pop(context);
    } on GraphRuleException catch (e) {
      setState(() => _error = e.message);
    }
  }
}
