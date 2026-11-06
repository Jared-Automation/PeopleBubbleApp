import 'package:drift/drift.dart';

import '../domain/style.dart';
import 'app_database.dart';

/// Fixed IDs for the built-in rows, so they match across devices on import.
abstract final class SeedIds {
  static const nodeBase = 'node-type-base';
  static const person = 'node-type-person';
  static const thing = 'node-type-thing';

  static const edgeBase = 'edge-type-base';
  static const likes = 'edge-type-likes';
  static const loves = 'edge-type-loves';
  static const dislikes = 'edge-type-dislikes';
  static const related = 'edge-type-related';
}

/// Inserts the built-in types. Safe to run twice: existing rows are kept.
Future<void> insertSeedTypes(AppDatabase db) async {
  final nodeTypes = [
    NodeTypesCompanion.insert(
      id: const Value(SeedIds.nodeBase),
      name: 'Node',
      style: const Value(NodeStyle.appDefaults),
      builtIn: const Value(true),
    ),
    NodeTypesCompanion.insert(
      id: const Value(SeedIds.person),
      name: 'Person',
      parentId: const Value(SeedIds.nodeBase),
      style: const Value(
        NodeStyle(
          shape: NodeShape.roundedRect,
          width: 140,
          height: 64,
          outlineWidth: 3,
          fontSize: 18,
          bold: true,
        ),
      ),
      builtIn: const Value(true),
    ),
    NodeTypesCompanion.insert(
      id: const Value(SeedIds.thing),
      name: 'Thing',
      parentId: const Value(SeedIds.nodeBase),
      style: const Value(NodeStyle(shape: NodeShape.ellipse)),
      builtIn: const Value(true),
    ),
  ];
  final edgeTypes = [
    EdgeTypesCompanion.insert(
      id: const Value(SeedIds.edgeBase),
      name: 'Edge',
      style: const Value(EdgeStyle.appDefaults),
      builtIn: const Value(true),
    ),
    EdgeTypesCompanion.insert(
      id: const Value(SeedIds.likes),
      name: 'Likes',
      parentId: const Value(SeedIds.edgeBase),
      style: const Value(EdgeStyle(color: 0xFF43A047)),
      builtIn: const Value(true),
    ),
    EdgeTypesCompanion.insert(
      id: const Value(SeedIds.loves),
      name: 'Loves',
      parentId: const Value(SeedIds.likes),
      style: const Value(EdgeStyle(color: 0xFFE91E63, width: 3)),
      builtIn: const Value(true),
    ),
    EdgeTypesCompanion.insert(
      id: const Value(SeedIds.dislikes),
      name: 'Dislikes',
      parentId: const Value(SeedIds.edgeBase),
      style: const Value(EdgeStyle(color: 0xFFE53935)),
      builtIn: const Value(true),
    ),
    EdgeTypesCompanion.insert(
      id: const Value(SeedIds.related),
      name: 'Related',
      parentId: const Value(SeedIds.edgeBase),
      style: const Value(
        EdgeStyle(
          color: 0xFF9E9E9E,
          lineStyle: LineStyle.dotted,
          hierarchical: false,
        ),
      ),
      builtIn: const Value(true),
    ),
  ];
  // Parents are listed before children, so foreign keys hold row by row.
  await db.batch((b) {
    b.insertAll(db.nodeTypes, nodeTypes, mode: InsertMode.insertOrIgnore);
    b.insertAll(db.edgeTypes, edgeTypes, mode: InsertMode.insertOrIgnore);
  });
}
