import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/domain/style.dart';
import 'package:people_bubble/services/sample_data.dart';

import 'harness.dart';

void main() {
  testWidgets('shows people first, with line chips and shared markers', (
    tester,
  ) async {
    await AppHarness.start(tester, startOnList: true, seed: loadSampleData);

    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    // Alex is the first person A–Z; Hiking hangs under Alex via "loves".
    expect(labels.indexOf('Alex'), lessThan(labels.indexOf('Hiking')));
    expect(find.text('loves'), findsWidgets);
    // Sushi is under Sam and Priya → link marker.
    expect(find.byTooltip('Also under 1 more'), findsWidgets);
  });

  testWidgets('adds a quick run of likes without closing the sheet', (
    tester,
  ) async {
    final app = await AppHarness.start(
      tester,
      startOnList: true,
      seed: (g) => g.createNode(label: 'Sam', typeIds: [SeedIds.person]),
    );

    await tester.tap(find.byTooltip('Add under Sam'));
    await tester.pumpAndSettle();
    expect(find.text('Add under Sam'), findsOneWidget);

    for (final food in ['Tacos', 'Ramen']) {
      await tester.enterText(find.widgetWithText(TextField, 'Name'), food);
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await app.settle();
      expect(find.text('Added “$food”'), findsOneWidget);
    }
    await tester.tap(find.text('Done'));
    await app.settle();

    final s = await app.snapshot();
    final sam = s.nodes.values.firstWhere((n) => n.label == 'Sam');
    final children = [
      for (final e in s.edges.values)
        if (e.sourceId == sam.id) (s.nodes[e.targetId]!.label, e.typeId),
    ];
    expect(
      children,
      unorderedEquals([('Tacos', SeedIds.likes), ('Ramen', SeedIds.likes)]),
    );
    expect(find.text('Tacos'), findsOneWidget, reason: 'shown in the list');
  });

  testWidgets('greys out a conflicting type with the reason', (tester) async {
    await AppHarness.start(
      tester,
      startOnList: true,
      seed: (g) async {
        await g.createNodeType(
          name: 'Partner',
          parentId: SeedIds.person,
          style: const NodeStyle(outlineColor: 0xFFE91E63),
        );
        await g.createNodeType(
          name: 'Friend',
          parentId: SeedIds.person,
          style: const NodeStyle(outlineColor: 0xFF1E88E5),
        );
      },
    );

    await tester.tap(find.text('Add person'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Partner'));
    await tester.pumpAndSettle();

    final friend = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Friend'),
    );
    expect(friend.onSelected, isNull, reason: 'disabled');
    expect(
      find.text(
        "Friend can't be combined with Partner (both set outline color).",
      ),
      findsOneWidget,
    );
  });

  testWidgets('add sheet fits a phone screen with the keyboard open', (
    tester,
  ) async {
    await AppHarness.start(tester, startOnList: true, seed: loadSampleData);
    // Galaxy S24-ish: 1080x2340 px at 2.625x, keyboard ~ 40% of the height.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    tester.view.viewInsets = const FakeViewPadding(bottom: 950);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add under Alex'));
    await tester.pumpAndSettle();
    // Any overflow would have failed the test by now; check the content.
    expect(find.text('Add under Alex'), findsOneWidget);
    await tester.tap(find.text('Existing'));
    await tester.pumpAndSettle();
    expect(find.text('Search bubbles'), findsOneWidget);
  });
}
