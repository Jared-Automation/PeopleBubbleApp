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
  }) => _write((s) async {
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
  });

  Future<void> renameNode(String id, String label) => _write((s) async {
    _requireNode(s, id);
    await _updateNode(id, NodesCompanion(label: Value(_requireLabel(label))));
  });

  /// Replaces a node's types. Redundant ancestors are dropped; conflicting
  /// combinations are refused.
  Future<void> setNodeTypes(String id, List<String> typeIds) =>
      _write((s) async {
        _requireNode(s, id);
        final types = _checkNodeTypes(s, typeIds);
        await (_db.delete(
          _db.nodeTypeLinks,
        )..where((l) => l.nodeId.equals(id))).go();
        await _insertTypeLinks(id, types);
        await _updateNode(id, const NodesCompanion());
      });

  /// Saves a node's canvas position. Call on drag end, not every frame.
  Future<void> moveNode(String id, double x, double y) => _write((s) async {
    _requireNode(s, id);
    await _updateNode(id, NodesCompanion(x: Value(x), y: Value(y)));
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
  });

  Future<void> setEdgeType(String id, String typeId) => _write((s) async {
    final edge = _requireEdge(s, id);
    _requireEdgeType(s, typeId);
    _checkNoCycle(s, edge.sourceId, edge.targetId, typeId, ignoreEdgeId: id);
    await _updateEdge(id, EdgesCompanion(typeId: Value(typeId)));
  });

  Future<void> setEdgeLabel(String id, String? label) => _write((s) async {
    _requireEdge(s, id);
    await _updateEdge(id, EdgesCompanion(label: Value(_optionalLabel(label))));
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
