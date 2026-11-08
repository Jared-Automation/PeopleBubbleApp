import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  /// Dim everything not connected to the selection.
  final bool dimUnrelated;

  /// Drop dragged bubbles and waypoints on the nearest grid point.
  final bool snapToGrid;

  /// Draw lines as curves through their waypoints instead of corners.
  final bool smoothLines;

  CanvasSettings copyWith({
    bool? dimUnrelated,
    bool? snapToGrid,
    bool? smoothLines,
  }) => CanvasSettings(
    dimUnrelated: dimUnrelated ?? this.dimUnrelated,
    snapToGrid: snapToGrid ?? this.snapToGrid,
    smoothLines: smoothLines ?? this.smoothLines,
  );
}

/// Canvas preferences, saved across launches.
class CanvasSettingsNotifier extends Notifier<CanvasSettings> {
  static const _dimKey = 'canvas.dimUnrelated',
      _snapKey = 'canvas.snapToGrid',
      _smoothKey = 'canvas.smoothLines';

  @override
  CanvasSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return CanvasSettings(
      dimUnrelated: prefs.getBool(_dimKey) ?? true,
      snapToGrid: prefs.getBool(_snapKey) ?? false,
      smoothLines: prefs.getBool(_smoothKey) ?? false,
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
}

final canvasSettingsProvider =
    NotifierProvider<CanvasSettingsNotifier, CanvasSettings>(
      CanvasSettingsNotifier.new,
    );
