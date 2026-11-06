import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/geometry.dart';
import '../../domain/graph.dart';
import '../../domain/placement.dart';
import '../common/type_pickers.dart';
import 'canvas_layout_cache.dart';
import 'graph_painter.dart';
import 'grid_painter.dart';

/// World (0, 0) sits in the middle of a huge canvas child, so the world can
/// extend this far in every direction without the child ever resizing.
const _worldHalfExtent = 100000.0;
const _origin = Offset(_worldHalfExtent, _worldHalfExtent);

/// Far enough out to fit a few hundred bubbles on a phone screen.
const _minScale = 0.02;
const _maxScale = 4.0;

/// The bubble canvas: everything drawn from saved positions, with pan and
/// pinch-zoom. Bubbles without a position are auto-placed and saved.
class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  final _cache = CanvasLayoutCache();
  late final _fitAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..addListener(_stepFit);
  Matrix4Tween? _fitTween;

  Size? _viewSize;
  bool _initialFitDone = false;

  /// Set once the user pans or zooms; from then on we don't move the view
  /// for them.
  bool _userMoved = false;
  bool _placing = false;
  bool _fitAfterPlacing = false;

  /// Placement waits for writes to pause, so a burst of changes (a bulk load,
  /// a bubble created before its line) is placed once, with the full picture.
  Timer? _placeDebounce;
  static const _placeDelay = Duration(milliseconds: 400);

  @override
  void dispose() {
    _placeDebounce?.cancel();
    _fitAnimation.dispose();
    _transform.dispose();
    _cache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(graphSnapshotProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bubbles')),
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
              : _buildCanvas(value),
        AsyncError(:final error) => Center(
          child: Text('Database error: $error'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildCanvas(GraphSnapshot snapshot) {
    _placeUnplaced(snapshot);
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
              GestureDetector(
                onDoubleTap: () => _fit(animate: true),
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: _minScale,
                  maxScale: _maxScale,
                  onInteractionStart: (_) {
                    _userMoved = true;
                    _fitAnimation.stop();
                  },
                  // Only the canvas repaints when data changes; panning just
                  // moves the already-painted layer.
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: const Size.square(2 * _worldHalfExtent),
                      painter: GraphPainter(
                        snapshot: snapshot,
                        cache: _cache,
                        origin: _origin,
                        labelBackground: colors.surface.withValues(alpha: 0.9),
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

  /// Gives every unplaced bubble a position and saves it, once the data has
  /// been quiet for [_placeDelay].
  void _placeUnplaced(GraphSnapshot snapshot) {
    if (snapshot.nodes.values.every((n) => n.isPlaced)) {
      _placeDebounce?.cancel();
      if (_fitAfterPlacing && !_placing) {
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
      final positions = placeUnplaced(
        snapshot,
        sizeOf: (node) => _cache.node(node.label, snapshot.styleOf(node)).size,
        viewCenter: _viewCenterInWorld(),
      );
      _fitAfterPlacing = true;
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
    final inverse = Matrix4.inverted(_transform.value);
    final p =
        MatrixUtils.transformPoint(inverse, size.center(Offset.zero)) - _origin;
    return Point(p.dx, p.dy);
  }

  /// Zooms and pans so every placed bubble is on screen (an empty canvas is
  /// centred on world 0, 0).
  void _fit({required bool animate}) {
    final view = _viewSize;
    final snapshot = ref.read(graphSnapshotProvider).value;
    if (view == null || snapshot == null || !mounted) return;
    final bounds = boundsOf([
      for (final n in snapshot.nodes.values)
        if (n.isPlaced)
          boxAt(
            Point(n.x!, n.y!),
            _cache.node(n.label, snapshot.styleOf(n)).size,
          ),
    ]);
    const margin = 32.0;
    final scale = bounds == null
        ? 1.0
        : min(
            (view.width - 2 * margin) / bounds.width,
            (view.height - 2 * margin) / bounds.height,
          ).clamp(_minScale, 1.5);
    final center = bounds == null
        ? Offset.zero
        : Offset(
            bounds.left + bounds.width / 2,
            bounds.top + bounds.height / 2,
          );
    final target = Matrix4.translationValues(view.width / 2, view.height / 2, 0)
        // Scale z too: InteractiveViewer reads the zoom level with
        // getMaxScaleOnAxis(), which would see an unscaled z as 1×.
        .multiplied(Matrix4.diagonal3Values(scale, scale, scale))
        .multiplied(
          Matrix4.translationValues(
            -(center.dx + _origin.dx),
            -(center.dy + _origin.dy),
            0,
          ),
        );
    if (!animate) {
      _transform.value = target;
      return;
    }
    _fitTween = Matrix4Tween(begin: _transform.value, end: target);
    _fitAnimation.forward(from: 0);
  }

  void _stepFit() {
    final tween = _fitTween;
    if (tween == null) return;
    _transform.value = tween.transform(
      Curves.easeOutCubic.transform(_fitAnimation.value),
    );
  }
}
