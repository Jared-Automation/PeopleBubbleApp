import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';

import 'harness.dart';

void main() {
  testWidgets('the app bar undoes and redoes, naming the step', (tester) async {
    final app = await AppHarness.start(
      tester,
      startOnList: true,
      seed: (g) => g.createNode(label: 'Sam', typeIds: [SeedIds.person]),
    );
    expect(find.text('Sam'), findsOneWidget);
    expect(find.byTooltip('Redo'), findsWidgets, reason: 'nothing to redo');

    await tester.tap(find.byTooltip('Undo: add “Sam”').last);
    await app.settle();
    expect(find.text('Sam'), findsNothing);
    expect(find.text('Undid add “Sam”'), findsOneWidget);

    await tester.tap(find.byTooltip('Redo: add “Sam”').last);
    await app.settle();
    expect(find.text('Sam'), findsOneWidget);
  });

  testWidgets('deleting from the list offers Undo', (tester) async {
    final app = await AppHarness.start(
      tester,
      startOnList: true,
      seed: (g) => g.createNode(label: 'Sam', typeIds: [SeedIds.person]),
    );
    // Swipe left for Delete, then confirm.
    await tester.drag(find.text('Sam'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await app.settle();
    expect(find.text('Sam'), findsNothing);
    expect(find.text('Deleted “Sam”'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await app.settle();
    expect(find.text('Sam'), findsOneWidget);
  });
}
