import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui/harness.dart';

void main() {
  testWidgets('opens on the canvas and switches to the list', (tester) async {
    await AppHarness.start(tester);

    expect(find.text('No one here yet'), findsOneWidget);
    expect(find.text('Add your first person'), findsOneWidget);
    expect(find.text('Import a backup'), findsOneWidget);

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(find.text('Add your first person'), findsOneWidget);
  });

  testWidgets('the empty state adds a person', (tester) async {
    final app = await AppHarness.start(tester, startOnList: true);
    await tester.tap(find.text('Add your first person'));
    await app.settle();
    expect(find.byType(TextField), findsOneWidget, reason: 'the add sheet');
  });
}
