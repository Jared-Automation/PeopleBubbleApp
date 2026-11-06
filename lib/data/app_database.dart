import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/style.dart';
import 'app_database.steps.dart';
import 'seed.dart';
import 'tables.dart';

export 'tables.dart';

// drift generates `_$AppDatabase` and the row classes into this file when you
// run `dart run build_runner build`.
part 'app_database.g.dart';

/// The app's SQLite database.
///
/// To change the schema: edit `tables.dart`, bump [schemaVersion], run
/// `dart run drift_dev make-migrations`, then add the new `fromXToY` step to
/// [migration]. That command also snapshots the schema and writes a test.
@DriftDatabase(
  tables: [
    NodeTypes,
    EdgeTypes,
    Nodes,
    NodeTypeLinks,
    Edges,
    Waypoints,
    EdgeWaypoints,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or [executor] if given (tests pass an
  /// in-memory one).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'people_bubble'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // v1 (Phase 1) had no tables.
      from1To2: (m, schema) async {
        await m.createTable(schema.nodeTypes);
        await m.createTable(schema.edgeTypes);
        await m.createTable(schema.nodes);
        await m.createTable(schema.nodeTypeLinks);
        await m.createTable(schema.edges);
        await m.createTable(schema.waypoints);
        await m.createTable(schema.edgeWaypoints);
      },
    ),
    beforeOpen: (details) async {
      // SQLite leaves foreign keys (and so cascading deletes) off by default.
      await customStatement('PRAGMA foreign_keys = ON');
      final before = details.versionBefore;
      if (before == null || before < 2) await insertSeedTypes(this);
    },
  );

  /// The schema version actually stored in the file (SQLite `user_version`).
  Future<int> storedSchemaVersion() async {
    final row = await customSelect('PRAGMA user_version').getSingle();
    return row.read<int>('user_version');
  }
}
