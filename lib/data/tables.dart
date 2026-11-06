import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/style.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

/// Stores a [NodeStyle] as JSON text. Like an EF Core value converter: drift
/// calls it on every read and write, so the rest of the app sees the class.
class NodeStyleConverter extends TypeConverter<NodeStyle, String> {
  const NodeStyleConverter();

  @override
  NodeStyle fromSql(String fromDb) => NodeStyle.fromJson(_decodeObject(fromDb));

  @override
  String toSql(NodeStyle value) => jsonEncode(value.toJson());
}

class EdgeStyleConverter extends TypeConverter<EdgeStyle, String> {
  const EdgeStyleConverter();

  @override
  EdgeStyle fromSql(String fromDb) => EdgeStyle.fromJson(_decodeObject(fromDb));

  @override
  String toSql(EdgeStyle value) => jsonEncode(value.toJson());
}

Map<String, Object?> _decodeObject(String text) {
  try {
    final value = jsonDecode(text);
    return value is Map<String, Object?> ? value : const {};
  } on FormatException {
    return const {};
  }
}

/// id, createdAt and updatedAt, shared by every entity table.
mixin _Entity on Table {
  TextColumn get id => text().clientDefault(newId)();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NodeTypeRow')
class NodeTypes extends Table with _Entity {
  TextColumn get name => text()();

  /// Null only for the built-in base `Node` type.
  TextColumn get parentId => text().nullable().references(NodeTypes, #id)();
  TextColumn get style => text()
      .map(const NodeStyleConverter())
      .withDefault(const Constant('{}'))();
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();
}

@DataClassName('EdgeTypeRow')
class EdgeTypes extends Table with _Entity {
  TextColumn get name => text()();

  /// Null only for the built-in base `Edge` type.
  TextColumn get parentId => text().nullable().references(EdgeTypes, #id)();

  /// Includes the inherited `hierarchical` flag.
  TextColumn get style => text()
      .map(const EdgeStyleConverter())
      .withDefault(const Constant('{}'))();
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();
}

@DataClassName('NodeRow')
class Nodes extends Table with _Entity {
  TextColumn get label => text()();

  /// Canvas position; null until the node is first placed.
  RealColumn get x => real().nullable()();
  RealColumn get y => real().nullable()();

  /// Per-node style overrides, applied after all types.
  TextColumn get style => text()
      .map(const NodeStyleConverter())
      .withDefault(const Constant('{}'))();
}

/// Which types each node has. A node with no rows here is a base `Node`.
@DataClassName('NodeTypeLinkRow')
class NodeTypeLinks extends Table {
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();
  TextColumn get typeId => text().references(NodeTypes, #id)();

  /// Keeps the user's chosen order (it doesn't affect the resolved style).
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {nodeId, typeId};
}

@DataClassName('EdgeRow')
class Edges extends Table with _Entity {
  /// Parent end. Deleting either node deletes the edge.
  TextColumn get sourceId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();

  /// Child end.
  TextColumn get targetId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();
  TextColumn get typeId => text().references(EdgeTypes, #id)();
  TextColumn get label => text().nullable()();
  TextColumn get style => text()
      .map(const EdgeStyleConverter())
      .withDefault(const Constant('{}'))();
}

/// A bend point that any number of edges can share.
@DataClassName('WaypointRow')
class Waypoints extends Table with _Entity {
  RealColumn get x => real()();
  RealColumn get y => real()();
}

/// The ordered waypoints of each edge.
@DataClassName('EdgeWaypointRow')
class EdgeWaypoints extends Table {
  TextColumn get edgeId =>
      text().references(Edges, #id, onDelete: KeyAction.cascade)();
  TextColumn get waypointId =>
      text().references(Waypoints, #id, onDelete: KeyAction.cascade)();

  /// 0-based order from source to target.
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {edgeId, position};
}
