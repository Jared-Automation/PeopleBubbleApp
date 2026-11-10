import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/domain/hit_test.dart';
import 'package:people_bubble/domain/style.dart';
import 'package:people_bubble/ui/canvas/canvas_state.dart';
import 'package:people_bubble/ui/canvas/graph_painter.dart';

import 'canvas_helpers.dart';
import 'harness.dart';

GraphPainter painterOf(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((c) => c.painter)
    .whereType<GraphPainter>()
    .single;

final graphCanvas = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is GraphPainter,
);

/// The canvas helpers' Sam → Sushi, with Sam marked hidden.
Future<AppHarness> openWithSamHidden(WidgetTester tester) async {
  final app = await openCanvas(tester);
  await tester.runAsync(
    () => app.service.setNodeOverrides(sam, const NodeStyle(hidden: true)),
  );
  await app.settle();
  return app;
}

Future<void> toggleShowHidden(AppHarness app) async {
  await app.tester.tap(find.byTooltip('More').last);
  await app.tester.pumpAndSettle();
  await app.tester.tap(find.text('Show hidden'));
  await app.settle();
}

void main() {
  testWidgets('canvas: greys what is under a hidden bubble until selected', (
    tester,
  ) async {
    final app = await openWithSamHidden(tester);
    // Name the line, to check its label is hidden too.
    await tester.runAsync(
      () => app.service.updateEdge(line, typeId: SeedIds.likes, label: 'a lot'),
    );
    await app.settle();
    var p = painterOf(tester);
    expect(p.greyedNodes, {sushi});
    expect(p.greyedEdges, {line});
    expect(p.hiders, {sam});
    // Text drawn: Sam, Jazz and Sam's eye-off badge. Not Sushi, not the
    // line's label.
    expect(graphCanvas, paintsExactlyCountTimes(#drawParagraph, 3));

    // Selecting the hidden bubble reveals its group…
    containerOf(tester)
        .read(canvasSelectionProvider.notifier)
        .select(NodeHit(sam));
    await tester.pump();
    expect(painterOf(tester).greyedNodes, isEmpty);
    expect(graphCanvas, paintsExactlyCountTimes(#drawParagraph, 5));

    // …and so does selecting something in it.
    containerOf(tester)
        .read(canvasSelectionProvider.notifier)
        .select(NodeHit(sushi));
    await tester.pump();
    expect(painterOf(tester).greyedNodes, isEmpty);

    containerOf(tester).read(canvasSelectionProvider.notifier).select(null);
    await tester.pump();
    expect(painterOf(tester).greyedNodes, {sushi});

    await toggleShowHidden(app);
    p = painterOf(tester);
    expect(p.greyedNodes, isEmpty);
    expect(p.hiders, {sam}, reason: 'the badge stays');
  });

  testWidgets('list: rows under a hidden bubble are faded with a badge', (
    tester,
  ) async {
    final app = await openWithSamHidden(tester);
    await tester.tap(find.text('List'));
    await app.settle();

    double opacityOf(String label) => tester
        .widget<Opacity>(
          find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
        )
        .opacity;

    // Faded, and the name can't be read.
    expect(find.text('Sushi'), findsNothing);
    expect(find.byTooltip('Add under Sushi'), findsNothing);
    expect(opacityOf('•••'), 0.3);
    expect(opacityOf('Sam'), 1);
    expect(find.byTooltip('What’s under this is hidden'), findsOneWidget);

    await toggleShowHidden(app);
    expect(find.text('•••'), findsNothing);
    expect(opacityOf('Sushi'), 1);
  });

  testWidgets('the bubble style sheet has the Hide switch', (tester) async {
    final app = await openCanvas(tester);
    await tester.tap(find.text('List'));
    await app.settle();
    await tester.drag(find.text('Sam'), const Offset(300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await app.settle();
    await tester.tap(find.text('Bubble style…'));
    await app.settle();

    final toggle = find.descendant(
      of: find.byKey(const ValueKey('field-hidden')),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await app.settle();

    final s = await app.snapshot();
    expect(s.nodes[sam]!.overrides, const NodeStyle(hidden: true));
  });
}
