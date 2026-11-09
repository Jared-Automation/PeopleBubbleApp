import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/app_database.dart';
import 'package:people_bubble/data/graph_reader.dart';
import 'package:people_bubble/data/providers.dart';
import 'package:people_bubble/domain/graph.dart';
import 'package:people_bubble/services/graph_service.dart';
import 'package:people_bubble/ui/app.dart';
import 'package:people_bubble/ui/list/list_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real app on an in-memory database, on a tall screen so most rows fit.
class AppHarness {
  AppHarness._(this.tester, this.db);

  final WidgetTester tester;
  final AppDatabase db;
  late final service = GraphService(db);

  static Future<AppHarness> start(
    WidgetTester tester, {
    Future<void> Function(GraphService service)? seed,
    bool startOnList = false,
  }) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final harness = AppHarness._(tester, db);
    addTearDown(() async {
      // Dispose the widgets (and their database streams) before closing.
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
    if (seed != null) await tester.runAsync(() => seed(harness.service));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // The app and the seed share one service, so one undo history.
          graphServiceProvider.overrideWithValue(harness.service),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const PeopleBubbleApp(),
      ),
    );
    await harness.settle();
    if (startOnList) {
      // The app opens on the canvas; list tests switch tabs first.
      await tester.tap(find.text('List'));
      await harness.settle();
    }
    return harness;
  }

  /// Lets real SQLite work finish (it runs outside the fake test clock), then
  /// rebuilds.
  Future<void> settle() async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<GraphSnapshot> snapshot() async =>
      (await tester.runAsync(() => GraphReader(db).load()))!;
}
