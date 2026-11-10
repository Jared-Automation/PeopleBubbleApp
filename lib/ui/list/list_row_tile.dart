import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../domain/graph.dart';
import '../../domain/list_tree.dart';

/// Every row is this tall, so the list can scroll straight to any index.
const listRowHeight = 56.0;

/// What a row can ask the list screen to do.
class ListRowActions {
  const ListRowActions({
    required this.onToggle,
    required this.onJumpTo,
    required this.onShowParents,
    required this.onAdd,
    required this.onEdit,
    required this.onUnlink,
    required this.onDelete,
    required this.onDrop,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final void Function(ListRow row) onToggle;
  final void Function(String nodeId) onJumpTo;
  final void Function(ListRow row) onShowParents;
  final void Function(ListRow row) onAdd;
  final void Function(ListRow row) onEdit;
  final void Function(ListRow row) onUnlink;
  final void Function(ListRow row) onDelete;

  /// [dragged] was dropped onto [target].
  final void Function(ListRow dragged, ListRow target) onDrop;
  final VoidCallback onDragStart;
  final void Function(Offset globalPosition) onDragUpdate;
  final VoidCallback onDragEnd;
}

class ListRowTile extends StatelessWidget {
  const ListRowTile({
    super.key,
    required this.row,
    required this.snapshot,
    required this.actions,
    this.highlighted = false,
    this.greyed = false,
    this.hider = false,
  });

  final ListRow row;
  final GraphSnapshot snapshot;
  final ListRowActions actions;
  final bool highlighted;

  /// Under a hidden bubble (and "Show hidden" is off): drawn faint.
  final bool greyed;

  /// This bubble is marked hidden: shows an eye-off icon.
  final bool hider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = _RowContent(
      row: row,
      snapshot: snapshot,
      actions: actions,
      greyed: greyed,
      hider: hider,
    );

    if (row.isShadow) {
      return Slidable(
        key: ValueKey(row.key),
        groupTag: 'list',
        endActionPane: _pane([_unlinkAction(colors)]),
        child: _Highlight(on: highlighted, child: content),
      );
    }

    final tile = DragTarget<ListRow>(
      onWillAcceptWithDetails: (d) =>
          d.data.nodeId != row.nodeId && d.data.parentNodeId != row.nodeId,
      onAcceptWithDetails: (d) => actions.onDrop(d.data, row),
      builder: (context, candidates, _) =>
          _Highlight(on: highlighted || candidates.isNotEmpty, child: content),
    );

    return Slidable(
      key: ValueKey(row.key),
      groupTag: 'list',
      startActionPane: _pane([
        SlidableAction(
          onPressed: (_) => actions.onEdit(row),
          icon: Icons.edit,
          label: 'Edit',
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
        ),
      ]),
      endActionPane: _pane([
        if (!row.isRoot) _unlinkAction(colors),
        SlidableAction(
          onPressed: (_) => actions.onDelete(row),
          icon: Icons.delete,
          label: 'Delete',
          backgroundColor: colors.error,
          foregroundColor: colors.onError,
        ),
      ]),
      // Long-press picks the row up to drop it under a different parent.
      child: LongPressDraggable<ListRow>(
        data: row,
        onDragStarted: actions.onDragStart,
        onDragUpdate: (d) => actions.onDragUpdate(d.globalPosition),
        onDragEnd: (_) => actions.onDragEnd(),
        onDraggableCanceled: (_, _) => actions.onDragEnd(),
        feedback: _DragFeedback(
          label: greyed ? '•••' : snapshot.nodes[row.nodeId]!.label,
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: content),
        child: tile,
      ),
    );
  }

  ActionPane _pane(List<Widget> children) => ActionPane(
    motion: const DrawerMotion(),
    extentRatio: 0.25 * children.length,
    children: children,
  );

  SlidableAction _unlinkAction(ColorScheme colors) => SlidableAction(
    onPressed: (_) => actions.onUnlink(row),
    icon: Icons.link_off,
    label: 'Unlink',
    backgroundColor: colors.tertiaryContainer,
    foregroundColor: colors.onTertiaryContainer,
  );
}

class _RowContent extends StatelessWidget {
  const _RowContent({
    required this.row,
    required this.snapshot,
    required this.actions,
    required this.greyed,
    required this.hider,
  });

  final ListRow row;
  final GraphSnapshot snapshot;
  final ListRowActions actions;
  final bool greyed;
  final bool hider;

  @override
  Widget build(BuildContext context) {
    final node = snapshot.nodes[row.nodeId]!;
    final style = snapshot.styleOf(node);
    final edge = row.viaEdgeId == null ? null : snapshot.edges[row.viaEdgeId];
    final theme = Theme.of(context);

    // Under a hidden bubble: no name until revealed (Show hidden).
    final label = Text(
      greyed ? '•••' : node.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontFamily: style.fontFamily,
        fontWeight: style.bold! ? FontWeight.bold : FontWeight.normal,
        fontStyle: row.isShadow ? FontStyle.italic : null,
      ),
    );

    final body = SizedBox(
      height: listRowHeight,
      child: Row(
        children: [
          SizedBox(width: 8.0 + 16.0 * row.depth.clamp(0, 8)),
          if (row.hasChildren)
            IconButton(
              icon: Icon(
                row.expanded ? Icons.expand_more : Icons.chevron_right,
              ),
              tooltip: row.expanded ? 'Collapse' : 'Expand',
              onPressed: () => actions.onToggle(row),
            )
          else
            SizedBox(
              width: 48,
              child: row.isShadow
                  ? const Icon(Icons.swap_horiz, size: 18)
                  : null,
            ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(style.fillColor!),
              shape: BoxShape.circle,
              border: Border.all(color: Color(style.outlineColor!), width: 2),
            ),
          ),
          const SizedBox(width: 8),
          // Label and chip share whatever space the buttons leave.
          Expanded(
            child: Row(
              children: [
                Flexible(child: label),
                if (hider)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Tooltip(
                      message: 'What’s under this is hidden',
                      child: Icon(Icons.visibility_off, size: 18),
                    ),
                  ),
                if (edge != null && !greyed) ...[
                  const SizedBox(width: 8),
                  // Capped so a long line label can't squeeze the name; the
                  // name gets all the remaining room.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: _EdgeChip(edge: edge, snapshot: snapshot),
                  ),
                ],
                if (row.loopCut)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Tooltip(
                      message: 'Loop in imported data',
                      child: Icon(Icons.warning_amber, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          if (row.parentCount > 1 && !row.isShadow)
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Also under ${row.parentCount - 1} more',
              onPressed: () => actions.onShowParents(row),
            ),
          if (!row.isShadow)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: greyed ? 'Add under this' : 'Add under ${node.label}',
              onPressed: () => actions.onAdd(row),
            ),
        ],
      ),
    );

    return InkWell(
      onTap: row.isShadow
          ? () => actions.onJumpTo(row.nodeId)
          : row.hasChildren
          ? () => actions.onToggle(row)
          : null,
      child: Opacity(
        opacity: greyed
            ? 0.3
            : row.isShadow
            ? 0.55
            : 1,
        child: body,
      ),
    );
  }
}

class _EdgeChip extends StatelessWidget {
  const _EdgeChip({required this.edge, required this.snapshot});

  final GraphEdge edge;
  final GraphSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final color = Color(snapshot.edgeStyleOf(edge).color!);
    final name = snapshot.edgeTypes.byId[edge.typeId]?.name.toLowerCase() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        edge.label == null ? name : '$name · ${edge.label}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    color: on
        ? Theme.of(context).colorScheme.primaryContainer
        : Colors.transparent,
    child: child,
  );
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 6,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
