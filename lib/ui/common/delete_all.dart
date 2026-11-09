import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'type_pickers.dart';
import 'undo_ui.dart';

/// Asks first, saying exactly what goes, then deletes every bubble, line,
/// waypoint and custom type. Built-in types stay. One undo step.
Future<void> confirmAndDeleteAll(BuildContext context, WidgetRef ref) async {
  final snapshot = ref.read(graphSnapshotProvider).value;
  if (snapshot == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final bubbles = snapshot.nodes.length;
  final lines = snapshot.edges.length;
  final customTypes = [
    ...snapshot.nodeTypes.byId.values,
    ...snapshot.edgeTypes.byId.values,
  ].where((t) => !t.builtIn && !t.isBase).length;
  if (bubbles == 0 && customTypes == 0) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Nothing to delete.')));
    return;
  }

  String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  final what = [
    if (bubbles > 0) count(bubbles, 'bubble', 'bubbles'),
    if (lines > 0) count(lines, 'line', 'lines'),
    if (customTypes > 0) count(customTypes, 'custom type', 'custom types'),
  ];
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final error = Theme.of(context).colorScheme.error;
      return AlertDialog(
        icon: Icon(Icons.delete_forever, color: error),
        title: const Text('Delete everything?'),
        content: Text(
          'This deletes all ${_joined(what)}. The built-in types stay.\n\n'
          'You can undo it until you close the app. To keep a copy, '
          'cancel and use Export backup first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      );
    },
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(graphServiceProvider).clearAllData();
    if (context.mounted) showUndoSnackBar(context, ref, 'Deleted everything');
  } catch (e) {
    if (context.mounted) showGraphError(context, e);
  }
}

/// "a, b and c".
String _joined(List<String> parts) => parts.length < 2
    ? parts.join()
    : '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
