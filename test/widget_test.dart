import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/app_database.dart';
import 'package:people_bubble/data/providers.dart';
import 'package:people_bubble/ui/app.dart';

void main() {
  testWidgets('opens the database and switches between views', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const PeopleBubbleApp(),
      ),
    );
    // Real SQLite work happens outside the fake test clock.
    await tester.runAsync(() => db.storedSchemaVersion());
    await tester.pumpAndSettle();

    expect(find.text('Database ready (schema v1)'), findsOneWidget);

    await tester.tap(find.text('Bubbles'));
    await tester.pumpAndSettle();
    expect(find.text('Bubble canvas coming in phase 4'), findsOneWidget);
  });
}
