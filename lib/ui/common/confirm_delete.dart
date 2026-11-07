import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'type_pickers.dart';

/// Asks before deleting a bubble everywhere, saying how many lines go with
/// it, then deletes. Shared by the list and the canvas so they can't drift.
Future<void> confirmAndDeleteNode(
  BuildContext context,
  WidgetRef ref,
  String nodeId,
) async {
  final snapshot = ref.read(graphSnapshotProvider).value;
  final node = snapshot?.nodes[nodeId];
  if (snapshot == null || node == null) return;
  final lines = snapshot.edges.values
      .where((e) => e.sourceId == nodeId || e.targetId == nodeId)
      .length;
  final linesText = lines == 0
      ? ''
      : ', along with its $lines ${lines == 1 ? 'line' : 'lines'}';
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete “${node.label}”?'),
      content: Text(
        'This removes it everywhere it appears$linesText. '
        'Bubbles under it stay; any left without a parent move to the top.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (!(ok ?? false)) return;
  try {
    await ref.read(graphServiceProvider).deleteNode(nodeId);
  } catch (e) {
    if (context.mounted) showGraphError(context, e);
  }
}
