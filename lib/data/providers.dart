import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The single [AppDatabase] for the app. Tests override this with an
/// in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The schema version stored on disk; shown on the placeholder screens to
/// prove the database opens.
final storedSchemaVersionProvider = FutureProvider<int>(
  (ref) => ref.watch(databaseProvider).storedSchemaVersion(),
);
