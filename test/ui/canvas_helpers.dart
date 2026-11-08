import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/domain/radial_menu.dart';
import 'package:people_bubble/ui/canvas/canvas_screen.dart';
import 'package:people_bubble/ui/canvas/radial_wheel.dart';

import 'harness.dart';

/// Sam at (0, 0) with Sushi below at (0, 300); Jazz far right at (600, 0).
late String sam, sushi, line;

Future<AppHarness> openCanvas(WidgetTester tester) async {
  final app = await AppHarness.start(
    tester,
    seed: (g) async {
      sam = await g.createNode(
        label: 'Sam',
        typeIds: [SeedIds.person],
        x: 0,
        y: 0,
      );
      sushi = await g.createNode(
        label: 'Sushi',
        typeIds: [SeedIds.thing],
        x: 0,
        y: 300,
      );
      await g.createNode(label: 'Jazz', x: 600, y: 0);
      line = await g.createEdge(
        sourceId: sam,
        targetId: sushi,
        typeId: SeedIds.likes,
      );
    },
  );
  await app.settle();
  return app;
}

Matrix4 transformOf(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value;

/// Where world point [p] is on the test screen.
Offset screenOf(WidgetTester tester, Point<double> p) =>
    tester.getTopLeft(find.byType(InteractiveViewer)) +
    MatrixUtils.transformPoint(
      transformOf(tester),
      Offset(p.x + 100000, p.y + 100000),
    );

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(CanvasScreen)));

Future<void> tapAt(WidgetTester tester, Offset at, Duration time) async {
  final gesture = await tester.createGesture();
  await gesture.down(at, timeStamp: time);
  await gesture.up(timeStamp: time + const Duration(milliseconds: 40));
  await tester.pump();
}

/// Long-presses at [at] and leaves the finger down; returns the gesture.
Future<TestGesture> longPress(WidgetTester tester, Offset at) async {
  final gesture = await tester.startGesture(at);
  await tester.pump(const Duration(milliseconds: 500));
  return gesture;
}

RadialWheel wheelOf(WidgetTester tester) =>
    tester.widget<RadialWheel>(find.byType(RadialWheel));

/// Screen position of the slice labelled [label] (main or More ring).
Offset slice(WidgetTester tester, String label) {
  final wheel = wheelOf(tester);
  final origin = tester.getTopLeft(find.byType(RadialWheel));
  const g = RadialGeometry();
  final inner = wheel.items.indexWhere((i) => i.label == label);
  double angle, radius;
  if (inner >= 0) {
    angle = RadialGeometry.sliceCenter(inner, wheel.items.length);
    radius = (g.deadZone + g.innerRadius) / 2;
  } else {
    final more = wheel.items.indexWhere((i) => i.isMore);
    final outer = wheel.items[more].more!;
    final index = outer.indexWhere((i) => i.label == label);
    expect(index, isNonNegative, reason: 'no slice "$label"');
    angle = RadialGeometry.outerCenter(
      index,
      outerCount: outer.length,
      moreIndex: more,
      innerCount: wheel.items.length,
    );
    radius = (g.innerRadius + g.outerRadius) / 2;
  }
  return origin +
      wheel.center +
      Offset(radius * cos(angle), radius * sin(angle));
}
