import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/style.dart';
import '../common/type_pickers.dart';
import 'style_fields.dart';

/// Hand-styles one bubble ([nodeId]) or one line ([edgeId]) on top of its
/// types. Fields left "inherited" follow the types; "Reset to type" clears
/// every override.
Future<void> showItemStyleSheet(
  BuildContext context, {
  String? nodeId,
  String? edgeId,
}) {
  assert((nodeId == null) != (edgeId == null));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ItemStyleSheet(nodeId: nodeId, edgeId: edgeId),
  );
}

class _ItemStyleSheet extends ConsumerStatefulWidget {
  const _ItemStyleSheet({this.nodeId, this.edgeId});

  final String? nodeId;
  final String? edgeId;

  @override
  ConsumerState<_ItemStyleSheet> createState() => _ItemStyleSheetState();
}

class _ItemStyleSheetState extends ConsumerState<_ItemStyleSheet> {
  Map<String, Object>? _own;
  bool _saving = false;

  bool get _isEdge => widget.edgeId != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = ref.watch(graphSnapshotProvider).value;
    final node = snapshot?.nodes[widget.nodeId];
    final edge = snapshot?.edges[widget.edgeId];
    if (snapshot == null || (node == null && edge == null)) {
      return const SizedBox(height: 120);
    }

    final String title;
    final Map<String, Object> typeStyle;
    final Widget preview;
    final List<StyleFieldSpec> fields;
    if (edge != null) {
      final own = _own ??= {...edge.overrides.setFields};
      final base = snapshot.edgeTypes.resolve([edge.typeId]);
      title =
          '${snapshot.nodes[edge.sourceId]?.label} → '
          '${snapshot.nodes[edge.targetId]?.label}';
      typeStyle = base.setFields;
      fields = edgeStyleFields(withHierarchy: false);
      preview = LinePreview(
        style: EdgeStyle.fromJson(own).mergeOver(base),
        width: 200,
      );
    } else {
      final own = _own ??= {...node!.overrides.setFields};
      final base = snapshot.nodeTypes.resolve(node!.typeIds);
      title = node.label;
      typeStyle = base.setFields;
      fields = nodeStyleFields;
      preview = BubblePreview(
        style: NodeStyle.fromJson(own).mergeOver(base),
        label: node.label,
      );
    }
    final own = _own!;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Style: $title', style: theme.textTheme.titleMedium),
            Text(
              'Changes here apply to this ${_isEdge ? 'line' : 'bubble'} '
              'only, on top of its types.',
              style: theme.textTheme.bodySmall,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: preview,
              ),
            ),
            StyleFieldsEditor(
              fields: fields,
              own: own,
              inherited: typeStyle,
              onChanged: (v) => setState(() => _own = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: own.isEmpty
                      ? null
                      : () => setState(() => _own = {}),
                  child: const Text('Reset to type'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : () => _save(own),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(Map<String, Object> own) async {
    final service = ref.read(graphServiceProvider);
    setState(() => _saving = true);
    try {
      if (_isEdge) {
        await service.setEdgeOverrides(widget.edgeId!, EdgeStyle.fromJson(own));
      } else {
        await service.setNodeOverrides(widget.nodeId!, NodeStyle.fromJson(own));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showGraphError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
