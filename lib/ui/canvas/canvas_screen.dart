import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/geometry.dart';
import '../../domain/graph.dart';
import '../../domain/hit_test.dart';
import '../../domain/placement.dart';
import '../common/type_pickers.dart';
import 'canvas_layout_cache.dart';
import 'canvas_scene.dart';
import 'canvas_state.dart';
import 'graph_painter.dart';
import 'grid_painter.dart';
import 'rename_dialog.dart';

/// World (0, 0) sits in the middle of a huge canvas child, so the world can
/// extend this far in every direction without the child ever resizing.
const _worldHalfExtent = 100000.0;
const _origin = Offset(_worldHalfExtent, _worldHalfExtent);

/// Far enough out to fit a few hundred bubbles on a phone screen.
const _minScale = 0.02;
const _maxScale = 4.0;

/// The finger that went down first, and what it landed on.
class _Press {
  const _Press({
    required this.pointer,
    required this.start,
    required this.time,
    required this.hit,
    required this.world,
    required this.nodeStart,
  });

  final int pointer;

  /// Screen position (canvas-local) and time of the touch.
  final Offset start;
  final Duration time;
  final CanvasHit? hit;

  /// World position under the finger, and the touched bubble's centre.
  final Point<double> world;
  final Point<double>? nodeStart;
}

/// The bubble canvas: drawn from saved positions, with pan and pinch-zoom,
/// tap to select, drag to move, double-tap to rename. Bubbles without a
/// position are auto-placed and saved.
class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  final _cache = CanvasLayoutCache();
  late final _viewAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..addListener(_stepViewAnimation);
  Matrix4Tween? _viewTween;

  Size? _viewSize;
  CanvasScene? _scene;
  bool _initialFitDone = false;

  /// Set once the user pans or zooms; from then on we don't zoom-to-fit for
  /// them (small "pan to show" moves still happen).
  bool _userMoved = false;

  // ---- placement
  bool _placing = false;
  bool _fitAfterPlacing = false;
  List<Rectangle<double>>? _revealAfterPlacing;

  /// Placement waits for writes to pause, so a burst of changes (a bulk load,
  /// a bubble created before its line) is placed once, with the full picture.
  Timer? _placeDebounce;
  static const _placeDelay = Duration(milliseconds: 400);

  // ---- gestures
  //
  // Raw pointer events (a Listener) decide what a touch is, instead of
  // competing gesture detectors: a finger that lands on a bubble turns off
  // the viewer's panning and drags the bubble; anywhere else the viewer pans
  // as usual. A second finger always means pinch.
  final _pointers = <int>{};
  _Press? _press;
  bool _dragging = false;
  bool _panEnabled = true;

  /// The view when a finger landed on a bubble. Turning off the viewer's
  /// panning needs a rebuild, and the first moves can arrive before it; any
  /// pan the viewer makes during a bubble touch is undone back to this.
  Matrix4? _frozenView;
  Offset? _dragLocal;
  Timer? _edgePan;
  Duration? _lastTapTime;
  Offset? _lastTapPosition;
  static const _doubleTapTime = Duration(milliseconds: 300);
  static const _tapMaxTime = Duration(milliseconds: 500);

  /// Live bubble positions that win over the saved ones: the bubble being
  /// dragged, and a dropped bubble until its saved position arrives.
  final _overrides = <String, Point<double>>{};

  @override
  void dispose() {
    _placeDebounce?.cancel();
    _edgePan?.cancel();
    _viewAnimation.dispose();
    _transform.dispose();
    _cache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(graphSnapshotProvider);
    final settings = ref.watch(canvasSettingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubbles'),
        actions: [_SettingsMenu(settings: settings)],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Zoom to fit',
        onPressed: () => _fit(animate: true),
        child: const Icon(Icons.fit_screen),
      ),
      body: switch (snapshot) {
        AsyncData(:final value) =>
          value.nodes.isEmpty
              ? const Center(
                  child: Text('Nothing here yet. Add people from the List.'),
                )
              : _buildCanvas(value, settings),
        AsyncError(:final error) => Center(
          child: Text('Database error: $error'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildCanvas(GraphSnapshot snapshot, CanvasSettings settings) {
    _placeUnplaced(snapshot);
    // A dropped bubble's override is no longer needed once the saved
    // position has arrived (or the bubble is gone).
    _overrides.removeWhere((id, p) {
      if (_dragging && (_press?.hit as NodeHit?)?.id == id) return false;
      final node = snapshot.nodes[id];
      return node == null || (node.x == p.x && node.y == p.y);
    });
    final scene = _scene = CanvasScene.build(
      snapshot,
      _cache,
      overrides: _overrides,
    );
    final selection = _validSelection(snapshot);
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewSize = constraints.biggest;
        if (!_initialFitDone) {
          _initialFitDone = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fit(animate: false),
          );
        }
        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPainter(_transform, colors.outlineVariant),
                ),
              ),
              Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: _minScale,
                  maxScale: _maxScale,
                  panEnabled: _panEnabled,
                  onInteractionStart: (_) {
                    if (_frozenView == null) _userMoved = true;
                  },
                  onInteractionUpdate: (_) {
                    final frozen = _frozenView;
                    if (frozen != null) _transform.value = frozen.clone();
                  },
                  // Only the canvas repaints when data changes; panning just
                  // moves the already-painted layer.
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: const Size.square(2 * _worldHalfExtent),
                      painter: GraphPainter(
                        scene: scene,
                        cache: _cache,
                        origin: _origin,
                        labelBackground: colors.surface.withValues(alpha: 0.9),
                        highlight: colors.primary,
                        selection: selection,
                        dimUnrelated: settings.dimUnrelated,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The selection, or null if it points at something deleted since.
  CanvasHit? _validSelection(GraphSnapshot snapshot) {
    final selection = ref.watch(canvasSelectionProvider);
    final exists = switch (selection) {
      NodeHit(:final id) => snapshot.nodes.containsKey(id),
      EdgeHit(:final id) => snapshot.edges.containsKey(id),
      null => true,
    };
    if (exists) return selection;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(canvasSelectionProvider.notifier).select(null),
    );
    return null;
  }

  // ------------------------------------------------------------ gestures

  double get _scale => _transform.value.getMaxScaleOnAxis();

  Point<double> _toWorld(Offset local) {
    final p =
        MatrixUtils.transformPoint(Matrix4.inverted(_transform.value), local) -
        _origin;
    return Point(p.dx, p.dy);
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers.add(e.pointer);
    _viewAnimation.stop();
    if (_pointers.length > 1) {
      // A second finger: this is a pinch, not a drag or tap.
      _cancelPress();
      return;
    }
    final world = _toWorld(e.localPosition);
    final hit = _scene?.hitAt(world, scale: _scale);
    _press = _Press(
      pointer: e.pointer,
      start: e.localPosition,
      time: e.timeStamp,
      hit: hit,
      world: world,
      nodeStart: hit is NodeHit ? centerOf(_scene!.nodes[hit.id]!.box) : null,
    );
    if (hit is NodeHit) {
      _frozenView = _transform.value.clone();
      setState(() => _panEnabled = false);
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    final press = _press;
    if (press == null || e.pointer != press.pointer) return;
    if (!_dragging) {
      if (press.hit is! NodeHit) return;
      if ((e.localPosition - press.start).distance < kTouchSlop) return;
      _dragging = true;
      _startEdgePan();
    }
    _dragLocal = e.localPosition;
    _updateDrag();
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    final press = _press;
    if (press != null && e.pointer == press.pointer) {
      _press = null;
      if (_dragging) {
        _finishDrag(press);
      } else if ((e.localPosition - press.start).distance < kTouchSlop &&
          e.timeStamp - press.time < _tapMaxTime) {
        _onTap(press, e.timeStamp);
      }
    }
    _endTouch();
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (e.pointer == _press?.pointer) _cancelPress();
    _endTouch();
  }

  void _endTouch() {
    if (_pointers.isNotEmpty) return;
    _frozenView = null;
    if (!_panEnabled) setState(() => _panEnabled = true);
  }

  /// Abandons the current touch: a dragged bubble snaps back.
  void _cancelPress() {
    final hit = _press?.hit;
    if (_dragging && hit is NodeHit) _overrides.remove(hit.id);
    _dragging = false;
    _press = null;
    _lastTapTime = null;
    _frozenView = null;
    _stopEdgePan();
    setState(() => _panEnabled = true);
  }

  void _updateDrag() {
    final press = _press, local = _dragLocal;
    if (press == null || local == null) return;
    final world = _toWorld(local);
    setState(() {
      _overrides[(press.hit! as NodeHit).id] = Point(
        press.nodeStart!.x + world.x - press.world.x,
        press.nodeStart!.y + world.y - press.world.y,
      );
    });
  }

  Future<void> _finishDrag(_Press press) async {
    final id = (press.hit! as NodeHit).id;
    _dragging = false;
    _stopEdgePan();
    var p = _overrides[id];
    if (p == null) return;
    if (ref.read(canvasSettingsProvider).snapToGrid) {
      p = snapToGrid(p);
      setState(() => _overrides[id] = p!);
    }
    // One write per drag, on release.
    try {
      await ref.read(graphServiceProvider).moveNode(id, p.x, p.y);
    } catch (e) {
      if (!mounted) return;
      setState(() => _overrides.remove(id));
      showGraphError(context, e);
    }
  }

  void _onTap(_Press press, Duration time) {
    final lastTime = _lastTapTime, lastPosition = _lastTapPosition;
    final isDouble =
        lastTime != null &&
        lastPosition != null &&
        time - lastTime < _doubleTapTime &&
        (press.start - lastPosition).distance < 32;
    if (isDouble) {
      _lastTapTime = null;
      switch (press.hit) {
        case NodeHit(:final id):
          _renameNode(id);
        case EdgeHit(:final id):
          _renameEdge(id);
        case null:
          _fit(animate: true);
      }
      return;
    }
    _lastTapTime = time;
    _lastTapPosition = press.start;
    ref.read(canvasSelectionProvider.notifier).select(press.hit);
  }

  /// While dragging near a screen edge, pans the canvas so the bubble can be
  /// carried further.
  void _startEdgePan() {
    _edgePan ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final local = _dragLocal, view = _viewSize;
      if (local == null || view == null) return;
      const edge = 56.0, speed = 12.0;
      double push(double at, double size) {
        if (at < edge) return speed * (1 - at / edge);
        if (at > size - edge) return -speed * (1 - (size - at) / edge);
        return 0;
      }

      final dx = push(local.dx, view.width), dy = push(local.dy, view.height);
      if (dx == 0 && dy == 0) return;
      _transform.value = Matrix4.translationValues(
        dx,
        dy,
        0,
      ).multiplied(_transform.value);
      _frozenView = _transform.value.clone();
      _updateDrag();
    });
  }

  void _stopEdgePan() {
    _edgePan?.cancel();
    _edgePan = null;
    _dragLocal = null;
  }

  Future<void> _renameNode(String id) async {
    final node = ref.read(graphSnapshotProvider).value?.nodes[id];
    if (node == null) return;
    final name = await showRenameDialog(
      context,
      title: 'Rename',
      initial: node.label,
    );
    if (name == null || !mounted) return;
    try {
      await ref.read(graphServiceProvider).updateNode(id, label: name);
    } catch (e) {
      if (mounted) showGraphError(context, e);
    }
  }

  Future<void> _renameEdge(String id) async {
    final edge = ref.read(graphSnapshotProvider).value?.edges[id];
    if (edge == null) return;
    final label = await showRenameDialog(
      context,
      title: 'Line label',
      initial: edge.label ?? '',
      label: 'Label (optional)',
      allowEmpty: true,
    );
    if (label == null || !mounted) return;
    try {
      await ref
          .read(graphServiceProvider)
          .updateEdge(id, typeId: edge.typeId, label: label);
    } catch (e) {
      if (mounted) showGraphError(context, e);
    }
  }

  // ------------------------------------------------------------ placement

  /// Gives every unplaced bubble a position and saves it, once the data has
  /// been quiet for [_placeDelay]. Afterwards a few new bubbles are panned
  /// into view; a big batch zooms to fit.
  void _placeUnplaced(GraphSnapshot snapshot) {
    if (snapshot.nodes.values.every((n) => n.isPlaced)) {
      _placeDebounce?.cancel();
      if (_placing) return;
      final reveal = _revealAfterPlacing;
      if (reveal != null) {
        _revealAfterPlacing = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(reveal));
      } else if (_fitAfterPlacing) {
        _fitAfterPlacing = false;
        if (!_userMoved) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fit(animate: true),
          );
        }
      }
      return;
    }
    _placeDebounce?.cancel();
    _placeDebounce = Timer(_placeDelay, _placeNow);
  }

  Future<void> _placeNow() async {
    // Always place from the latest data, not the snapshot that started the
    // timer.
    final snapshot = ref.read(graphSnapshotProvider).value;
    if (_placing || snapshot == null || !mounted) return;
    _placing = true;
    try {
      BoxSize sizeOf(GraphNode node) =>
          _cache.node(node.label, snapshot.styleOf(node)).size;
      final positions = placeUnplaced(
        snapshot,
        sizeOf: sizeOf,
        viewCenter: _viewCenterInWorld(),
      );
      final placedBefore = snapshot.nodes.length - positions.length;
      if (positions.length <= 3 && placedBefore > 0) {
        _revealAfterPlacing = [
          for (final MapEntry(key: id, value: p) in positions.entries)
            boxAt(p, sizeOf(snapshot.nodes[id]!)),
        ];
      } else {
        _fitAfterPlacing = true;
      }
      await ref.read(graphServiceProvider).placeNodes(positions);
    } catch (e) {
      if (mounted) showGraphError(context, e);
    } finally {
      _placing = false;
    }
  }

  /// The world point currently in the middle of the screen.
  Point<double> _viewCenterInWorld() {
    final size = _viewSize;
    if (size == null) return const Point(0, 0);
    return _toWorld(size.center(Offset.zero));
  }

  /// Pans just enough to bring [boxes] on screen (no zoom change).
  void _reveal(List<Rectangle<double>> boxes) {
    final view = _viewSize;
    final target = boundsOf(boxes);
    if (view == null || target == null || !mounted) return;
    final scale = _scale;
    final margin = 48 / scale;
    final topLeft = _toWorld(Offset.zero);
    final visible = Rectangle(
      topLeft.x + margin,
      topLeft.y + margin,
      max(0.0, view.width / scale - 2 * margin),
      max(0.0, view.height / scale - 2 * margin),
    );
    double shift(double lo, double hi, double vLo, double vHi) {
      if (hi - lo > vHi - vLo) return (lo + hi) / 2 - (vLo + vHi) / 2;
      if (lo < vLo) return lo - vLo;
      if (hi > vHi) return hi - vHi;
      return 0;
    }

    final sx = shift(target.left, target.right, visible.left, visible.right);
    final sy = shift(target.top, target.bottom, visible.top, visible.bottom);
    if (sx == 0 && sy == 0) return;
    _animateTo(
      _transform.value.multiplied(Matrix4.translationValues(-sx, -sy, 0)),
    );
  }

  /// Zooms and pans so every placed bubble is on screen (an empty canvas is
  /// centred on world 0, 0).
  void _fit({required bool animate}) {
    final view = _viewSize;
    final scene = _scene;
    if (view == null || scene == null || !mounted) return;
    final bounds = scene.bounds;
    const margin = 32.0;
    final scale = bounds == null
        ? 1.0
        : min(
            (view.width - 2 * margin) / bounds.width,
            (view.height - 2 * margin) / bounds.height,
          ).clamp(_minScale, 1.5);
    final center = bounds == null ? const Point(0.0, 0.0) : centerOf(bounds);
    final target = Matrix4.translationValues(view.width / 2, view.height / 2, 0)
        // Scale z too: InteractiveViewer reads the zoom level with
        // getMaxScaleOnAxis(), which would see an unscaled z as 1×.
        .multiplied(Matrix4.diagonal3Values(scale, scale, scale))
        .multiplied(
          Matrix4.translationValues(
            -(center.x + _origin.dx),
            -(center.y + _origin.dy),
            0,
          ),
        );
    if (animate) {
      _animateTo(target);
    } else {
      _transform.value = target;
    }
  }

  void _animateTo(Matrix4 target) {
    _viewTween = Matrix4Tween(begin: _transform.value, end: target);
    _viewAnimation.forward(from: 0);
  }

  void _stepViewAnimation() {
    final tween = _viewTween;
    if (tween == null) return;
    _transform.value = tween.transform(
      Curves.easeOutCubic.transform(_viewAnimation.value),
    );
  }
}

/// Canvas preferences: dimming and snap-to-grid.
class _SettingsMenu extends ConsumerWidget {
  const _SettingsMenu({required this.settings});

  final CanvasSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(canvasSettingsProvider.notifier);
    return PopupMenuButton<VoidCallback>(
      icon: const Icon(Icons.tune),
      tooltip: 'Canvas settings',
      onSelected: (toggle) => toggle(),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: () => notifier.setDimUnrelated(!settings.dimUnrelated),
          checked: settings.dimUnrelated,
          child: const Text('Dim unrelated when selecting'),
        ),
        CheckedPopupMenuItem(
          value: () => notifier.setSnapToGrid(!settings.snapToGrid),
          checked: settings.snapToGrid,
          child: const Text('Snap to grid'),
        ),
      ],
    );
  }
}
