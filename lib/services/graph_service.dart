import 'dart:math';

import 'package:drift/drift.dart';

import '../data/app_database.dart';
import '../data/graph_reader.dart';
import '../domain/graph.dart';
import '../domain/style.dart';
import '../domain/types.dart';
import 'graph_errors.dart';

export 'graph_errors.dart';

/// Every change to the graph goes through here: the UI, sample data and,
/// later, AI quick-add all call the same methods.
///
/// Each method checks the rules against a fresh snapshot and writes inside one
/// transaction, so a refused write changes nothing. Refusals throw a
/// [GraphRuleException] with a message for the user.
class GraphService {
  GraphService(this._db) : _reader = GraphReader(_db);

  final AppDatabase _db;
  final GraphReader _reader;

  // ---------------------------------------------------------------- nodes

  /// Creates a node and returns its id. [typeIds] empty means base `Node`.
  Future<String> createNode({
    required String label,
    List<String> typeIds = const [],
    double? x,
    double? y,
  }) => _write((s) => _insertNode(s, label, typeIds, x: x, y: y));

  /// Creates a bubble under [parentId] and the line to it, in one step.
  /// Used by the list's add sheet; a refusal leaves neither behind.
  Future<({String nodeId, String edgeId})> createChildNode({
    required String parentId,
    required String label,
    required String edgeTypeId,
    List<String> typeIds = const [],
    String? edgeLabel,
  }) => _write((s) async {
    _requireNode(s, parentId);
    _requireEdgeType(s, edgeTypeId);
    final nodeId = await _insertNode(s, label, typeIds);
    // A brand-new bubble has no children, so this line can't form a loop.
    final edgeId = await _insertEdge(parentId, nodeId, edgeTypeId, edgeLabel);
    return (nodeId: nodeId, edgeId: edgeId);
  });

  /// Renames a node and/or replaces its types, in one step.
  Future<void> updateNode(String id, {String? label, List<String>? typeIds}) =>
      _write((s) async {
        _requireNode(s, id);
        final cleanLabel = label == null ? null : _requireLabel(label);
        final types = typeIds == null ? null : _checkNodeTypes(s, typeIds);
        if (types != null) {
          await (_db.delete(
            _db.nodeTypeLinks,
          )..where((l) => l.nodeId.equals(id))).go();
          await _insertTypeLinks(id, types);
        }
        await _updateNode(
          id,
          NodesCompanion(
            label: cleanLabel == null
                ? const Value.absent()
                : Value(cleanLabel),
          ),
        );
      });

  /// Saves positions chosen by auto-placement, in one batch. Nodes that got
  /// a position some other way in the meantime keep it.
  Future<void> placeNodes(Map<String, Point<double>> positions) async {
    if (positions.isEmpty) return;
    final now = DateTime.now();
    await _db.batch((b) {
      for (final MapEntry(key: id, value: p) in positions.entries) {
        b.update(
          _db.nodes,
          NodesCompanion(x: Value(p.x), y: Value(p.y), updatedAt: Value(now)),
          where: (n) => n.id.equals(id) & n.x.isNull(),
        );
      }
    });
  }

  /// Saves a node's canvas position. Call on drag end, not every frame.
  Future<void> moveNode(String id, double x, double y) => _write((s) async {
    _requireNode(s, id);
    await _updateNode(id, NodesCompanion(x: Value(x), y: Value(y)));
  });

  /// Saves several canvas positions at once (a dragged group, and the
  /// waypoints that travel with it), in one write.
  Future<void> moveNodes(
    Map<String, Point<double>> positions, {
    Map<String, Point<double>> waypoints = const {},
  }) => _write((s) async {
    for (final id in positions.keys) {
      _requireNode(s, id);
    }
    for (final id in waypoints.keys) {
      _requireWaypoint(s, id);
    }
    final now = DateTime.now();
    await _db.batch((b) {
      for (final MapEntry(key: id, value: p) in positions.entries) {
        b.update(
          _db.nodes,
          NodesCompanion(x: Value(p.x), y: Value(p.y), updatedAt: Value(now)),
          where: (n) => n.id.equals(id),
        );
      }
      for (final MapEntry(key: id, value: p) in waypoints.entries) {
        b.update(
          _db.waypoints,
          WaypointsCompanion(
            x: Value(p.x),
            y: Value(p.y),
            updatedAt: Value(now),
          ),
          where: (w) => w.id.equals(id),
        );
      }
    });
  });

  Future<void> setNodeOverrides(String id, NodeStyle overrides) =>
      _write((s) async {
        _requireNode(s, id);
        await _updateNode(id, NodesCompanion(style: Value(overrides)));
      });

  /// Deletes a node, its edges, and any waypoints no edge uses any more.
  Future<void> deleteNode(String id) => _write((s) async {
    _requireNode(s, id);
    // Foreign-key cascades remove its edges, type links and edge waypoints.
    await (_db.delete(_db.nodes)..where((n) => n.id.equals(id))).go();
    await _deleteOrphanWaypoints();
  });

  // ---------------------------------------------------------------- edges

  /// Creates an edge from [sourceId] (parent) to [targetId] (child) and
  /// returns its id. Refused if a hierarchical edge would form a loop.
  Future<String> createEdge({
    required String sourceId,
    required String targetId,
    required String typeId,
    String? label,
  }) => _write((s) async {
    _requireNode(s, sourceId);
    _requireNode(s, targetId);
    _requireEdgeType(s, typeId);
    if (sourceId == targetId) {
      throw const InvalidInput("A line can't connect a bubble to itself.");
    }
    _checkNoCycle(s, sourceId, targetId, typeId);
    return _insertEdge(sourceId, targetId, typeId, label);
  });

  /// Moves a line so it hangs under [newSourceId] instead, keeping its type
  /// and label. Used when dragging a row to a new parent in the list.
  Future<void> moveEdge(String id, String newSourceId) => _write((s) async {
    final edge = _requireEdge(s, id);
    _requireNode(s, newSourceId);
    if (newSourceId == edge.targetId) {
      throw const InvalidInput("A line can't connect a bubble to itself.");
    }
    _checkNoCycle(s, newSourceId, edge.targetId, edge.typeId, ignoreEdgeId: id);
    await _updateEdge(id, EdgesCompanion(sourceId: Value(newSourceId)));
  });

  /// Swaps a line's ends (parent ↔ child), keeping its type and label.
  /// Refused if the reversed line would form a loop. Waypoints keep their
  /// places, in reverse order.
  Future<void> reverseEdge(String id) => _write((s) async {
    final edge = _requireEdge(s, id);
    _checkNoCycle(
      s,
      edge.targetId,
      edge.sourceId,
      edge.typeId,
      ignoreEdgeId: id,
    );
    await _updateEdge(
      id,
      EdgesCompanion(
        sourceId: Value(edge.targetId),
        targetId: Value(edge.sourceId),
      ),
    );
    final count = edge.waypointIds.length;
    if (count > 1) {
      // position -> count-1-position in two steps, so the (edge, position)
      // key never collides mid-update.
      await _db.customUpdate(
        'UPDATE edge_waypoints SET position = -1 - position WHERE edge_id = ?',
        variables: [Variable(id)],
        updates: {_db.edgeWaypoints},
      );
      await _db.customUpdate(
        'UPDATE edge_waypoints SET position = position + ? WHERE edge_id = ?',
        variables: [Variable(count), Variable(id)],
        updates: {_db.edgeWaypoints},
      );
    }
  });

  /// Changes a line's type and label together (from the list's edit sheet).
  /// An empty [label] clears it.
  Future<void> updateEdge(String id, {required String typeId, String? label}) =>
      _write((s) async {
        final edge = _requireEdge(s, id);
        _requireEdgeType(s, typeId);
        _checkNoCycle(
          s,
          edge.sourceId,
          edge.targetId,
          typeId,
          ignoreEdgeId: id,
        );
        await _updateEdge(
          id,
          EdgesCompanion(
            typeId: Value(typeId),
            label: Value(_optionalLabel(label)),
          ),
        );
      });

  /// Per-edge style overrides. Whether an edge is hierarchical comes from its
  /// type only, so a `hierarchical` value here is ignored.
  Future<void> setEdgeOverrides(String id, EdgeStyle overrides) =>
      _write((s) async {
        _requireEdge(s, id);
        final visualOnly = EdgeStyle(
          width: overrides.width,
          lineStyle: overrides.lineStyle,
          color: overrides.color,
          arrowhead: overrides.arrowhead,
        );
        await _updateEdge(id, EdgesCompanion(style: Value(visualOnly)));
      });

  Future<void> deleteEdge(String id) => _write((s) async {
    _requireEdge(s, id);
    await (_db.delete(_db.edges)..where((e) => e.id.equals(id))).go();
    await _deleteOrphanWaypoints();
  });

  // ------------------------------------------------------------ waypoints

  /// Bends line [edgeId] through a new waypoint at [at], placed [index]-th
  /// along it from the source end (clamped to the valid range). Returns the
  /// waypoint's id.
  Future<String> addWaypoint(
    String edgeId, {
    required int index,
    required Point<double> at,
  }) => _write((s) async {
    final edge = _requireEdge(s, edgeId);
    final id = newId();
    await _db
        .into(_db.waypoints)
        .insert(WaypointsCompanion.insert(id: Value(id), x: at.x, y: at.y));
    final ids = [...edge.waypointIds]
      ..insert(index.clamp(0, edge.waypointIds.length), id);
    await _setEdgeWaypoints(edgeId, ids);
    return id;
  });

  Future<void> moveWaypoint(String id, Point<double> to) => _write((s) async {
    _requireWaypoint(s, id);
    await _writeWaypoint(id, to);
  });

  /// Clamps two waypoints together: every line through [dragged] goes
  /// through [into] instead, and [dragged] is deleted. A line that would
  /// then pass through the same point twice in a row keeps it once.
  Future<void> mergeWaypoints(String dragged, String into) => _write((s) async {
    _requireWaypoint(s, dragged);
    _requireWaypoint(s, into);
    if (dragged == into) return;
    for (final edge in s.edges.values) {
      if (!edge.waypointIds.contains(dragged)) continue;
      final ids = <String>[];
      for (final w in edge.waypointIds) {
        final id = w == dragged ? into : w;
        if (ids.isEmpty || ids.last != id) ids.add(id);
      }
      await _setEdgeWaypoints(edge.id, ids);
    }
    await (_db.delete(_db.waypoints)..where((w) => w.id.equals(dragged))).go();
  });

  /// Splits a shared waypoint: each line through it gets its own copy,
  /// nudged [nudge] units along that line so the split is visible. Refused
  /// if only one line uses it.
  Future<void> unclampWaypoint(String id, {double nudge = 24}) => _write((
    s,
  ) async {
    final w = _requireWaypoint(s, id);
    final edges = [
      for (final e in s.edges.values)
        if (e.waypointIds.contains(id)) e,
    ];
    if (edges.length < 2) {
      throw const InvalidInput('Only one line uses that waypoint.');
    }
    final here = Point(w.x, w.y);
    for (final (k, edge) in edges.indexed) {
      final dir = _nudgeAlong(s, edge, id, here, k, edges.length);
      final at = Point(here.x + dir.x * nudge, here.y + dir.y * nudge);
      if (k == 0) {
        // The first line keeps the original (moved a little).
        await _writeWaypoint(id, at);
        continue;
      }
      final copy = newId();
      await _db
          .into(_db.waypoints)
          .insert(WaypointsCompanion.insert(id: Value(copy), x: at.x, y: at.y));
      await _setEdgeWaypoints(edge.id, [
        for (final x in edge.waypointIds) x == id ? copy : x,
      ]);
    }
  });

  /// Removes a waypoint from every line that bends through it.
  Future<void> deleteWaypoint(String id) => _write((s) async {
    _requireWaypoint(s, id);
    for (final edge in s.edges.values) {
      if (!edge.waypointIds.contains(id)) continue;
      await _setEdgeWaypoints(edge.id, [
        for (final x in edge.waypointIds)
          if (x != id) x,
      ]);
    }
    await (_db.delete(_db.waypoints)..where((w) => w.id.equals(id))).go();
  });

  /// A unit vector from waypoint [id] toward the middle of its neighbours
  /// on [edge] (the points just before and after it), so an unclamped copy
  /// slides along its own line. Falls back to spreading the [count] copies
  /// evenly around a circle when the neighbours are unknown or cancel out.
  Point<double> _nudgeAlong(
    GraphSnapshot s,
    GraphEdge edge,
    String id,
    Point<double> here,
    int k,
    int count,
  ) {
    Point<double>? waypointAt(String wid) {
      final w = s.waypoints[wid];
      return w == null ? null : Point(w.x, w.y);
    }

    Point<double>? nodeAt(String nid) {
      final n = s.nodes[nid];
      return n == null || !n.isPlaced ? null : Point(n.x!, n.y!);
    }

    final ids = edge.waypointIds;
    final i = ids.indexOf(id);
    final before = i == 0 ? nodeAt(edge.sourceId) : waypointAt(ids[i - 1]);
    final after = i == ids.length - 1
        ? nodeAt(edge.targetId)
        : waypointAt(ids[i + 1]);
    final neighbours = [?before, ?after];
    if (neighbours.isNotEmpty) {
      var mx = 0.0, my = 0.0;
      for (final p in neighbours) {
        mx += p.x / neighbours.length;
        my += p.y / neighbours.length;
      }
      final dx = mx - here.x, dy = my - here.y;
      final length = sqrt(dx * dx + dy * dy);
      if (length > 1e-6) return Point(dx / length, dy / length);
    }
    final angle = 2 * pi * k / count;
    return Point(cos(angle), sin(angle));
  }

  Future<void> _writeWaypoint(String id, Point<double> at) =>
      (_db.update(_db.waypoints)..where((w) => w.id.equals(id))).write(
        WaypointsCompanion(
          x: Value(at.x),
          y: Value(at.y),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Replaces line [edgeId]'s waypoint list with [ids], in order.
  Future<void> _setEdgeWaypoints(String edgeId, List<String> ids) async {
    await (_db.delete(
      _db.edgeWaypoints,
    )..where((r) => r.edgeId.equals(edgeId))).go();
    await _db.batch((b) {
      b.insertAll(_db.edgeWaypoints, [
        for (final (i, id) in ids.indexed)
          EdgeWaypointsCompanion.insert(
            edgeId: edgeId,
            waypointId: id,
            position: i,
          ),
      ]);
    });
    await _updateEdge(edgeId, const EdgesCompanion());
  }

  // ---------------------------------------------------------------- types

  Future<String> createNodeType({
    required String name,
    required String parentId,
    NodeStyle style = NodeStyle.empty,
  }) => _write((s) async {
    final cleanName = _requireLabel(name);
    if (!s.nodeTypes.byId.containsKey(parentId)) {
      throw const InvalidInput('That parent type no longer exists.');
    }
    final id = newId();
    await _db
        .into(_db.nodeTypes)
        .insert(
          NodeTypesCompanion.insert(
            id: Value(id),
            name: cleanName,
            parentId: Value(parentId),
            style: Value(style),
          ),
        );
    return id;
  });

  /// Changes a node type. Refused if it would make the type its own ancestor,
  /// or make the types on any existing node conflict (those nodes are listed).
  Future<void> updateNodeType(
    String id, {
    String? name,
    String? parentId,
    NodeStyle? style,
  }) => _write((s) async {
    final current = s.nodeTypes.byId[id];
    if (current == null) {
      throw const InvalidInput('That type no longer exists.');
    }
    _checkTypeParent(s.nodeTypes, current, parentId);
    final edited = current.copyWith(
      name: name == null ? null : _requireLabel(name),
      parentId: parentId,
      style: style,
    );
    final broken = nodesBrokenByTypeEdit(s.nodeTypes, edited, {
      for (final n in s.nodes.values) n.id: n.typeIds,
    });
    if (broken.isNotEmpty) {
      final labels = broken.keys.map((n) => s.nodes[n]!.label).toList()..sort();
      throw TypeEditBlocked(
        'That change would give ${labels.length} '
        '${labels.length == 1 ? 'bubble' : 'bubbles'} conflicting types: '
        '${labels.join(', ')}.',
        affectedNodeIds: broken.keys.toList(),
      );
    }
    await (_db.update(_db.nodeTypes)..where((t) => t.id.equals(id))).write(
      NodeTypesCompanion(
        name: Value(edited.name),
        parentId: Value(edited.parentId),
        style: Value(edited.style),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  Future<String> createEdgeType({
    required String name,
    required String parentId,
    EdgeStyle style = EdgeStyle.empty,
  }) => _write((s) async {
    final cleanName = _requireLabel(name);
    if (!s.edgeTypes.byId.containsKey(parentId)) {
      throw const InvalidInput('That parent type no longer exists.');
    }
    // A new type has no edges yet, so it can't create a loop.
    final id = newId();
    await _db
        .into(_db.edgeTypes)
        .insert(
          EdgeTypesCompanion.insert(
            id: Value(id),
            name: cleanName,
            parentId: Value(parentId),
            style: Value(style),
          ),
        );
    return id;
  });

  /// Changes an edge type. Refused if it would make the type its own
  /// ancestor, or turn hierarchy on for edges that would then form a loop.
  Future<void> updateEdgeType(
    String id, {
    String? name,
    String? parentId,
    EdgeStyle? style,
  }) => _write((s) async {
    final current = s.edgeTypes.byId[id];
    if (current == null) {
      throw const InvalidInput('That type no longer exists.');
    }
    _checkTypeParent(s.edgeTypes, current, parentId);
    final edited = current.copyWith(
      name: name == null ? null : _requireLabel(name),
      parentId: parentId,
      style: style,
    );
    final after = GraphSnapshot(
      nodes: s.nodes.values,
      edges: s.edges.values,
      nodeTypes: s.nodeTypes,
      edgeTypes: s.edgeTypes.withType(edited),
    );
    if (graphHasCycle(_hierarchicalPairs(after))) {
      throw const CycleBlocked(
        'Making these lines hierarchical would create a loop '
        '(something would end up inside itself).',
      );
    }
    await (_db.update(_db.edgeTypes)..where((t) => t.id.equals(id))).write(
      EdgeTypesCompanion(
        name: Value(edited.name),
        parentId: Value(edited.parentId),
        style: Value(edited.style),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  /// Deletes a user-made node type. Bubbles lose it (falling back to base
  /// `Node` if it was their only type) and its subtypes move up to its
  /// parent. Built-in types can't be deleted.
  Future<void> deleteNodeType(String id) => _write((s) async {
    final type = _requireDeletableType(s.nodeTypes, id);
    await (_db.update(
      _db.nodeTypes,
    )..where((t) => t.parentId.equals(id))).write(
      NodeTypesCompanion(
        parentId: Value(type.parentId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (_db.delete(
      _db.nodeTypeLinks,
    )..where((l) => l.typeId.equals(id))).go();
    await (_db.delete(_db.nodeTypes)..where((t) => t.id.equals(id))).go();
  });

  /// Deletes a user-made line type. Its lines and subtypes move to its
  /// parent type. Refused if that would make lines form a loop (the parent
  /// can be hierarchical where this type wasn't).
  Future<void> deleteEdgeType(String id) => _write((s) async {
    final type = _requireDeletableType(s.edgeTypes, id);
    final parentId = type.parentId!;
    final types = s.edgeTypes;
    final after = GraphSnapshot(
      nodes: s.nodes.values,
      edges: [
        for (final e in s.edges.values)
          e.typeId != id
              ? e
              : GraphEdge(
                  id: e.id,
                  sourceId: e.sourceId,
                  targetId: e.targetId,
                  typeId: parentId,
                  label: e.label,
                  waypointIds: e.waypointIds,
                  overrides: e.overrides,
                ),
      ],
      nodeTypes: s.nodeTypes,
      edgeTypes: TypeHierarchy(
        [
          for (final t in types.byId.values)
            if (t.id != id)
              t.parentId == id ? t.copyWith(parentId: parentId) : t,
        ],
        appDefaults: types.appDefaults,
        empty: types.empty,
      ),
    );
    if (graphHasCycle(_hierarchicalPairs(after))) {
      throw const CycleBlocked(
        'Deleting this type would turn its lines into ones that form a loop '
        '(something would end up inside itself).',
      );
    }
    final now = DateTime.now();
    await (_db.update(_db.edges)..where((e) => e.typeId.equals(id))).write(
      EdgesCompanion(typeId: Value(parentId), updatedAt: Value(now)),
    );
    await (_db.update(
      _db.edgeTypes,
    )..where((t) => t.parentId.equals(id))).write(
      EdgeTypesCompanion(parentId: Value(parentId), updatedAt: Value(now)),
    );
    await (_db.delete(_db.edgeTypes)..where((t) => t.id.equals(id))).go();
  });

  TypeDef<S> _requireDeletableType<S extends Style<S>>(
    TypeHierarchy<S> types,
    String id,
  ) {
    final type = types.byId[id];
    if (type == null) throw const InvalidInput('That type no longer exists.');
    if (type.builtIn || type.isBase) {
      throw InvalidInput("${type.name} is built in, so it can't be deleted.");
    }
    return type;
  }

  // ---------------------------------------------------------------- bulk

  /// Deletes every node, edge, waypoint and user-made type. Built-in types
  /// stay. For debug tools and "replace" imports.
  Future<void> clearAllData() => _db.transaction(() async {
    await _db.delete(_db.nodes).go();
    await _db.delete(_db.waypoints).go();
    // Children before parents, so foreign keys hold.
    for (final TableInfo<Table, Object?> table in [
      _db.nodeTypes,
      _db.edgeTypes,
    ]) {
      while (true) {
        final deleted = await _db.customUpdate(
          'DELETE FROM ${table.actualTableName} WHERE built_in = 0 AND id NOT '
          'IN (SELECT parent_id FROM ${table.actualTableName} '
          'WHERE parent_id IS NOT NULL)',
          updates: {table},
          updateKind: UpdateKind.delete,
        );
        if (deleted == 0) break;
      }
    }
  });

  // ---------------------------------------------------------------- helpers

  /// Runs [body] in a transaction with a fresh snapshot to check rules against.
  Future<T> _write<T>(Future<T> Function(GraphSnapshot snapshot) body) =>
      _db.transaction(() async => body(await _reader.load()));

  String _requireLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) throw const InvalidInput('Give it a name first.');
    return trimmed;
  }

  String? _optionalLabel(String? label) {
    final trimmed = label?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  GraphNode _requireNode(GraphSnapshot s, String id) =>
      s.nodes[id] ??
      (throw const InvalidInput('That bubble no longer exists.'));

  GraphWaypoint _requireWaypoint(GraphSnapshot s, String id) =>
      s.waypoints[id] ??
      (throw const InvalidInput('That waypoint no longer exists.'));

  GraphEdge _requireEdge(GraphSnapshot s, String id) =>
      s.edges[id] ?? (throw const InvalidInput('That line no longer exists.'));

  void _requireEdgeType(GraphSnapshot s, String typeId) {
    if (!s.edgeTypes.byId.containsKey(typeId)) {
      throw const InvalidInput('That line type no longer exists.');
    }
  }

  /// Validates and normalizes node types; the base type is implied, not stored.
  List<String> _checkNodeTypes(GraphSnapshot s, List<String> typeIds) {
    for (final id in typeIds) {
      if (!s.nodeTypes.byId.containsKey(id)) {
        throw const InvalidInput('One of those types no longer exists.');
      }
    }
    final conflicts = s.nodeTypes.conflicts(typeIds);
    if (conflicts.isNotEmpty) {
      throw TypeConflictBlocked(
        "Those types can't be combined: "
        '${conflicts.map(s.nodeTypes.describe).join('; ')}.',
        conflicts,
      );
    }
    return [
      for (final id in s.nodeTypes.normalize(typeIds))
        if (!s.nodeTypes.byId[id]!.isBase) id,
    ];
  }

  void _checkTypeParent<S extends Style<S>>(
    TypeHierarchy<S> types,
    TypeDef<S> type,
    String? newParentId,
  ) {
    if (newParentId == null) return;
    if (type.isBase) {
      throw const InvalidInput("The base type can't have a parent.");
    }
    if (!types.byId.containsKey(newParentId)) {
      throw const InvalidInput('That parent type no longer exists.');
    }
    if (types.parentWouldCreateCycle(type.id, newParentId)) {
      throw const InvalidInput(
        "A type can't be inside one of its own subtypes.",
      );
    }
  }

  void _checkNoCycle(
    GraphSnapshot s,
    String sourceId,
    String targetId,
    String typeId, {
    String? ignoreEdgeId,
  }) {
    if (s.edgeTypes.resolve([typeId]).hierarchical == false) return;
    final edges = [
      for (final e in s.hierarchicalEdges)
        if (e.id != ignoreEdgeId) (e.sourceId, e.targetId),
    ];
    if (edgeWouldCreateCycle(
      parentId: sourceId,
      childId: targetId,
      edges: edges,
    )) {
      throw CycleBlocked(
        'That would make a loop: “${s.nodes[targetId]!.label}” is already '
        'above “${s.nodes[sourceId]!.label}”.',
      );
    }
  }

  List<(String, String)> _hierarchicalPairs(GraphSnapshot s) => [
    for (final e in s.hierarchicalEdges) (e.sourceId, e.targetId),
  ];

  Future<String> _insertNode(
    GraphSnapshot s,
    String label,
    List<String> typeIds, {
    double? x,
    double? y,
  }) async {
    final cleanLabel = _requireLabel(label);
    final types = _checkNodeTypes(s, typeIds);
    final id = newId();
    await _db
        .into(_db.nodes)
        .insert(
          NodesCompanion.insert(
            id: Value(id),
            label: cleanLabel,
            x: Value(x),
            y: Value(y),
          ),
        );
    await _insertTypeLinks(id, types);
    return id;
  }

  Future<String> _insertEdge(
    String sourceId,
    String targetId,
    String typeId,
    String? label,
  ) async {
    final id = newId();
    await _db
        .into(_db.edges)
        .insert(
          EdgesCompanion.insert(
            id: Value(id),
            sourceId: sourceId,
            targetId: targetId,
            typeId: typeId,
            label: Value(_optionalLabel(label)),
          ),
        );
    return id;
  }

  Future<void> _insertTypeLinks(String nodeId, List<String> typeIds) async {
    await _db.batch((b) {
      b.insertAll(_db.nodeTypeLinks, [
        for (final (i, typeId) in typeIds.indexed)
          NodeTypeLinksCompanion.insert(
            nodeId: nodeId,
            typeId: typeId,
            position: i,
          ),
      ]);
    });
  }

  Future<void> _updateNode(String id, NodesCompanion changes) =>
      (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(DateTime.now())),
      );

  Future<void> _updateEdge(String id, EdgesCompanion changes) =>
      (_db.update(_db.edges)..where((e) => e.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(DateTime.now())),
      );

  Future<void> _deleteOrphanWaypoints() async {
    final used = _db.selectOnly(_db.edgeWaypoints)
      ..addColumns([_db.edgeWaypoints.waypointId]);
    await (_db.delete(
      _db.waypoints,
    )..where((w) => w.id.isNotInQuery(used))).go();
  }
}
