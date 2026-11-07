import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/ui/canvas/canvas_screen.dart';

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
