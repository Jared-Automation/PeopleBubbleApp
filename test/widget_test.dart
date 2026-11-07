import 'package:flutter_test/flutter_test.dart';

import 'ui/harness.dart';

void main() {
  testWidgets('opens on the canvas and switches to the list', (tester) async {
    await AppHarness.start(tester);

    expect(
      find.text('Nothing here yet. Add people from the List.'),
      findsOneWidget,
    );

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(find.text('Add your first person'), findsOneWidget);
  });
}
