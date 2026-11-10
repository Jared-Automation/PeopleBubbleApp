import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/hidden.dart';
import '../../domain/hit_test.dart';
import '../list/list_state.dart';

/// The selected bubble, line or waypoint on the canvas, or null. The wheel
/// acts on this.
class CanvasSelectionNotifier extends Notifier<CanvasHit?> {
  @override
  CanvasHit? build() => null;

  void select(CanvasHit? hit) => state = hit;
}

final canvasSelectionProvider =
    NotifierProvider<CanvasSelectionNotifier, CanvasHit?>(
      CanvasSelectionNotifier.new,
    );

/// A multi-bubble selection made by "Select subtree". Dragging any member
/// moves them all. Empty when there's no group.
class CanvasGroupNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void set(Set<String> ids) => state = Set.unmodifiable(ids);

  void clear() => state = const {};
}

final canvasGroupProvider = NotifierProvider<CanvasGroupNotifier, Set<String>>(
  CanvasGroupNotifier.new,
);

class CanvasSettings {
  const CanvasSettings({
    required this.dimUnrelated,
    required this.snapToGrid,
    required this.smoothLines,
    required this.showHidden,
  });

  /// Dim everything not connected to the selection.
  final bool dimUnrelated;

  /// Drop dragged bubbles and waypoints on the nearest grid point.
  final bool snapToGrid;

  /// Draw lines as curves through their waypoints instead of corners.
  final bool smoothLines;

  /// Show what's under hidden bubbles at full strength, on both screens.
  /// Toggled from the ⋮ menu.
  final bool showHidden;

  CanvasSettings copyWith({
    bool? dimUnrelated,
    bool? snapToGrid,
    bool? smoothLines,
    bool? showHidden,
  }) => CanvasSettings(
    dimUnrelated: dimUnrelated ?? this.dimUnrelated,
    snapToGrid: snapToGrid ?? this.snapToGrid,
    smoothLines: smoothLines ?? this.smoothLines,
    showHidden: showHidden ?? this.showHidden,
  );
}

/// Canvas preferences, saved across launches.
class CanvasSettingsNotifier extends Notifier<CanvasSettings> {
  static const _dimKey = 'canvas.dimUnrelated',
      _snapKey = 'canvas.snapToGrid',
      _smoothKey = 'canvas.smoothLines',
      _showHiddenKey = 'canvas.showHidden';

  @override
  CanvasSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return CanvasSettings(
      dimUnrelated: prefs.getBool(_dimKey) ?? true,
      snapToGrid: prefs.getBool(_snapKey) ?? false,
      smoothLines: prefs.getBool(_smoothKey) ?? false,
      showHidden: prefs.getBool(_showHiddenKey) ?? false,
    );
  }

  void setDimUnrelated(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_dimKey, value);
    state = state.copyWith(dimUnrelated: value);
  }

  void setSnapToGrid(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_snapKey, value);
    state = state.copyWith(snapToGrid: value);
  }

  void setSmoothLines(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_smoothKey, value);
    state = state.copyWith(smoothLines: value);
  }

  void setShowHidden(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_showHiddenKey, value);
    state = state.copyWith(showHidden: value);
  }
}

/// Which bubbles sit under hidden ones, recomputed only when the data
/// changes (not on every selection).
final hiddenGroupsProvider = Provider<HiddenGroups?>((ref) {
  final snapshot = ref.watch(graphSnapshotProvider).value;
  return snapshot == null ? null : HiddenGroups.of(snapshot);
});

final canvasSettingsProvider =
    NotifierProvider<CanvasSettingsNotifier, CanvasSettings>(
      CanvasSettingsNotifier.new,
    );
