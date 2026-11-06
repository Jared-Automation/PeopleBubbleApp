import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/graph.dart';
import '../services/graph_service.dart';
import 'app_database.dart';
import 'graph_reader.dart';

/// The single [AppDatabase] for the app. Tests override this with an
/// in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The only way to change data.
final graphServiceProvider = Provider<GraphService>(
  (ref) => GraphService(ref.watch(databaseProvider)),
);

/// The whole graph, re-emitted after every change. Widgets that watch this
/// rebuild automatically, much like binding to an observable in WinUI.
final graphSnapshotProvider = StreamProvider<GraphSnapshot>(
  (ref) => GraphReader(ref.watch(databaseProvider)).watch(),
);
