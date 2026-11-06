import 'package:drift/drift.dart';

import '../domain/graph.dart';
import '../domain/types.dart';
import 'app_database.dart';

/// Reads the whole graph into a [GraphSnapshot]. All reads go through here;
/// all writes go through `GraphService`.
class GraphReader {
  GraphReader(this._db);

  final AppDatabase _db;

  /// One consistent snapshot of every table.
  Future<GraphSnapshot> load() => _db.transaction(() async {
    final nodeTypeRows = await _db.select(_db.nodeTypes).get();
    final edgeTypeRows = await _db.select(_db.edgeTypes).get();
    final nodeRows = await _db.select(_db.nodes).get();
    final linkRows = await (_db.select(
      _db.nodeTypeLinks,
    )..orderBy([(l) => OrderingTerm.asc(l.position)])).get();
    final edgeRows = await _db.select(_db.edges).get();
    final waypointRows = await _db.select(_db.waypoints).get();
    final edgeWaypointRows = await (_db.select(
      _db.edgeWaypoints,
    )..orderBy([(w) => OrderingTerm.asc(w.position)])).get();

    final typesByNode = <String, List<String>>{};
    for (final link in linkRows) {
      (typesByNode[link.nodeId] ??= []).add(link.typeId);
    }
    final waypointsByEdge = <String, List<String>>{};
    for (final ew in edgeWaypointRows) {
      (waypointsByEdge[ew.edgeId] ??= []).add(ew.waypointId);
    }

    return GraphSnapshot(
      nodeTypes: TypeHierarchy.nodes([
        for (final t in nodeTypeRows)
          NodeTypeDef(
            id: t.id,
            name: t.name,
            parentId: t.parentId,
            style: t.style,
            builtIn: t.builtIn,
          ),
      ]),
      edgeTypes: TypeHierarchy.edges([
        for (final t in edgeTypeRows)
          EdgeTypeDef(
            id: t.id,
            name: t.name,
            parentId: t.parentId,
            style: t.style,
            builtIn: t.builtIn,
          ),
      ]),
      nodes: [
        for (final n in nodeRows)
          GraphNode(
            id: n.id,
            label: n.label,
            x: n.x,
            y: n.y,
            typeIds: typesByNode[n.id] ?? const [],
            overrides: n.style,
          ),
      ],
      edges: [
        for (final e in edgeRows)
          GraphEdge(
            id: e.id,
            sourceId: e.sourceId,
            targetId: e.targetId,
            typeId: e.typeId,
            label: e.label,
            waypointIds: waypointsByEdge[e.id] ?? const [],
            overrides: e.style,
          ),
      ],
      waypoints: [
        for (final w in waypointRows) GraphWaypoint(id: w.id, x: w.x, y: w.y),
      ],
    );
  });

  /// The current snapshot, then a fresh one after every committed change.
  Stream<GraphSnapshot> watch() async* {
    yield await load();
    await for (final _ in _db.tableUpdates()) {
      yield await load();
    }
  }
}
