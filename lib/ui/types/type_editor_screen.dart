import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/graph.dart';
import '../../domain/style.dart';
import '../../domain/types.dart';
import '../common/type_pickers.dart';
import 'style_fields.dart';
import 'types_screen.dart';

/// Creates or edits one bubble or line type: name, parent, and the style
/// fields it sets. The preview and the conflict check update as you edit;
/// Save is disabled while the edit would give bubbles conflicting types.
///
/// Pass [typeId] to edit, or [parentId] to create a subtype.
class TypeEditorScreen extends ConsumerStatefulWidget {
  const TypeEditorScreen({
    super.key,
    required this.isEdge,
    this.typeId,
    this.parentId,
  }) : assert(typeId != null || parentId != null);

  final bool isEdge;
  final String? typeId;
  final String? parentId;

  @override
  ConsumerState<TypeEditorScreen> createState() => _TypeEditorScreenState();
}

class _TypeEditorScreenState extends ConsumerState<TypeEditorScreen> {
  final _name = TextEditingController();
  String? _parentId;
  Map<String, Object> _own = {};
  bool _loaded = false;
  bool _saving = false;

  bool get _isNew => widget.typeId == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Fills the form from the saved type, once.
  void _load(GraphSnapshot s) {
    if (_loaded) return;
    _loaded = true;
    if (_isNew) {
      _parentId = widget.parentId;
      return;
    }
    widget.isEdge ? _fill(s.edgeTypes) : _fill(s.nodeTypes);
  }

  void _fill<S extends Style<S>>(TypeHierarchy<S> types) {
    final type = types.byId[widget.typeId];
    if (type == null) return;
    _name.text = type.name;
    _parentId = type.parentId;
    _own = {...type.style.setFields};
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(graphSnapshotProvider).value;
    if (snapshot == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _load(snapshot);
    return widget.isEdge
        ? _buildFor(snapshot, snapshot.edgeTypes, _edgeKind)
        : _buildFor(snapshot, snapshot.nodeTypes, _nodeKind);
  }

  static final _nodeKind = _Kind<NodeStyle>(
    noun: 'bubble',
    fields: nodeStyleFields,
    fromJson: NodeStyle.fromJson,
  );
  static final _edgeKind = _Kind<EdgeStyle>(
    noun: 'line',
    fields: edgeStyleFields(withHierarchy: true),
    fromJson: EdgeStyle.fromJson,
  );

  Widget _buildFor<S extends Style<S>>(
    GraphSnapshot snapshot,
    TypeHierarchy<S> types,
    _Kind<S> kind,
  ) {
    final theme = Theme.of(context);
    final existing = _isNew ? null : types.byId[widget.typeId];
    if (!_isNew && existing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('That type no longer exists.')),
      );
    }
    final isBase = existing?.isBase ?? false;
    final parentId = _parentId;

    final inherited = parentId == null
        ? types.appDefaults
        : types.resolve([parentId]);
    final own = kind.fromJson(_own);
    final preview = own.mergeOver(inherited);

    // Bubbles that would end up with conflicting types after this edit.
    final broken = existing == null || widget.isEdge
        ? const <String>[]
        : ([
            for (final id in nodesBrokenByTypeEdit(
              types,
              existing.copyWith(parentId: parentId, style: own),
              {for (final n in snapshot.nodes.values) n.id: n.typeIds},
            ).keys)
              snapshot.nodes[id]!.label,
          ]..sort());

    final parentChoices = [
      for (final (t, depth) in typeTreeRows(types))
        if (t.id != widget.typeId &&
            !(widget.typeId != null && types.isAncestor(widget.typeId!, t.id)))
          (t, depth),
    ];
    final nameValid = _name.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New ${kind.noun} type' : 'Edit type'),
        actions: [
          if (existing != null && !existing.builtIn)
            IconButton(
              tooltip: 'Delete type',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(snapshot, types, existing, kind),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: widget.isEdge
                  ? LinePreview(style: preview as EdgeStyle, width: 200)
                  : BubblePreview(
                      style: preview as NodeStyle,
                      label: nameValid ? _name.text.trim() : 'Preview',
                    ),
            ),
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          if (!isBase) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: parentId,
              decoration: const InputDecoration(labelText: 'Parent type'),
              items: [
                for (final (t, depth) in parentChoices)
                  DropdownMenuItem(
                    value: t.id,
                    child: Text('${'   ' * depth}${t.name}'),
                  ),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Style',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            'Fields left as "inherited" come from '
            '${parentId == null ? 'the app defaults' : 'the parent type'}.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          StyleFieldsEditor(
            fields: kind.fields,
            own: _own,
            inherited: inherited.setFields,
            onChanged: (v) => setState(() => _own = v),
          ),
          if (broken.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Can't save: this would give ${broken.length} "
              '${broken.length == 1 ? 'bubble' : 'bubbles'} conflicting types: '
              '${broken.join(', ')}.',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: !nameValid || broken.isNotEmpty || _saving
                ? null
                : () => _save(own),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(Object style) async {
    final service = ref.read(graphServiceProvider);
    final name = _name.text;
    setState(() => _saving = true);
    try {
      if (widget.isEdge) {
        final s = style as EdgeStyle;
        if (_isNew) {
          await service.createEdgeType(
            name: name,
            parentId: _parentId!,
            style: s,
          );
        } else {
          await service.updateEdgeType(
            widget.typeId!,
            name: name,
            parentId: _parentId,
            style: s,
          );
        }
      } else {
        final s = style as NodeStyle;
        if (_isNew) {
          await service.createNodeType(
            name: name,
            parentId: _parentId!,
            style: s,
          );
        } else {
          await service.updateNodeType(
            widget.typeId!,
            name: name,
            parentId: _parentId,
            style: s,
          );
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showGraphError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete<S extends Style<S>>(
    GraphSnapshot s,
    TypeHierarchy<S> types,
    TypeDef<S> type,
    _Kind<S> kind,
  ) async {
    final parentName = types.byId[type.parentId]?.name ?? 'its parent';
    final used = widget.isEdge
        ? s.edges.values.where((e) => e.typeId == type.id).length
        : s.nodes.values.where((n) => n.typeIds.contains(type.id)).length;
    final subtypes = types.byId.values.where((t) => t.parentId == type.id);
    final effects = [
      if (used > 0)
        widget.isEdge
            ? '$used ${used == 1 ? 'line' : 'lines'} will become $parentName.'
            : '$used ${used == 1 ? 'bubble loses' : 'bubbles lose'} this type.',
      if (subtypes.isNotEmpty)
        '${subtypes.length} ${subtypes.length == 1 ? 'subtype moves' : 'subtypes move'} '
            'under $parentName.',
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete “${type.name}”?'),
        content: Text(
          effects.isEmpty ? 'Nothing uses this type.' : effects.join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final service = ref.read(graphServiceProvider);
    try {
      if (widget.isEdge) {
        await service.deleteEdgeType(type.id);
      } else {
        await service.deleteNodeType(type.id);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showGraphError(context, e);
    }
  }
}

/// What differs between editing bubble types and line types.
class _Kind<S extends Style<S>> {
  const _Kind({
    required this.noun,
    required this.fields,
    required this.fromJson,
  });

  final String noun;
  final List<StyleFieldSpec> fields;
  final S Function(Map<String, Object?>) fromJson;
}
