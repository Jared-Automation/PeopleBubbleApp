import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/domain/hit_test.dart';
import 'package:people_bubble/ui/canvas/canvas_state.dart';
import 'package:people_bubble/ui/canvas/graph_painter.dart';
import 'package:people_bubble/ui/canvas/radial_wheel.dart';
import 'package:people_bubble/ui/canvas/waypoint_painter.dart';

import 'canvas_helpers.dart';
import 'harness.dart';

void select(WidgetTester tester, CanvasHit hit) =>
    containerOf(tester).read(canvasSelectionProvider.notifier).select(hit);

Future<String> addWaypoint(
  AppHarness app,
  String edgeId,
  Point<double> at,
) async {
  final id = await app.tester.runAsync(
    () => app.service.addWaypoint(edgeId, index: 99, at: at),
  );
  await app.settle();
  return id!;
}

GraphPainter painterOf(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((c) => c.painter)
    .whereType<GraphPainter>()
    .single;

WaypointPainter overlayOf(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((c) => c.painter)
    .whereType<WaypointPainter>()
    .single;

void main() {
  testWidgets('dragging a line that is not selected pans; nothing bends', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final before = transformOf(tester).getTranslation();
    await tester.dragFrom(
      screenOf(tester, const Point(0, 150)),
      const Offset(80, 0),
    );
    await app.settle();
    expect(transformOf(tester).getTranslation(), isNot(before));
    expect((await app.snapshot()).edges[line]!.waypointIds, isEmpty);
  });

  testWidgets('dragging the selected line bends it through a new waypoint', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    select(tester, EdgeHit(line));
    await tester.pump();
    final scale = transformOf(tester).getMaxScaleOnAxis();
    final before = transformOf(tester).clone();

    await tester.dragFrom(
      screenOf(tester, const Point(0, 150)),
      const Offset(90, 0),
    );
    await app.settle();

    final s = await app.snapshot();
    final w = s.waypoints[s.edges[line]!.waypointIds.single]!;
    expect(w.x, closeTo(90 / scale, 1e-6));
    expect(w.y, closeTo(150, 1e-6));
    expect(transformOf(tester), before, reason: 'the view did not pan');
  });

  testWidgets('a waypoint handle drags the waypoint', (tester) async {
    final app = await openCanvas(tester);
    final w = await addWaypoint(app, line, const Point(100, 150));
    select(tester, EdgeHit(line));
    await tester.pump();
    final scale = transformOf(tester).getMaxScaleOnAxis();

    await tester.dragFrom(
      screenOf(tester, const Point(100, 150)),
      const Offset(0, 60),
    );
    await app.settle();

    final p = (await app.snapshot()).waypoints[w]!;
    expect(p.x, 100);
    expect(p.y, closeTo(150 + 60 / scale, 1e-6));
  });

  testWidgets('dropping a waypoint on another clamps the two lines', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final jazz = (await app.snapshot()).nodes.values
        .firstWhere((n) => n.label == 'Jazz')
        .id;
    final other = await tester.runAsync(
      () => app.service.createEdge(
        sourceId: sam,
        targetId: jazz,
        typeId: SeedIds.likes,
      ),
    );
    final mine = await addWaypoint(app, line, const Point(100, 150));
    final theirs = await addWaypoint(app, other!, const Point(300, 100));
    select(tester, EdgeHit(line));
    await tester.pump();

    final from = screenOf(tester, const Point(100, 150));
    final to = screenOf(tester, const Point(305, 102)); // near enough
    final finger = await tester.startGesture(from);
    await finger.moveTo(from + const Offset(20, 0));
    await finger.moveTo(to);
    await tester.pump();
    expect(overlayOf(tester).mergeTarget, theirs, reason: 'target shows');
    await finger.up();
    await app.settle();

    final s = await app.snapshot();
    expect(s.edges[line]!.waypointIds, [theirs]);
    expect(s.edges[other]!.waypointIds, [theirs]);
    expect(s.waypoints.containsKey(mine), isFalse);
    expect(
      containerOf(tester).read(canvasSelectionProvider),
      WaypointHit(theirs),
    );
  });

  testWidgets('waypoint wheel: Unclamp splits a shared waypoint', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final jazz = (await app.snapshot()).nodes.values
        .firstWhere((n) => n.label == 'Jazz')
        .id;
    final other = await tester.runAsync(
      () => app.service.createEdge(
        sourceId: sam,
        targetId: jazz,
        typeId: SeedIds.likes,
      ),
    );
    final shared = await addWaypoint(app, line, const Point(200, 200));
    final copy = await addWaypoint(app, other!, const Point(0, 0));
    await tester.runAsync(() => app.service.mergeWaypoints(copy, shared));
    await app.settle();

    // A shared waypoint shows (and can be grabbed) without selecting first.
    final finger = await longPress(
      tester,
      screenOf(tester, const Point(200, 200)),
    );
    expect(wheelOf(tester).title, 'Clamp');
    expect(wheelOf(tester).items.map((i) => i.label), ['Unclamp', 'Delete']);
    await finger.up();
    await tester.pumpAndSettle();
    await tester.tapAt(slice(tester, 'Unclamp'));
    await app.settle();

    final s = await app.snapshot();
    expect(
      s.edges[line]!.waypointIds.single,
      isNot(s.edges[other]!.waypointIds.single),
    );
  });

  testWidgets('waypoint wheel: Unclamp is greyed out on a lone waypoint', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final w = await addWaypoint(app, line, const Point(100, 150));
    select(tester, WaypointHit(w));
    await tester.pump();
    final finger = await longPress(
      tester,
      screenOf(tester, const Point(100, 150)),
    );
    expect(wheelOf(tester).title, 'Waypoint');
    final unclamp = wheelOf(tester).items.first;
    expect(unclamp.onSelected, isNull);
    await finger.up();
    await tester.pumpAndSettle();

    await tester.tapAt(slice(tester, 'Delete'));
    await app.settle();
    final s = await app.snapshot();
    expect(s.edges[line]!.waypointIds, isEmpty);
    expect(s.waypoints, isEmpty);
  });

  testWidgets('line wheel: Waypoint bends the line where you pressed', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final finger = await longPress(
      tester,
      screenOf(tester, const Point(0, 150)),
    );
    expect(wheelOf(tester).items[2].label, 'Waypoint');
    await finger.up();
    await tester.pumpAndSettle();
    await tester.tapAt(slice(tester, 'Waypoint'));
    await app.settle();

    final s = await app.snapshot();
    final w = s.waypoints[s.edges[line]!.waypointIds.single]!;
    expect(w.x, closeTo(0, 1));
    expect(w.y, closeTo(150, 1));
  });

  testWidgets('a dragged group carries the waypoints of its inner lines', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final w = await addWaypoint(app, line, const Point(100, 150));
    containerOf(tester).read(canvasGroupProvider.notifier).set({sam, sushi});
    await tester.pump();
    final scale = transformOf(tester).getMaxScaleOnAxis();

    await tester.dragFrom(
      screenOf(tester, const Point(0, 0)),
      const Offset(50, 0),
    );
    await app.settle();

    final p = (await app.snapshot()).waypoints[w]!;
    expect(p.x, closeTo(100 + 50 / scale, 1e-6));
  });

  testWidgets('a single dragged bubble leaves waypoints alone', (tester) async {
    final app = await openCanvas(tester);
    final w = await addWaypoint(app, line, const Point(100, 150));
    await tester.dragFrom(
      screenOf(tester, const Point(0, 0)),
      const Offset(50, 0),
    );
    await app.settle();
    expect((await app.snapshot()).waypoints[w]!.x, 100);
  });

  testWidgets('Smooth lines (settings menu) curves lines through waypoints', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    await addWaypoint(app, line, const Point(100, 150));
    final straight = painterOf(tester).scene.edges.single;
    expect(straight.path, straight.corners);

    await tester.tap(find.byTooltip('Canvas settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smooth lines'));
    await tester.pumpAndSettle();

    final curved = painterOf(tester).scene.edges.single;
    expect(curved.path.length, greaterThan(curved.corners.length));
    expect(find.byType(RadialWheel), findsNothing);
  });
}
