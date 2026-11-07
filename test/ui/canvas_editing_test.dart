import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/domain/hit_test.dart';
import 'package:people_bubble/ui/canvas/canvas_state.dart';

import 'canvas_helpers.dart';

void main() {
  testWidgets('tap selects a bubble or line; tapping empty space clears', (
    tester,
  ) async {
    await openCanvas(tester);
    final selection = containerOf(tester);

    await tapAt(tester, screenOf(tester, const Point(0, 0)), Duration.zero);
    expect(selection.read(canvasSelectionProvider), NodeHit(sam));

    await tapAt(
      tester,
      screenOf(tester, const Point(0, 150)),
      const Duration(seconds: 1),
    );
    expect(selection.read(canvasSelectionProvider), EdgeHit(line));

    await tapAt(
      tester,
      screenOf(tester, const Point(300, 200)),
      const Duration(seconds: 2),
    );
    expect(selection.read(canvasSelectionProvider), isNull);
  });

  testWidgets('dragging a bubble moves it and saves on release', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final before = transformOf(tester).clone();
    final scale = before.getMaxScaleOnAxis();

    final gesture = await tester.startGesture(
      screenOf(tester, const Point(0, 0)),
    );
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(70, 0));
    await tester.pump();
    // Nothing saved mid-drag.
    expect((await app.snapshot()).nodes[sam]!.x, 0);
    await gesture.up();
    await app.settle();

    final node = (await app.snapshot()).nodes[sam]!;
    expect(node.x, closeTo(100 / scale, 1e-6));
    expect(node.y, closeTo(0, 1e-6));
    expect(transformOf(tester), before, reason: 'the view did not pan');
  });

  testWidgets('dragging empty canvas pans instead of moving anything', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final before = transformOf(tester).getTranslation();

    await tester.dragFrom(
      screenOf(tester, const Point(300, 200)),
      const Offset(80, 40),
    );
    await app.settle();

    expect(transformOf(tester).getTranslation(), isNot(before));
    final s = await app.snapshot();
    expect((s.nodes[sam]!.x, s.nodes[sam]!.y), (0, 0));
  });

  testWidgets('a second finger turns a drag into a pinch; nothing moves', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    final first = await tester.startGesture(
      screenOf(tester, const Point(0, 0)),
    );
    await first.moveBy(const Offset(40, 0));
    final second = await tester.startGesture(
      screenOf(tester, const Point(300, 200)),
      pointer: 2,
    );
    await second.moveBy(const Offset(40, 40));
    await first.up();
    await second.up();
    await app.settle();

    final s = await app.snapshot();
    expect((s.nodes[sam]!.x, s.nodes[sam]!.y), (0, 0));
  });

  testWidgets('double-tap renames; two slow taps do not', (tester) async {
    final app = await openCanvas(tester);
    final at = screenOf(tester, const Point(0, 0));

    await tapAt(tester, at, Duration.zero);
    await tapAt(tester, at, const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsNothing);

    await tapAt(tester, at, const Duration(milliseconds: 1000));
    await tapAt(tester, at, const Duration(milliseconds: 1150));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Samantha');
    await tester.tap(find.text('Save'));
    await app.settle();

    expect((await app.snapshot()).nodes[sam]!.label, 'Samantha');
  });

  testWidgets('snap to grid (from the settings menu) rounds the drop point', (
    tester,
  ) async {
    final app = await openCanvas(tester);

    await tester.tap(find.byTooltip('Canvas settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snap to grid'));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(canvasSettingsProvider).snapToGrid, isTrue);

    await tester.dragFrom(
      screenOf(tester, const Point(0, 0)),
      const Offset(37, 23),
    );
    await app.settle();

    final node = (await app.snapshot()).nodes[sam]!;
    expect(node.x! % 40, 0);
    expect(node.y! % 40, 0);
  });

  testWidgets('a bubble added elsewhere is placed and panned into view', (
    tester,
  ) async {
    final app = await openCanvas(tester);
    // Pan Sam well off screen first.
    await tester.dragFrom(
      screenOf(tester, const Point(300, 200)),
      const Offset(-700, -900),
    );
    await app.settle();

    // As if added from the list.
    final added = await tester.runAsync(
      () => app.service.createChildNode(
        parentId: sam,
        label: 'Tacos',
        edgeTypeId: SeedIds.likes,
      ),
    );
    await app.settle();
    await tester.pump(const Duration(milliseconds: 500)); // placement delay
    await app.settle();

    final node = (await app.snapshot()).nodes[added!.nodeId]!;
    expect(node.isPlaced, isTrue);
    final at = screenOf(tester, Point(node.x!, node.y!));
    expect(tester.getRect(find.byType(InteractiveViewer)).contains(at), isTrue);
  });
}
