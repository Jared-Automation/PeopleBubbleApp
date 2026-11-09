import 'dart:convert';

import 'package:drift/drift.dart' show DriftSqlType;

import 'app_database.dart';
import 'graph_dump.dart';

/// Backup files: one JSON object holding every table, plus the schema
/// version. Export writes it; import reads it, checks every row, and works
/// out the rows the database should end up with ("Replace" or "Merge").
///
/// Everything here works on [GraphDump]s (plain maps), so it needs no
/// database and is unit-tested directly.

const backupApp = 'people_bubble';

/// Bumped if the file layout itself changes (not the tables).
const backupFormat = 1;

/// A backup that can't be read at all. [message] is for the user.
class BackupRejected implements Exception {
  const BackupRejected(this.message);

  final String message;

  @override
  String toString() => 'BackupRejected: $message';
}

/// One column as the import checker sees it.
/// [type] is null for custom column types (checked as text).
typedef BackupColumn = ({DriftSqlType<Object>? type, bool nullable});

/// Table → column name → column, read from the drift schema so it can never
/// fall out of step with `tables.dart`.
typedef BackupSchema = Map<String, Map<String, BackupColumn>>;

BackupSchema backupSchemaOf(AppDatabase db) => {
  for (final t in db.allTables)
    t.actualTableName: {
      for (final c in t.$columns)
        c.name: (
          type: c.type is DriftSqlType<Object>
              ? c.type as DriftSqlType<Object>
              : null,
          nullable: c.$nullable,
        ),
    },
};

/// Defaults for columns a file may leave out (they have SQL defaults).
const _columnDefaults = <String, Object>{'style': '{}', 'built_in': 0};

// ---------------------------------------------------------------- export

/// The backup file for [dump], as pretty-printed JSON.
String encodeBackup(
  GraphDump dump, {
  required int schemaVersion,
  DateTime? exportedAt,
}) {
  return const JsonEncoder.withIndent(' ').convert({
    'app': backupApp,
    'format': backupFormat,
    'schemaVersion': schemaVersion,
    'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
    'tables': {
      for (final t in dumpTables)
        t.name: [
          for (final row in dump[t.name].values)
            {
              for (final MapEntry(:key, :value) in row.entries)
                key: t.jsonColumns.contains(key) && value is String
                    ? _decodeJsonText(value)
                    : value,
            },
        ],
    },
  });
}

Object? _decodeJsonText(String text) {
  try {
    return jsonDecode(text);
  } on FormatException {
    return text;
  }
}

// ---------------------------------------------------------------- import

/// A backup file that passed the checks, ready to import.
class BackupFile {
  const BackupFile({
    required this.dump,
    required this.schemaVersion,
    required this.exportedAt,
    required this.badRows,
  });

  /// The rows that were well-formed. References between them aren't
  /// checked yet: that depends on what they are merged with.
  final GraphDump dump;
  final int schemaVersion;
  final DateTime? exportedAt;

  /// Rows dropped because a column was missing or the wrong kind.
  final int badRows;

  int count(String table) => dump[table].length;
}

/// Reads and checks a backup file. Throws [BackupRejected] when the file
/// isn't a backup at all, or is from a newer version of the app.
BackupFile decodeBackup(
  String text, {
  required BackupSchema schema,
  required int currentSchemaVersion,
}) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    throw const BackupRejected("That file isn't a People Bubble backup.");
  }
  if (json is! Map<String, Object?> ||
      json['app'] != backupApp ||
      json['tables'] is! Map) {
    throw const BackupRejected("That file isn't a People Bubble backup.");
  }
  final version = json['schemaVersion'];
  final format = json['format'];
  if (version is! int || format is! int) {
    throw const BackupRejected('That backup is damaged (no version).');
  }
  if (version > currentSchemaVersion || format > backupFormat) {
    throw const BackupRejected(
      'That backup is from a newer version of the app. Update the app, '
      'then import it.',
    );
  }

  final tablesJson = json['tables']! as Map;
  final tables = <String, Map<String, DbRow>>{};
  var bad = 0;
  for (final t in dumpTables) {
    final columns = schema[t.name]!;
    final rows = tablesJson[t.name];
    final out = tables[t.name] = {};
    if (rows is! List) continue;
    for (final raw in rows) {
      final row = raw is Map ? _checkRow(t, columns, raw) : null;
      if (row == null) {
        bad++;
      } else {
        out[t.keyOf(row)] = row;
      }
    }
  }
  return BackupFile(
    dump: GraphDump(tables),
    schemaVersion: version,
    exportedAt: DateTime.tryParse('${json['exportedAt']}'),
    badRows: bad,
  );
}

/// The row as SQLite would store it, or null if it can't be stored.
/// Unknown columns are dropped; missing optional ones get their default.
DbRow? _checkRow(
  DumpTable t,
  Map<String, BackupColumn> columns,
  Map<Object?, Object?> raw,
) {
  final row = <String, Object?>{};
  for (final MapEntry(key: name, value: col) in columns.entries) {
    Object? value = raw[name];
    if (value == null) {
      if (col.nullable) {
        row[name] = null;
        continue;
      }
      value = switch (name) {
        'created_at' || 'updated_at' => DateTime.now().toIso8601String(),
        _ => _columnDefaults[name],
      };
      if (value == null) return null;
    }
    final stored = t.jsonColumns.contains(name)
        ? (value is String ? value : jsonEncode(value))
        : _storedValue(col.type, value);
    if (stored == null) return null;
    row[name] = stored;
  }
  return row;
}

Object? _storedValue(DriftSqlType<Object>? type, Object value) =>
    switch (type) {
      null => value is String ? value : null,
      DriftSqlType.string => value is String ? value : null,
      DriftSqlType.int => value is int ? value : null,
      DriftSqlType.double => value is num ? value.toDouble() : null,
      DriftSqlType.bool => switch (value) {
        true || 1 => 1,
        false || 0 => 0,
        _ => null,
      },
      DriftSqlType.dateTime =>
        value is String && parseStoredDate(value) != null ? value : null,
      _ => null,
    };

/// Parses a date as drift stores it ("2026-11-09T12:20:58.015 -05:00").
DateTime? parseStoredDate(String text) =>
    DateTime.tryParse(text) ?? DateTime.tryParse(text.replaceFirst(' ', ''));

// ------------------------------------------------------------ the result

/// What an import will do (or did), counted from the rows that change.
class ImportPlan {
  ImportPlan(this.target, {required this.skipped, required this.badRows});

  /// The full set of rows the database should hold afterwards.
  final GraphDump target;

  /// Rows dropped because they point at something that isn't there.
  final int skipped;

  /// Rows dropped while reading the file.
  final int badRows;
}

/// Replace: the file's rows, plus any built-in type the file lacks (the app
/// needs those).
ImportPlan planReplace(GraphDump current, BackupFile file) {
  final tables = {
    for (final t in dumpTables) t.name: {...file.dump[t.name]},
  };
  for (final table in ['node_types', 'edge_types']) {
    for (final MapEntry(key: id, value: row) in current[table].entries) {
      if (row['built_in'] == 1) tables[table]!.putIfAbsent(id, () => row);
    }
  }
  return _finish(tables, file);
}

/// Merge: records are matched by id. Where both sides have one, the newer
/// `updated_at` wins (ties keep what's on the phone). A bubble's types and a
/// line's waypoint list come with whichever side won it.
ImportPlan planMerge(GraphDump current, BackupFile file) {
  final tables = {
    for (final t in dumpTables) t.name: {...current[t.name]},
  };
  final won = <String, Set<String>>{};
  for (final table in [
    'node_types',
    'edge_types',
    'nodes',
    'waypoints',
    'edges',
  ]) {
    final mine = tables[table]!;
    final wins = won[table] = {};
    for (final MapEntry(key: id, value: row) in file.dump[table].entries) {
      final existing = mine[id];
      if (existing == null ||
          (!_sameContent(row, existing) && _newer(row, existing))) {
        mine[id] = row;
        wins.add(id);
      }
    }
  }
  // Child lists follow their owner.
  void takeChildren(String table, String ownerColumn, Set<String> owners) {
    final rows = tables[table]!;
    rows.removeWhere((_, r) => owners.contains(r[ownerColumn]));
    for (final MapEntry(:key, :value) in file.dump[table].entries) {
      if (owners.contains(value[ownerColumn])) rows[key] = value;
    }
  }

  takeChildren('node_type_links', 'node_id', won['nodes']!);
  takeChildren('edge_waypoints', 'edge_id', won['edges']!);
  return _finish(tables, file);
}

/// Equal apart from timestamps (built-in types seeded on two phones).
bool _sameContent(DbRow a, DbRow b) {
  const stamps = {'created_at', 'updated_at'};
  if (a.length != b.length) return false;
  for (final MapEntry(:key, :value) in a.entries) {
    if (!stamps.contains(key) && b[key] != value) return false;
  }
  return true;
}

bool _newer(DbRow a, DbRow b) {
  final ta = parseStoredDate('${a['updated_at']}');
  final tb = parseStoredDate('${b['updated_at']}');
  if (ta == null || tb == null) return false;
  return ta.isAfter(tb);
}

/// Drops rows that point at missing rows (repeating, since one drop can
/// orphan another) and types caught in a parent loop.
ImportPlan _finish(Map<String, Map<String, DbRow>> tables, BackupFile file) {
  var skipped = 0;
  void dropWhere(String table, bool Function(DbRow row) bad) {
    final rows = tables[table]!;
    final before = rows.length;
    rows.removeWhere((_, r) => bad(r));
    skipped += before - rows.length;
  }

  for (final table in ['node_types', 'edge_types']) {
    final rows = tables[table]!;
    // A type must reach a root (no parent) without looping.
    bool reachesRoot(DbRow row) {
      final seen = <Object?>{};
      Object? at = row['parent_id'];
      while (at != null) {
        if (!seen.add(at)) return false;
        final parent = rows[at];
        if (parent == null) return false;
        at = parent['parent_id'];
      }
      return true;
    }

    dropWhere(table, (r) => !reachesRoot(r));
  }
  final nodes = tables['nodes']!, nodeTypes = tables['node_types']!;
  final edgeTypes = tables['edge_types']!, waypoints = tables['waypoints']!;
  dropWhere(
    'node_type_links',
    (r) =>
        !nodes.containsKey(r['node_id']) ||
        !nodeTypes.containsKey(r['type_id']),
  );
  dropWhere(
    'edges',
    (r) =>
        !nodes.containsKey(r['source_id']) ||
        !nodes.containsKey(r['target_id']) ||
        !edgeTypes.containsKey(r['type_id']),
  );
  final edges = tables['edges']!;
  dropWhere(
    'edge_waypoints',
    (r) =>
        !edges.containsKey(r['edge_id']) ||
        !waypoints.containsKey(r['waypoint_id']),
  );
  return ImportPlan(GraphDump(tables), skipped: skipped, badRows: file.badRows);
}

/// What an import changed, for the message afterwards.
class ImportReport {
  const ImportReport(
    this.changes, {
    required this.skipped,
    required this.badRows,
  });

  /// Table → (added, updated, removed).
  final Map<String, ({int added, int updated, int removed})> changes;
  final int skipped;
  final int badRows;

  factory ImportReport.of(DumpDiff diff, ImportPlan plan) => ImportReport(
    {
      for (final MapEntry(key: table, value: rows) in diff.tables.entries)
        table: (
          added: rows.values.where((c) => c.before == null).length,
          updated: rows.values
              .where((c) => c.before != null && c.after != null)
              .length,
          removed: rows.values.where((c) => c.after == null).length,
        ),
    },
    skipped: plan.skipped,
    badRows: plan.badRows,
  );

  /// "12 bubbles added, 3 updated · 40 lines added · 2 items skipped".
  String get summary {
    String part(List<String> tables, String one, String many) {
      var added = 0, updated = 0, removed = 0;
      for (final t in tables) {
        final c = changes[t];
        if (c == null) continue;
        added += c.added;
        updated += c.updated;
        removed += c.removed;
      }
      final total = added + updated + removed;
      if (total == 0) return '';
      String noun(int n) => n == 1 ? one : many;
      final bits = [
        if (added > 0) '$added ${noun(added)} added',
        if (updated > 0)
          added > 0 ? '$updated updated' : '$updated ${noun(updated)} updated',
        if (removed > 0)
          added + updated > 0
              ? '$removed removed'
              : '$removed ${noun(removed)} removed',
      ];
      return bits.join(', ');
    }

    final dropped = skipped + badRows;
    final parts = [
      part(['nodes'], 'bubble', 'bubbles'),
      part(['edges'], 'line', 'lines'),
      part(['node_types', 'edge_types'], 'type', 'types'),
      if (dropped > 0) '$dropped ${dropped == 1 ? 'item' : 'items'} skipped',
    ].where((p) => p.isNotEmpty);
    return parts.isEmpty
        ? 'Nothing new: everything in that file is already here.'
        : parts.join(' · ');
  }
}
