import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// drift generates `_$AppDatabase` into this file when you run
// `dart run build_runner build`.
part 'app_database.g.dart';

/// The app's SQLite database.
///
/// Tables are added in phase 2. Bump [schemaVersion] whenever a table changes
/// and add a step to [migration] so existing installs upgrade in place.
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or [executor] if given (tests pass an
  /// in-memory one).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'people_bubble'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());

  /// The schema version actually stored in the file (SQLite `user_version`).
  Future<int> storedSchemaVersion() async {
    final row = await customSelect('PRAGMA user_version').getSingle();
    return row.read<int>('user_version');
  }
}
