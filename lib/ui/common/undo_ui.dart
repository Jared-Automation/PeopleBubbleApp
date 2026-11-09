import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../services/graph_service.dart';

/// Undo and redo buttons for an app bar. Their tooltips name the step
/// ("Undo: move “Sam”"); they grey out when there's nothing to do.
class UndoRedoButtons extends ConsumerWidget {
  const UndoRedoButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(graphServiceProvider);
    // ValueListenableBuilder rebuilds just these buttons when the history
    // changes, like a binding to one property.
    return ValueListenableBuilder<UndoState>(
      valueListenable: service.history.state,
      builder: (context, state, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: state.canUndo ? 'Undo: ${state.undoLabel}' : 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: state.canUndo
                ? () => replayStep(ScaffoldMessenger.of(context), service)
                : null,
          ),
          IconButton(
            tooltip: state.canRedo ? 'Redo: ${state.redoLabel}' : 'Redo',
            icon: const Icon(Icons.redo),
            onPressed: state.canRedo
                ? () => replayStep(
                    ScaffoldMessenger.of(context),
                    service,
                    redo: true,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Undoes (or redoes) one step and says which, or why it couldn't.
Future<void> replayStep(
  ScaffoldMessengerState messenger,
  GraphService service, {
  bool redo = false,
}) async {
  String message;
  try {
    final label = redo ? await service.redo() : await service.undo();
    if (label == null) return;
    message = redo ? 'Redid $label' : 'Undid $label';
  } on GraphRuleException catch (e) {
    message = e.message;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}

/// "Deleted “Sam”" with an Undo button, after a destructive step.
void showUndoSnackBar(BuildContext context, WidgetRef ref, String message) {
  final messenger = ScaffoldMessenger.of(context);
  final service = ref.read(graphServiceProvider);
  // The step this snackbar is about; if something else happened since,
  // Undo here would reverse that instead, so it does nothing.
  final step = service.history.nextUndo;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (step != null && service.history.nextUndo == step) {
              replayStep(messenger, service);
            }
          },
        ),
      ),
    );
}
