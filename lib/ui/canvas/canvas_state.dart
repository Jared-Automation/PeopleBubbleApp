import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/hit_test.dart';
import '../list/list_state.dart';

/// The selected bubble or line on the canvas, or null. Phase 6's wheel acts
/// on this.
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
  const CanvasSettings({required this.dimUnrelated, required this.snapToGrid});

  /// Dim everything not connected to the selection.
  final bool dimUnrelated;

  /// Drop dragged bubbles on the nearest grid point.
  final bool snapToGrid;
}

/// Canvas preferences, saved across launches.
class CanvasSettingsNotifier extends Notifier<CanvasSettings> {
  static const _dimKey = 'canvas.dimUnrelated', _snapKey = 'canvas.snapToGrid';

  @override
  CanvasSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return CanvasSettings(
      dimUnrelated: prefs.getBool(_dimKey) ?? true,
      snapToGrid: prefs.getBool(_snapKey) ?? false,
    );
  }

  void setDimUnrelated(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_dimKey, value);
    state = CanvasSettings(dimUnrelated: value, snapToGrid: state.snapToGrid);
  }

  void setSnapToGrid(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_snapKey, value);
    state = CanvasSettings(dimUnrelated: state.dimUnrelated, snapToGrid: value);
  }
}

final canvasSettingsProvider =
    NotifierProvider<CanvasSettingsNotifier, CanvasSettings>(
      CanvasSettingsNotifier.new,
    );
