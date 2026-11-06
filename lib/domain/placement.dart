/// Auto-placement: where a new bubble goes on the canvas.
///
/// - With parents: near the parent (or the average of its parents), fanning
///   away from the grandparent, on rings of candidate points.
/// - Without parents: the first spot in a spiral out from the screen centre
///   that is well clear of everything; failing that, just outside it all.
/// - Never fully covering an existing bubble.
library;

import 'dart:math';

import 'geometry.dart';
import 'graph.dart';

class Placer {
  const Placer({
    this.padding = 16,
    this.angleStepDegrees = 20,
    this.rings = 4,
    this.ringGrowth = 0.6,
  });

  /// Gap kept around existing boxes when measuring overlap.
  final double padding;
  final double angleStepDegrees;

  /// Rings tried before settling for the least-bad overlapping spot.
  final int rings;

  /// Each ring is this fraction of the first ring's radius further out.
  final double ringGrowth;

  /// Default direction for a first child with no grandparent: straight down.
  static const _down = pi / 2;

  /// Places a child of the bubbles at [parentCenters].
  ///
  /// [grandparentCenters] (the parents' own parents) set the preferred
  /// direction: away from them, so trees fan outward. For a root parent,
  /// [siblingCenters] (its other children) are used instead: the middle of the
  /// widest gap between them.
  Point<double> placeChild({
    required List<Point<double>> parentCenters,
    required BoxSize parentSize,
    required BoxSize size,
    required List<Rectangle<double>> obstacles,
    List<Point<double>> grandparentCenters = const [],
    List<Point<double>> siblingCenters = const [],
  }) {
    final anchor = _average(parentCenters);
    final preferred = _preferredAngle(
      anchor,
      grandparentCenters,
      siblingCenters,
    );
    final firstRadius = _radius(parentSize) + 1.5 * _radius(size);
    final padded = [for (final o in obstacles) inflate(o, padding)];
    final step = angleStepDegrees * pi / 180;
    final offsets = <double>[0];
    for (var k = 1; k * step < pi - 1e-9; k++) {
      offsets
        ..add(k * step)
        ..add(-k * step);
    }
    if ((pi / step - (pi / step).round()).abs() < 1e-9) offsets.add(pi);

    Point<double>? best;
    var bestScore = double.infinity;
    // Keep looking past [rings] only if every spot so far fully covers
    // something; give up after a generous number of rings.
    for (var ring = 0; ring < rings * 4; ring++) {
      final radius = firstRadius * (1 + ringGrowth * ring);
      for (final offset in offsets) {
        final angle = preferred + offset;
        final p = Point(
          anchor.x + radius * cos(angle),
          anchor.y + radius * sin(angle),
        );
        final box = boxAt(p, size);
        if (_coversAny(box, obstacles)) continue;
        final overlap = padded.fold(0.0, (sum, o) => sum + overlapArea(box, o));
        if (overlap == 0) return p;
        final score =
            overlap + 0.5 * (radius - firstRadius) + 40 * offset.abs();
        if (score < bestScore) (best, bestScore) = (p, score);
      }
      if (ring + 1 >= rings && best != null) return best;
    }
    return best ?? Point(anchor.x, anchor.y + firstRadius);
  }

  /// Places a bubble with no parent: the first point on a spiral out from
  /// [searchCenter], inside [searchArea], at least three bubble-widths from
  /// every other bubble. If there's no such spot, just outside everything.
  Point<double> placeRoot({
    required Point<double> searchCenter,
    required Rectangle<double> searchArea,
    required BoxSize size,
    required List<Rectangle<double>> obstacles,
  }) {
    if (obstacles.isEmpty) return searchCenter;
    final clearance = 3 * size.width;
    final spacing = size.width / 2;
    final maxRadius = [
      searchArea.topLeft,
      searchArea.topRight,
      searchArea.bottomLeft,
      searchArea.bottomRight,
    ].map((corner) => corner.distanceTo(searchCenter)).reduce(max);

    var theta = 0.0;
    while (true) {
      final r = spacing * theta / (2 * pi);
      if (r > maxRadius) break;
      final p = Point(
        searchCenter.x + r * cos(theta),
        searchCenter.y + r * sin(theta),
      );
      if (searchArea.containsPoint(p)) {
        final box = boxAt(p, size);
        if (obstacles.every((o) => gapBetween(box, o) >= clearance)) return p;
      }
      // Roughly constant arc length between samples.
      theta += spacing / max(r, spacing);
    }

    final bounds = boundsOf(obstacles)!;
    return Point(
      bounds.right + size.width + size.width / 2,
      bounds.top + bounds.height / 2,
    );
  }

  double _preferredAngle(
    Point<double> anchor,
    List<Point<double>> grandparents,
    List<Point<double>> siblings,
  ) {
    if (grandparents.isNotEmpty) {
      final g = _average(grandparents);
      if (g != anchor) return atan2(anchor.y - g.y, anchor.x - g.x);
    }
    final angles = [
      for (final s in siblings)
        if (s != anchor) atan2(s.y - anchor.y, s.x - anchor.x),
    ]..sort();
    if (angles.isEmpty) return _down;
    if (angles.length == 1) return angles.single + pi;
    var bestGap = 0.0, bestMid = _down;
    for (var i = 0; i < angles.length; i++) {
      final from = angles[i];
      final to = i + 1 < angles.length ? angles[i + 1] : angles[0] + 2 * pi;
      if (to - from > bestGap) {
        (bestGap, bestMid) = (to - from, (from + to) / 2);
      }
    }
    return bestMid;
  }

  static double _radius(BoxSize s) => max(s.width, s.height) / 2;

  static Point<double> _average(List<Point<double>> points) {
    var x = 0.0, y = 0.0;
    for (final p in points) {
      x += p.x;
      y += p.y;
    }
    return Point(x / points.length, y / points.length);
  }

  /// [box] would completely hide an existing bubble, or be hidden by one.
  static bool _coversAny(
    Rectangle<double> box,
    List<Rectangle<double>> obstacles,
  ) => obstacles.any(
    (o) => box.containsRectangle(o) || o.containsRectangle(box),
  );
}

/// Positions for every unplaced node in [snapshot], placed one at a time so
/// each sees the ones before it. Roots go first (A–Z); then each child is
/// placed once *all* its parents have positions, so a shared thing lands near
/// the average of everyone who has it. Already-placed nodes stay put.
Map<String, Point<double>> placeUnplaced(
  GraphSnapshot snapshot, {
  required BoxSize Function(GraphNode node) sizeOf,
  required Point<double> viewCenter,
  Placer placer = const Placer(),
}) {
  final centers = <String, Point<double>>{
    for (final n in snapshot.nodes.values)
      if (n.isPlaced) n.id: Point(n.x!, n.y!),
  };
  final unplaced = snapshot.nodes.length - centers.length;
  if (unplaced == 0) return const {};

  final childrenOf = <String, List<String>>{};
  final parentsOf = <String, List<String>>{};
  for (final e in snapshot.hierarchicalEdges) {
    (childrenOf[e.sourceId] ??= []).add(e.targetId);
    (parentsOf[e.targetId] ??= []).add(e.sourceId);
  }
  int byLabel(String a, String b) => snapshot.nodes[a]!.label
      .toLowerCase()
      .compareTo(snapshot.nodes[b]!.label.toLowerCase());
  for (final list in childrenOf.values) {
    list.sort(byLabel);
  }

  final obstacles = [
    for (final MapEntry(key: id, value: c) in centers.entries)
      boxAt(c, sizeOf(snapshot.nodes[id]!)),
  ];
  // Room for the roots to spread out around the view centre.
  final side = max(1500.0, 600 * sqrt(unplaced.toDouble()));
  final searchArea = Rectangle(
    viewCenter.x - side / 2,
    viewCenter.y - side / 2,
    side,
    side,
  );
  final placed = <String, Point<double>>{};

  void put(String id, Point<double> p) {
    centers[id] = p;
    placed[id] = p;
    obstacles.add(boxAt(p, sizeOf(snapshot.nodes[id]!)));
  }

  Point<double>? center(String id) => centers[id];

  final roots = snapshot.roots.map((n) => n.id).toList()..sort(byLabel);
  // Nodes stuck inside a loop (bad import) have no root; treat as roots.
  final reachable = <String>{};
  void mark(String id) {
    if (!reachable.add(id)) return;
    for (final c in childrenOf[id] ?? const <String>[]) {
      mark(c);
    }
  }

  roots.forEach(mark);
  final stranded =
      snapshot.nodes.keys.where((id) => !reachable.contains(id)).toList()
        ..sort(byLabel);

  void placeAsRoot(String id) => put(
    id,
    placer.placeRoot(
      searchCenter: viewCenter,
      searchArea: searchArea,
      size: sizeOf(snapshot.nodes[id]!),
      obstacles: obstacles,
    ),
  );

  void placeAsChild(String child, String via) {
    final parents = [
      for (final p in parentsOf[child] ?? const <String>[])
        if (center(p) != null) p,
    ];
    if (parents.isEmpty) return placeAsRoot(child);
    put(
      child,
      placer.placeChild(
        parentCenters: [for (final p in parents) center(p)!],
        parentSize: sizeOf(snapshot.nodes[via]!),
        size: sizeOf(snapshot.nodes[child]!),
        obstacles: obstacles,
        grandparentCenters: [
          for (final p in parents)
            for (final g in parentsOf[p] ?? const <String>[])
              if (center(g) != null) center(g)!,
        ],
        siblingCenters: [
          for (final s in childrenOf[via] ?? const <String>[])
            if (s != child && center(s) != null) center(s)!,
        ],
      ),
    );
  }

  // 1. Roots, so every person has a spot before any of their things.
  for (final root in roots) {
    if (center(root) == null) placeAsRoot(root);
  }

  // 2. Children in topological order (Kahn's algorithm): a child is placed
  //    when its last parent has been.
  final waitingOn = {
    for (final MapEntry(key: child, value: parents) in parentsOf.entries)
      child: parents.length,
  };
  final done = <String>{};
  final queue = [...roots];
  while (queue.isNotEmpty) {
    final parent = queue.removeAt(0);
    if (!done.add(parent)) continue;
    for (final child in childrenOf[parent] ?? const <String>[]) {
      final left = waitingOn[child] = waitingOn[child]! - 1;
      if (left > 0) continue;
      if (center(child) == null) placeAsChild(child, parent);
      queue.add(child);
    }
  }

  // 3. Anything left is in, or hangs below, a loop (bad import): place it
  //    next to whichever parents have positions, or as a root.
  final allIds = snapshot.nodes.keys.toList()..sort(byLabel);
  for (final id in [...stranded, ...allIds]) {
    if (center(id) == null) {
      final via = (parentsOf[id] ?? const <String>[]).where(
        (p) => center(p) != null,
      );
      via.isEmpty ? placeAsRoot(id) : placeAsChild(id, via.first);
    }
  }
  return placed;
}
