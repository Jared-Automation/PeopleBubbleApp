import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/app_database.dart';
import 'package:people_bubble/data/providers.dart';
import 'package:people_bubble/ui/app.dart';

void main() {
  testWidgets('shows the seeded database and switches views', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const PeopleBubbleApp(),
      ),
    );
    // Real SQLite work happens outside the fake test clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.textContaining('No bubbles yet'), findsOneWidget);
    expect(
      find.textContaining('3 bubble types · 5 line types'),
      findsOneWidget,
    );

    await tester.tap(find.text('Bubbles'));
    await tester.pumpAndSettle();
    expect(find.text('Bubble canvas coming in phase 4'), findsOneWidget);

    // Dispose the stream before the database closes.
    await tester.pumpWidget(const SizedBox());
  });
}
