import 'package:drift/drift.dart';

import 'app_database.dart';

/// One database row as SQLite stores it: column name → value (text, int,
/// real or null). Dates are ISO text and booleans 0/1, so rows copy
/// losslessly to JSON and back.
typedef DbRow = Map<String, Object?>;

/// What the dump needs to know about one table.
class DumpTable {
  const DumpTable(this.name, this.key, {this.jsonColumns = const {}});

  final String name;

  /// Primary-key columns; their values joined make a row's key.
  final List<String> key;

  /// Columns holding JSON text (styles), written as objects in exports.
  final Set<String> jsonColumns;

  String keyOf(DbRow row) => [for (final c in key) row[c]].join('|');
}

/// Every table, parents before children. Restores insert in this order and
/// delete in reverse.
const dumpTables = [
  DumpTable('node_types', ['id'], jsonColumns: {'style'}),
  DumpTable('edge_types', ['id'], jsonColumns: {'style'}),
  DumpTable('nodes', ['id'], jsonColumns: {'style'}),
  DumpTable('waypoints', ['id']),
  DumpTable('node_type_links', ['node_id', 'type_id']),
  DumpTable('edges', ['id'], jsonColumns: {'style'}),
  DumpTable('edge_waypoints', ['edge_id', 'position']),
];

DumpTable dumpTableNamed(String name) =>
    dumpTables.firstWhere((t) => t.name == name);

/// Every row of every table, keyed by table name, then row key.
class GraphDump {
  const GraphDump(this.tables);

  final Map<String, Map<String, DbRow>> tables;

  Map<String, DbRow> operator [](String table) => tables[table] ?? const {};

  int get rowCount => tables.values.fold(0, (n, t) => n + t.length);
}

/// Reads every table raw (no type conversion), for diffing and export.
Future<GraphDump> readDump(AppDatabase db) async {
  final tables = <String, Map<String, DbRow>>{};
  for (final t in dumpTables) {
    final rows = await db.customSelect('SELECT * FROM ${t.name}').get();
    tables[t.name] = {for (final r in rows) t.keyOf(r.data): Map.of(r.data)};
  }
  return GraphDump(tables);
}

/// One row's value before and after a change; null means "no such row".
class RowChange {
  const RowChange(this.before, this.after);

  final DbRow? before;
  final DbRow? after;

  RowChange get reversed => RowChange(after, before);
}

/// The rows a change touched, table → row key → change.
class DumpDiff {
  DumpDiff(this.tables);

  final Map<String, Map<String, RowChange>> tables;

  bool get isEmpty => tables.values.every((t) => t.isEmpty);

  int get rowCount => tables.values.fold(0, (n, t) => n + t.length);

  DumpDiff get reversed => DumpDiff({
    for (final MapEntry(key: table, value: rows) in tables.entries)
      table: {
        for (final MapEntry(key: k, value: c) in rows.entries) k: c.reversed,
      },
  });

  /// The `after` side of each change, ready for [applyRows].
  Map<String, Map<String, DbRow?>> get target => {
    for (final MapEntry(key: table, value: rows) in tables.entries)
      table: {
        for (final MapEntry(key: k, value: c) in rows.entries) k: c.after,
      },
  };

  /// Whether [dump] still holds exactly the `after` side of every change.
  bool matchesAfter(GraphDump dump) {
    for (final MapEntry(key: table, value: rows) in tables.entries) {
      for (final MapEntry(key: k, value: c) in rows.entries) {
        if (!rowsEqual(dump[table][k], c.after)) return false;
      }
    }
    return true;
  }
}

bool rowsEqual(DbRow? a, DbRow? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final MapEntry(:key, :value) in a.entries) {
    if (!b.containsKey(key) || b[key] != value) return false;
  }
  return true;
}

/// The rows that differ between [before] and [after].
DumpDiff diffDumps(GraphDump before, GraphDump after) {
  final tables = <String, Map<String, RowChange>>{};
  for (final t in dumpTables) {
    final a = before[t.name], b = after[t.name];
    final changes = <String, RowChange>{};
    for (final MapEntry(key: k, value: row) in a.entries) {
      final other = b[k];
      if (!rowsEqual(row, other)) changes[k] = RowChange(row, other);
    }
    for (final MapEntry(key: k, value: row) in b.entries) {
      if (!a.containsKey(k)) changes[k] = RowChange(null, row);
    }
    if (changes.isNotEmpty) tables[t.name] = changes;
  }
  return DumpDiff(tables);
}

/// Sets each listed row to the given value: null deletes it, otherwise it is
/// inserted or updated in place. Call inside a transaction. Foreign keys are
/// checked at commit, so rows can arrive in any order.
///
/// Updates use `ON CONFLICT DO UPDATE`, not `INSERT OR REPLACE`: a replace
/// deletes the old row first, which would cascade to its lines.
Future<void> applyRows(
  AppDatabase db,
  Map<String, Map<String, DbRow?>> target,
) async {
  await db.customStatement('PRAGMA defer_foreign_keys = ON');
  final tableInfo = {for (final t in db.allTables) t.actualTableName: t};

  for (final t in dumpTables.reversed) {
    final rows = target[t.name];
    if (rows == null) continue;
    final deletes = [
      for (final MapEntry(key: k, value: row) in rows.entries)
        if (row == null) k,
    ];
    if (deletes.isEmpty) continue;
    final keyExpr = t.key.length == 1
        ? t.key.single
        : "(${t.key.map((c) => "CAST($c AS TEXT)").join(" || '|' || ")})";
    for (var i = 0; i < deletes.length; i += 500) {
      final chunk = deletes.skip(i).take(500).toList();
      await db.customUpdate(
        'DELETE FROM ${t.name} WHERE $keyExpr IN '
        '(${List.filled(chunk.length, '?').join(', ')})',
        variables: [for (final k in chunk) Variable<String>(k)],
        updates: {tableInfo[t.name]!},
        updateKind: UpdateKind.delete,
      );
    }
  }

  for (final t in dumpTables) {
    final rows = target[t.name];
    if (rows == null) continue;
    for (final row in rows.values) {
      if (row == null) continue;
      final columns = row.keys.toList();
      final rest = [
        for (final c in columns)
          if (!t.key.contains(c)) c,
      ];
      final onConflict = rest.isEmpty
          ? 'DO NOTHING'
          : 'DO UPDATE SET ${rest.map((c) => '$c = excluded.$c').join(', ')}';
      await db.customUpdate(
        'INSERT INTO ${t.name} (${columns.join(', ')}) '
        'VALUES (${List.filled(columns.length, '?').join(', ')}) '
        'ON CONFLICT(${t.key.join(', ')}) $onConflict',
        variables: [for (final c in columns) _variable(row[c])],
        updates: {tableInfo[t.name]!},
        updateKind: UpdateKind.insert,
      );
    }
  }
}

Variable<Object> _variable(Object? value) => switch (value) {
  null => const Variable(null),
  final String s => Variable<String>(s),
  final int i => Variable<int>(i),
  final double d => Variable<double>(d),
  final bool b => Variable<int>(b ? 1 : 0),
  _ => Variable<String>('$value'),
};
