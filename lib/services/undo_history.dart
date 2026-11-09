import 'package:flutter/foundation.dart';

import '../data/graph_dump.dart';

/// One undoable step: the rows it changed, before and after.
class HistoryEntry {
  HistoryEntry(this.label, this.diff);

  /// Shown as "Undo: <label>", e.g. "move “Sam”".
  final String label;
  final DumpDiff diff;
}

/// What the undo/redo buttons show.
@immutable
class UndoState {
  const UndoState({this.undoLabel, this.redoLabel});

  /// The step Undo would reverse, or null when there's nothing to undo.
  final String? undoLabel;
  final String? redoLabel;

  bool get canUndo => undoLabel != null;
  bool get canRedo => redoLabel != null;
}

/// The in-memory undo and redo stacks, up to [limit] steps each. Lives for
/// one app run. [state] is a `ValueNotifier`, so widgets can listen to it
/// like a bindable property.
class UndoHistory {
  UndoHistory({this.limit = 50});

  final int limit;
  final _undo = <HistoryEntry>[];
  final _redo = <HistoryEntry>[];
  final state = ValueNotifier(const UndoState());

  HistoryEntry? get nextUndo => _undo.isEmpty ? null : _undo.last;
  HistoryEntry? get nextRedo => _redo.isEmpty ? null : _redo.last;

  /// Records a new step. Any redo steps are dropped.
  void push(HistoryEntry entry) {
    _undo.add(entry);
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
    _notify();
  }

  /// Moves the top undo step to the redo stack (after it was undone).
  void undone() {
    _redo.add(_undo.removeLast());
    _notify();
  }

  /// Moves the top redo step back to the undo stack (after it was redone).
  void redone() {
    _undo.add(_redo.removeLast());
    _notify();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
    _notify();
  }

  /// Folds a write that isn't its own step (auto-placement) into the
  /// history: the newest undo step that touched the row now ends with
  /// [row], and the next redo step that touched it now starts from it. So
  /// later undos still see the rows they expect.
  void absorb(String table, String key, DbRow? row) {
    for (final e in _undo.reversed) {
      final c = e.diff.tables[table]?[key];
      if (c != null) {
        e.diff.tables[table]![key] = RowChange(c.before, row);
        break;
      }
    }
    for (final e in _redo.reversed) {
      final c = e.diff.tables[table]?[key];
      if (c != null) {
        e.diff.tables[table]![key] = RowChange(row, c.after);
        break;
      }
    }
  }

  void _notify() => state.value = UndoState(
    undoLabel: nextUndo?.label,
    redoLabel: nextRedo?.label,
  );
}
