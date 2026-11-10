import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/subtree_copy.dart';
import '../list/list_state.dart';
import 'type_pickers.dart';
import 'undo_ui.dart';

/// What "Copy" holds: a bubble and everything under it. Lives until the app
/// closes (or the next Copy).
class SubtreeClipboard extends Notifier<SubtreeCopy?> {
  @override
  SubtreeCopy? build() => null;

  void set(SubtreeCopy copy) => state = copy;
}

final subtreeClipboardProvider =
    NotifierProvider<SubtreeClipboard, SubtreeCopy?>(SubtreeClipboard.new);

/// Copies [nodeId] and everything under it, and puts the names on the
/// system clipboard as an outline too.
Future<void> copyBubble(
  BuildContext context,
  WidgetRef ref,
  String nodeId,
) async {
  final snapshot = ref.read(graphSnapshotProvider).value;
  if (snapshot == null || !snapshot.nodes.containsKey(nodeId)) return;
  final messenger = ScaffoldMessenger.of(context);
  final copy = copySubtree(snapshot, nodeId);
  ref.read(subtreeClipboardProvider.notifier).set(copy);
  await Clipboard.setData(ClipboardData(text: copy.outline));
  final below = copy.belowCount;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'Copied “${copy.root.label}”'
          '${below == 0 ? '' : ' and $below under it'}',
        ),
      ),
    );
}

/// Pastes the copy under [parentId], linked by the last-used line type.
Future<void> pasteUnder(
  BuildContext context,
  WidgetRef ref,
  String parentId,
) async {
  final copy = ref.read(subtreeClipboardProvider);
  final parent = ref.read(graphSnapshotProvider).value?.nodes[parentId];
  if (copy == null || parent == null) return;
  try {
    await ref
        .read(graphServiceProvider)
        .pasteSubtree(
          copy,
          parentId: parentId,
          edgeTypeId: ref.read(lastEdgeTypeProvider),
        );
    if (context.mounted) {
      showUndoSnackBar(
        context,
        ref,
        'Pasted “${copy.root.label}” under “${parent.label}”',
      );
    }
  } catch (e) {
    if (context.mounted) showGraphError(context, e);
  }
}

/// The copy, if the system clipboard still holds what Copy put there (so
/// text copied from elsewhere since wins).
Future<SubtreeCopy?> copyStillOnClipboard(WidgetRef ref) async {
  final copy = ref.read(subtreeClipboardProvider);
  if (copy == null) return null;
  final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
  return text == copy.outline ? copy : null;
}

/// Pastes [copy] as a new top-level group with its root at [at].
Future<void> pasteAt(
  BuildContext context,
  WidgetRef ref,
  SubtreeCopy copy,
  Point<double> at,
) async {
  try {
    await ref.read(graphServiceProvider).pasteSubtree(copy, at: at);
    if (context.mounted) {
      showUndoSnackBar(context, ref, 'Pasted “${copy.root.label}”');
    }
  } catch (e) {
    if (context.mounted) showGraphError(context, e);
  }
}
