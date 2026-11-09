import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/domain/hit_test.dart';
import 'package:people_bubble/ui/canvas/canvas_state.dart';
import 'package:people_bubble/ui/canvas/radial_wheel.dart';

import 'canvas_helpers.dart';

void main() {
  testWidgets('long-press a bubble, slide to Rename, lift: rename opens', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final finger = await longPress(tester, screenOf(tester, const Point(0, 0)));

    expect(find.byType(RadialWheel), findsOneWidget);
    expect(wheelOf(tester).title, 'Sam');
    expect(wheelOf(tester).items.map((i) => i.label), [
      'Add child',
      'Link',
      'Rename',
      'Types',
      'Delete',
      'More',
    ]);

    await finger.moveTo(slice(tester, 'Rename'));
    await tester.pump();
    expect(wheelOf(tester).hovered, (ring: 0, index: 2));
    await finger.up();
    await tester.pumpAndSettle();

    expect(find.byType(RadialWheel), findsNothing);
    await tester.enterText(find.byType(TextField), 'Samuel');
    await tester.tap(find.text('Save'));
    await app.settle();
    expect((await app.snapshot()).nodes[sam]!.label, 'Samuel');
  });

  testWidgets('lifting in the centre keeps the wheel open for a tap', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final finger = await longPress(tester, screenOf(tester, const Point(0, 0)));
    await finger.up();
    await tester.pumpAndSettle();
    expect(find.byType(RadialWheel), findsOneWidget);

    await tester.tapAt(slice(tester, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete “Sam”?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await app.settle();
    expect((await app.snapshot()).nodes.containsKey(sam), isFalse);
  });

  testWidgets('near an edge, lifting without sliding keeps it open', (
    tester,
  ) async {
    await openCanvas(tester);
    final view = tester.getRect(find.byType(InteractiveViewer));
    // Empty canvas hard against the right edge: the wheel is pushed inward,
    // so the finger is no longer over its centre.
    final at = Offset(view.right - 40, view.center.dy);
    final finger = await longPress(tester, at);
    final wheel = wheelOf(tester);
    expect(
      wheel.center.dx,
      lessThan(at.dx - tester.getTopLeft(find.byType(RadialWheel)).dx - 50),
    );
    await finger.moveBy(const Offset(-2, 0)); // a jitter, not a slide
    await tester.pump();
    await finger.up();
    await tester.pumpAndSettle();
    expect(find.byType(RadialWheel), findsOneWidget);
    expect(find.text('Add person'), findsNothing);
  });

  testWidgets('tapping outside closes the wheel without acting', (
    tester,
  ) async {
    await openCanvas(tester);
    final finger = await longPress(tester, screenOf(tester, const Point(0, 0)));
    await finger.up();
    await tester.pumpAndSettle();

    // A canvas corner: the wheel is always kept a radius away from edges.
    await tester.tapAt(
      tester.getTopLeft(find.byType(RadialWheel)) + const Offset(10, 10),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RadialWheel), findsNothing);
  });

  testWidgets('More opens an outer ring; Subtree then drags as a group', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final finger = await longPress(tester, screenOf(tester, const Point(0, 0)));
    await finger.moveTo(slice(tester, 'More'));
    await tester.pump();
    expect(wheelOf(tester).moreOpen, isTrue, reason: 'opens on hover');
    await finger.moveTo(slice(tester, 'Subtree'));
    await tester.pump();
    await finger.up();
    await tester.pumpAndSettle();

    final container = containerOf(tester);
    expect(container.read(canvasGroupProvider), {sam, sushi});

    final scale = transformOf(tester).getMaxScaleOnAxis();
    await tester.dragFrom(
      screenOf(tester, const Point(0, 300)), // grab Sushi
      const Offset(60, 0),
    );
    await app.settle();
    final s = await app.snapshot();
    expect(s.nodes[sam]!.x, closeTo(60 / scale, 1e-6), reason: 'moved too');
    expect(s.nodes[sushi]!.x, closeTo(60 / scale, 1e-6));
    expect(s.nodes.values.firstWhere((n) => n.label == 'Jazz').x, 600);
  });

  testWidgets('More → Style opens the bubble style sheet', (tester) async {
    await openCanvas(tester);
    final finger = await longPress(tester, screenOf(tester, const Point(0, 0)));
    await finger.up();
    await tester.pumpAndSettle();
    await tester.tapAt(slice(tester, 'More'));
    await tester.pumpAndSettle();
    await tester.tapAt(slice(tester, 'Style'));
    await tester.pumpAndSettle();
    expect(find.text('Style: Sam'), findsOneWidget);
    expect(find.text('Reset to type'), findsOneWidget);
  });

  testWidgets('line wheel: More → Reverse swaps the ends', (tester) async {
    final app = await openCanvas(tester);
    final finger = await longPress(
      tester,
      screenOf(tester, const Point(0, 150)),
    );
    expect(wheelOf(tester).title, 'Sam → Sushi');
    expect(containerOf(tester).read(canvasSelectionProvider), EdgeHit(line));
    await finger.up();
    await tester.pumpAndSettle();
    await tester.tapAt(slice(tester, 'More'));
    await tester.pumpAndSettle();
    await tester.tapAt(slice(tester, 'Reverse'));
    await app.settle();

    final edge = (await app.snapshot()).edges[line]!;
    expect((edge.sourceId, edge.targetId), (sushi, sam));
  });

  testWidgets('empty canvas: New here puts the bubble where you pressed', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final finger = await longPress(
      tester,
      screenOf(tester, const Point(300, 200)),
    );
    expect(wheelOf(tester).items.map((i) => i.label), [
      'New here',
      'Paste',
      'Fit',
    ]);
    await finger.up();
    await tester.pumpAndSettle();
    await tester.tapAt(slice(tester, 'New here'));
    await tester.pumpAndSettle();

    expect(find.text('Add person'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Zoe');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await app.settle();

    final zoe = (await app.snapshot()).nodes.values.firstWhere(
      (n) => n.label == 'Zoe',
    );
    expect(zoe.typeIds, [SeedIds.person]);
    expect(zoe.x, closeTo(300, 1));
    expect(zoe.y, closeTo(200, 1));
  });

  testWidgets('empty canvas: Paste makes a bubble per clipboard line', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? <String, Object?>{'text': 'Ana\n  \nBen Smith\n'}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final app = await openCanvas(tester);
    final finger = await longPress(
      tester,
      screenOf(tester, const Point(300, 200)),
    );
    await finger.up();
    await tester.pumpAndSettle();
    await tester.tapAt(slice(tester, 'Paste'));
    await app.settle();

    final labels = (await app.snapshot()).nodes.values.map((n) => n.label);
    expect(labels, containsAll(['Ana', 'Ben Smith']));
    expect(find.text('Added 2 bubbles'), findsOneWidget);
  });

  testWidgets('moving before the long-press time drags instead', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final finger = await tester.startGesture(
      screenOf(tester, const Point(0, 0)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await finger.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RadialWheel), findsNothing);
    await finger.up();
    await app.settle();
    expect((await app.snapshot()).nodes[sam]!.x, greaterThan(0));
  });
}
