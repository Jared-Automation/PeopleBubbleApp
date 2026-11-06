import 'package:flutter_test/flutter_test.dart';

import 'ui/harness.dart';

void main() {
  testWidgets('starts empty and switches views', (tester) async {
    await AppHarness.start(tester);

    expect(find.text('Add your first person'), findsOneWidget);

    await tester.tap(find.text('Bubbles'));
    await tester.pumpAndSettle();
    expect(find.text('Bubble canvas coming in phase 4'), findsOneWidget);
  });
}
