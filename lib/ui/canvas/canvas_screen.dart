import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/seed.dart';
import '../../domain/geometry.dart';
import '../../domain/graph.dart';
import '../../domain/hit_test.dart';
import '../../domain/placement.dart';
import '../../domain/radial_menu.dart';
import '../common/confirm_delete.dart';
import '../common/line_sheet.dart';
import '../common/type_pickers.dart';
import '../list/add_sheet.dart';
import '../list/edit_sheet.dart';
import 'canvas_layout_cache.dart';
import 'canvas_scene.dart';
import 'canvas_state.dart';
import 'graph_painter.dart';
import 'grid_painter.dart';
import 'radial_wheel.dart';
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
    required this.starts,
  });

  final int pointer;

  /// Screen position (canvas-local) and time of the touch.
  final Offset start;
  final Duration time;
  final CanvasHit? hit;

  /// World position under the finger.
  final Point<double> world;

  /// Centres of the bubbles a drag would move: the touched bubble, or its
  /// whole group if it's part of a selected subtree.
  final Map<String, Point<double>> starts;
}

/// An open radial wheel.
class _Wheel {
  _Wheel({
    required this.center,
    required this.title,
    required this.items,
    required this.pointer,
    required this.opened,
  });

  final Offset center;

  /// Where the finger was when the wheel opened. Near a screen edge the
  /// wheel is pushed inward, so this isn't [center]; the finger has to slide
  /// away from here before it picks anything.
  final Offset opened;
  bool slid = false;
  final String title;
  final List<WheelItem> items;

  /// The finger that opened it, while it's still down ("slide and lift");
  /// null once lifted, when the wheel waits for a tap instead.
  int? pointer;
  WheelSlot? hovered;
  bool moreOpen = false;
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

  // ---- radial wheel
  Timer? _longPress;
  _Wheel? _wheel;
  static const _longPressTime = Duration(milliseconds: 450);
  static const _wheelGeometry = RadialGeometry();

  /// Live bubble positions that win over the saved ones: the bubble being
  /// dragged, and a dropped bubble until its saved position arrives.
  final _overrides = <String, Point<double>>{};

  @override
  void dispose() {
    _placeDebounce?.cancel();
    _edgePan?.cancel();
    _longPress?.cancel();
    _viewAnimation.dispose();
    _transform.dispose();
    _cache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(graphSnapshotProvider);
    final settings = ref.watch(canvasSettingsProvider);
    return PopScope(
      // Back closes an open wheel instead of leaving the screen.
      canPop: _wheel == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeWheel();
      },
      child: _scaffold(snapshot, settings),
    );
  }

  Widget _scaffold(
    AsyncValue<GraphSnapshot> snapshot,
    CanvasSettings settings,
  ) {
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
      if (_dragging && (_press?.starts.containsKey(id) ?? false)) return false;
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
                        group: ref.watch(canvasGroupProvider),
                      ),
                    ),
                  ),
                ),
              ),
              if (_wheel case final wheel?)
                Positioned.fill(
                  child: RadialWheel(
                    center: wheel.center,
                    title: wheel.title,
                    items: wheel.items,
                    hovered: wheel.hovered,
                    moreOpen: wheel.moreOpen,
                    geometry: _wheelGeometry,
                    onTap: (slot) => _chooseSlot(slot, lifted: false),
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
    // While a wheel is held open by a finger, other fingers do nothing.
    if (_wheel?.pointer != null) return;
    if (_pointers.length > 1) {
      // A second finger: this is a pinch, not a drag or tap.
      _cancelPress();
      return;
    }
    final world = _toWorld(e.localPosition);
    final hit = _scene?.hitAt(world, scale: _scale);
    final press = _press = _Press(
      pointer: e.pointer,
      start: e.localPosition,
      time: e.timeStamp,
      hit: hit,
      world: world,
      starts: hit is NodeHit ? _dragStarts(hit.id) : const {},
    );
    if (hit is NodeHit) {
      _frozenView = _transform.value.clone();
      setState(() => _panEnabled = false);
    }
    _longPress?.cancel();
    _longPress = Timer(_longPressTime, () => _openWheel(press));
  }

  /// Centres of what a drag starting on [id] moves: its group, or just it.
  Map<String, Point<double>> _dragStarts(String id) {
    final scene = _scene!;
    final group = ref.read(canvasGroupProvider);
    final ids = group.contains(id) ? group : {id};
    return {
      for (final g in ids)
        if (scene.nodes[g] case final n?) g: centerOf(n.box),
    };
  }

  void _onPointerMove(PointerMoveEvent e) {
    final wheel = _wheel;
    if (wheel != null) {
      if (e.pointer != wheel.pointer) return;
      if (!wheel.slid &&
          (e.localPosition - wheel.opened).distance < kTouchSlop) {
        return;
      }
      wheel.slid = true;
      _hoverWheel(wheel, e.localPosition);
      return;
    }
    final press = _press;
    if (press == null || e.pointer != press.pointer) return;
    if ((e.localPosition - press.start).distance >= kTouchSlop) {
      _longPress?.cancel();
    }
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
    _longPress?.cancel();
    final wheel = _wheel;
    if (wheel != null && e.pointer == wheel.pointer) {
      // Lifted: choose the slot under the finger, or stay open for a tap.
      _press = null;
      wheel.pointer = null;
      _chooseSlot(wheel.hovered, lifted: true);
      _endTouch();
      return;
    }
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
    _longPress?.cancel();
    if (e.pointer == _wheel?.pointer) _closeWheel();
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
    _longPress?.cancel();
    if (_dragging) _press?.starts.keys.forEach(_overrides.remove);
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
    final dx = world.x - press.world.x, dy = world.y - press.world.y;
    setState(() {
      for (final MapEntry(key: id, value: start) in press.starts.entries) {
        _overrides[id] = Point(start.x + dx, start.y + dy);
      }
    });
  }

  Future<void> _finishDrag(_Press press) async {
    final id = (press.hit! as NodeHit).id;
    _dragging = false;
    _stopEdgePan();
    final dropped = _overrides[id];
    if (dropped == null) return;
    // Snap the touched bubble; the rest of a group keeps its shape.
    final snapped = ref.read(canvasSettingsProvider).snapToGrid
        ? snapToGrid(dropped)
        : dropped;
    final start = press.starts[id]!;
    final dx = snapped.x - start.x, dy = snapped.y - start.y;
    final positions = {
      for (final MapEntry(key: g, value: s) in press.starts.entries)
        g: Point(s.x + dx, s.y + dy),
    };
    setState(() => _overrides.addAll(positions));
    // One write per drag, on release.
    try {
      final service = ref.read(graphServiceProvider);
      if (positions.length == 1) {
        await service.moveNode(id, snapped.x, snapped.y);
      } else {
        await service.moveNodes(positions);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => positions.keys.forEach(_overrides.remove));
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
    ref.read(canvasGroupProvider.notifier).clear();
    ref.read(canvasSelectionProvider.notifier).select(press.hit);
  }

  // ------------------------------------------------------------ wheel

  void _openWheel(_Press press) {
    final view = _viewSize;
    final snapshot = ref.read(graphSnapshotProvider).value;
    if (!mounted || view == null || snapshot == null || _dragging) return;
    final (title, items) = switch (press.hit) {
      NodeHit(:final id) => (snapshot.nodes[id]?.label ?? '', _nodeItems(id)),
      EdgeHit(:final id) => (_edgeTitle(snapshot, id), _edgeItems(id)),
      null => ('', _canvasItems(press.world)),
    };
    final hasMore = items.any((i) => i.isMore);
    final c = RadialGeometry.clampCenter(
      Point(press.start.dx, press.start.dy),
      radius: hasMore ? _wheelGeometry.outerRadius : _wheelGeometry.innerRadius,
      width: view.width,
      height: view.height,
    );
    HapticFeedback.mediumImpact();
    if (press.hit case final hit?) {
      if (hit is! NodeHit || !ref.read(canvasGroupProvider).contains(hit.id)) {
        ref.read(canvasGroupProvider.notifier).clear();
      }
      ref.read(canvasSelectionProvider.notifier).select(hit);
    }
    _frozenView = _transform.value.clone();
    setState(() {
      _panEnabled = false;
      _wheel = _Wheel(
        center: Offset(c.x, c.y),
        title: title,
        items: items,
        pointer: press.pointer,
        opened: press.start,
      );
    });
  }

  String _edgeTitle(GraphSnapshot s, String id) {
    final e = s.edges[id];
    if (e == null) return '';
    return '${s.nodes[e.sourceId]?.label} → ${s.nodes[e.targetId]?.label}';
  }

  void _hoverWheel(_Wheel wheel, Offset local) {
    final d = local - wheel.center;
    final moreIndex = wheel.items.indexWhere((i) => i.isMore);
    final slot = _wheelGeometry.slotAt(
      d.dx,
      d.dy,
      innerCount: wheel.items.length,
      outerCount: wheel.moreOpen ? wheel.items[moreIndex].more!.length : null,
      moreIndex: wheel.moreOpen ? moreIndex : null,
    );
    if (slot == wheel.hovered) return;
    HapticFeedback.selectionClick();
    setState(() {
      wheel.hovered = slot;
      // Sliding onto More opens its ring right away.
      if (slot == (ring: 0, index: moreIndex)) wheel.moreOpen = true;
    });
  }

  /// Acts on [slot]. [lifted] is true when a sliding finger let go: then the
  /// centre (or More, or a disabled slice) keeps the wheel open for a tap.
  void _chooseSlot(WheelSlot? slot, {required bool lifted}) {
    final wheel = _wheel;
    if (wheel == null) return;
    if (slot == null) {
      lifted ? setState(() => wheel.hovered = null) : _closeWheel();
      return;
    }
    final item = slot.ring == 0
        ? wheel.items[slot.index]
        : wheel.items.firstWhere((i) => i.isMore).more![slot.index];
    if (item.isMore) {
      setState(() {
        wheel.moreOpen = true;
        wheel.hovered = null;
      });
      return;
    }
    if (item.comingSoon) {
      _closeWheel();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${item.label} is coming in a later phase.')),
        );
      return;
    }
    final action = item.onSelected;
    if (action == null) return;
    _closeWheel();
    action();
  }

  void _closeWheel() {
    if (_wheel == null) return;
    setState(() => _wheel = null);
    _endTouch();
  }

  List<WheelItem> _nodeItems(String id) => [
    WheelItem(
      label: 'Add child',
      icon: Icons.add_circle_outline,
      onSelected: () => showAddSheet(context, parentId: id),
    ),
    WheelItem(
      label: 'Link',
      icon: Icons.add_link,
      onSelected: () => showAddSheet(context, parentId: id, existingTab: true),
    ),
    WheelItem(
      label: 'Rename',
      icon: Icons.edit_outlined,
      onSelected: () => _renameNode(id),
    ),
    WheelItem(
      label: 'Types',
      icon: Icons.category_outlined,
      onSelected: () => showEditSheet(context, nodeId: id),
    ),
    WheelItem(
      label: 'Delete',
      icon: Icons.delete_outline,
      onSelected: () => confirmAndDeleteNode(context, ref, id),
    ),
    WheelItem(
      label: 'More',
      icon: Icons.more_horiz,
      more: [
        const WheelItem(
          label: 'Style',
          icon: Icons.palette_outlined,
          comingSoon: true,
        ),
        WheelItem(
          label: 'Subtree',
          icon: Icons.account_tree_outlined,
          onSelected: () => _selectSubtree(id),
        ),
        WheelItem(
          label: 'Focus',
          icon: Icons.center_focus_strong_outlined,
          onSelected: () => _focus(id),
        ),
      ],
    ),
  ];

  List<WheelItem> _edgeItems(String id) => [
    WheelItem(
      label: 'Type',
      icon: Icons.category_outlined,
      onSelected: () => showLineSheet(context, edgeId: id),
    ),
    WheelItem(
      label: 'Label',
      icon: Icons.label_outline,
      onSelected: () => _renameEdge(id),
    ),
    const WheelItem(label: 'Waypoint', icon: Icons.commit, comingSoon: true),
    WheelItem(
      label: 'Delete',
      icon: Icons.delete_outline,
      onSelected: () => _deleteEdge(id),
    ),
    WheelItem(
      label: 'More',
      icon: Icons.more_horiz,
      more: [
        const WheelItem(
          label: 'Style',
          icon: Icons.palette_outlined,
          comingSoon: true,
        ),
        WheelItem(
          label: 'Reverse',
          icon: Icons.swap_vert,
          onSelected: () =>
              _run(() => ref.read(graphServiceProvider).reverseEdge(id)),
        ),
      ],
    ),
  ];

  List<WheelItem> _canvasItems(Point<double> world) => [
    WheelItem(
      label: 'New here',
      icon: Icons.add,
      onSelected: () => showAddSheet(context, parentId: null, position: world),
    ),
    WheelItem(
      label: 'Paste',
      icon: Icons.content_paste,
      onSelected: () => _paste(world),
    ),
    WheelItem(
      label: 'Fit',
      icon: Icons.fit_screen,
      onSelected: () => _fit(animate: true),
    ),
  ];

  /// Selects [id] and everything under it as a group that drags together.
  void _selectSubtree(String id) {
    final snapshot = ref.read(graphSnapshotProvider).value;
    if (snapshot == null) return;
    ref.read(canvasGroupProvider.notifier).set(subtreeOf(snapshot, id));
    ref.read(canvasSelectionProvider.notifier).select(NodeHit(id));
  }

  /// Selects [id] and zooms to it and its direct connections.
  void _focus(String id) {
    final snapshot = ref.read(graphSnapshotProvider).value;
    final scene = _scene;
    if (snapshot == null || scene == null) return;
    ref.read(canvasGroupProvider.notifier).clear();
    ref.read(canvasSelectionProvider.notifier).select(NodeHit(id));
    final near = neighborhoodOf(snapshot, nodeId: id).nodes;
    _fitTo(
      boundsOf([
        for (final n in near)
          if (scene.nodes[n] case final sn?) sn.box,
      ]),
      animate: true,
    );
  }

  Future<void> _deleteEdge(String id) async {
    await _run(() => ref.read(graphServiceProvider).deleteEdge(id));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Line deleted')));
  }

  /// New bubbles from the clipboard's text, one per line, stacked at [at].
  Future<void> _paste(Point<double> at) async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    final names = [
      for (final line in text.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ].take(50).toList();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (names.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nothing to paste: no text copied.')),
      );
      return;
    }
    final service = ref.read(graphServiceProvider);
    await _run(() async {
      for (final (i, name) in names.indexed) {
        await service.createNode(
          label: name,
          typeIds: [SeedIds.person],
          x: at.x,
          y: at.y + 80.0 * i,
        );
      }
    });
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Added ${names.length} ${names.length == 1 ? 'bubble' : 'bubbles'}',
        ),
      ),
    );
  }

  Future<void> _run(Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      if (mounted) showGraphError(context, e);
    }
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
  void _fit({required bool animate}) =>
      _fitTo(_scene?.bounds, animate: animate);

  /// Zooms and pans so [bounds] (world) fills the screen, at most 1.5×.
  void _fitTo(Rectangle<double>? bounds, {required bool animate}) {
    final view = _viewSize;
    if (view == null || !mounted) return;
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
