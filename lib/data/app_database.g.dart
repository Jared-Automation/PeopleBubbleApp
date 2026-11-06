// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NodeTypesTable extends NodeTypes
    with TableInfo<$NodeTypesTable, NodeTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES node_types (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<NodeStyle, String> style =
      GeneratedColumn<String>(
        'style',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<NodeStyle>($NodeTypesTable.$converterstyle);
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    parentId,
    style,
    builtIn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeTypeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      style: $NodeTypesTable.$converterstyle.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}style'],
        )!,
      ),
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}built_in'],
      )!,
    );
  }

  @override
  $NodeTypesTable createAlias(String alias) {
    return $NodeTypesTable(attachedDatabase, alias);
  }

  static TypeConverter<NodeStyle, String> $converterstyle =
      const NodeStyleConverter();
}

class NodeTypeRow extends DataClass implements Insertable<NodeTypeRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;

  /// Null only for the built-in base `Node` type.
  final String? parentId;
  final NodeStyle style;
  final bool builtIn;
  const NodeTypeRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.parentId,
    required this.style,
    required this.builtIn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    {
      map['style'] = Variable<String>(
        $NodeTypesTable.$converterstyle.toSql(style),
      );
    }
    map['built_in'] = Variable<bool>(builtIn);
    return map;
  }

  NodeTypesCompanion toCompanion(bool nullToAbsent) {
    return NodeTypesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      style: Value(style),
      builtIn: Value(builtIn),
    );
  }

  factory NodeTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeTypeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      style: serializer.fromJson<NodeStyle>(json['style']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'style': serializer.toJson<NodeStyle>(style),
      'builtIn': serializer.toJson<bool>(builtIn),
    };
  }

  NodeTypeRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    Value<String?> parentId = const Value.absent(),
    NodeStyle? style,
    bool? builtIn,
  }) => NodeTypeRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    style: style ?? this.style,
    builtIn: builtIn ?? this.builtIn,
  );
  NodeTypeRow copyWithCompanion(NodeTypesCompanion data) {
    return NodeTypeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      style: data.style.present ? data.style.value : this.style,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeTypeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('style: $style, ')
          ..write('builtIn: $builtIn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, name, parentId, style, builtIn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeTypeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.style == this.style &&
          other.builtIn == this.builtIn);
}

class NodeTypesCompanion extends UpdateCompanion<NodeTypeRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<NodeStyle> style;
  final Value<bool> builtIn;
  final Value<int> rowid;
  const NodeTypesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.style = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodeTypesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    this.parentId = const Value.absent(),
    this.style = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<NodeTypeRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? style,
    Expression<bool>? builtIn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (style != null) 'style': style,
      if (builtIn != null) 'built_in': builtIn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodeTypesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String?>? parentId,
    Value<NodeStyle>? style,
    Value<bool>? builtIn,
    Value<int>? rowid,
  }) {
    return NodeTypesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      style: style ?? this.style,
      builtIn: builtIn ?? this.builtIn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(
        $NodeTypesTable.$converterstyle.toSql(style.value),
      );
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeTypesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('style: $style, ')
          ..write('builtIn: $builtIn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EdgeTypesTable extends EdgeTypes
    with TableInfo<$EdgeTypesTable, EdgeTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EdgeTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES edge_types (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<EdgeStyle, String> style =
      GeneratedColumn<String>(
        'style',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<EdgeStyle>($EdgeTypesTable.$converterstyle);
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    parentId,
    style,
    builtIn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'edge_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<EdgeTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EdgeTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EdgeTypeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      style: $EdgeTypesTable.$converterstyle.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}style'],
        )!,
      ),
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}built_in'],
      )!,
    );
  }

  @override
  $EdgeTypesTable createAlias(String alias) {
    return $EdgeTypesTable(attachedDatabase, alias);
  }

  static TypeConverter<EdgeStyle, String> $converterstyle =
      const EdgeStyleConverter();
}

class EdgeTypeRow extends DataClass implements Insertable<EdgeTypeRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;

  /// Null only for the built-in base `Edge` type.
  final String? parentId;

  /// Includes the inherited `hierarchical` flag.
  final EdgeStyle style;
  final bool builtIn;
  const EdgeTypeRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.parentId,
    required this.style,
    required this.builtIn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    {
      map['style'] = Variable<String>(
        $EdgeTypesTable.$converterstyle.toSql(style),
      );
    }
    map['built_in'] = Variable<bool>(builtIn);
    return map;
  }

  EdgeTypesCompanion toCompanion(bool nullToAbsent) {
    return EdgeTypesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      style: Value(style),
      builtIn: Value(builtIn),
    );
  }

  factory EdgeTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EdgeTypeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      style: serializer.fromJson<EdgeStyle>(json['style']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'style': serializer.toJson<EdgeStyle>(style),
      'builtIn': serializer.toJson<bool>(builtIn),
    };
  }

  EdgeTypeRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    Value<String?> parentId = const Value.absent(),
    EdgeStyle? style,
    bool? builtIn,
  }) => EdgeTypeRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    style: style ?? this.style,
    builtIn: builtIn ?? this.builtIn,
  );
  EdgeTypeRow copyWithCompanion(EdgeTypesCompanion data) {
    return EdgeTypeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      style: data.style.present ? data.style.value : this.style,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EdgeTypeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('style: $style, ')
          ..write('builtIn: $builtIn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, name, parentId, style, builtIn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EdgeTypeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.style == this.style &&
          other.builtIn == this.builtIn);
}

class EdgeTypesCompanion extends UpdateCompanion<EdgeTypeRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<EdgeStyle> style;
  final Value<bool> builtIn;
  final Value<int> rowid;
  const EdgeTypesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.style = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EdgeTypesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    this.parentId = const Value.absent(),
    this.style = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<EdgeTypeRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? style,
    Expression<bool>? builtIn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (style != null) 'style': style,
      if (builtIn != null) 'built_in': builtIn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EdgeTypesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String?>? parentId,
    Value<EdgeStyle>? style,
    Value<bool>? builtIn,
    Value<int>? rowid,
  }) {
    return EdgeTypesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      style: style ?? this.style,
      builtIn: builtIn ?? this.builtIn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(
        $EdgeTypesTable.$converterstyle.toSql(style.value),
      );
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EdgeTypesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('style: $style, ')
          ..write('builtIn: $builtIn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodesTable extends Nodes with TableInfo<$NodesTable, NodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<NodeStyle, String> style =
      GeneratedColumn<String>(
        'style',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<NodeStyle>($NodesTable.$converterstyle);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    label,
    x,
    y,
    style,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      ),
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      ),
      style: $NodesTable.$converterstyle.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}style'],
        )!,
      ),
    );
  }

  @override
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }

  static TypeConverter<NodeStyle, String> $converterstyle =
      const NodeStyleConverter();
}

class NodeRow extends DataClass implements Insertable<NodeRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String label;

  /// Canvas position; null until the node is first placed.
  final double? x;
  final double? y;

  /// Per-node style overrides, applied after all types.
  final NodeStyle style;
  const NodeRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.label,
    this.x,
    this.y,
    required this.style,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || x != null) {
      map['x'] = Variable<double>(x);
    }
    if (!nullToAbsent || y != null) {
      map['y'] = Variable<double>(y);
    }
    {
      map['style'] = Variable<String>($NodesTable.$converterstyle.toSql(style));
    }
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      label: Value(label),
      x: x == null && nullToAbsent ? const Value.absent() : Value(x),
      y: y == null && nullToAbsent ? const Value.absent() : Value(y),
      style: Value(style),
    );
  }

  factory NodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      label: serializer.fromJson<String>(json['label']),
      x: serializer.fromJson<double?>(json['x']),
      y: serializer.fromJson<double?>(json['y']),
      style: serializer.fromJson<NodeStyle>(json['style']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'label': serializer.toJson<String>(label),
      'x': serializer.toJson<double?>(x),
      'y': serializer.toJson<double?>(y),
      'style': serializer.toJson<NodeStyle>(style),
    };
  }

  NodeRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? label,
    Value<double?> x = const Value.absent(),
    Value<double?> y = const Value.absent(),
    NodeStyle? style,
  }) => NodeRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    label: label ?? this.label,
    x: x.present ? x.value : this.x,
    y: y.present ? y.value : this.y,
    style: style ?? this.style,
  );
  NodeRow copyWithCompanion(NodesCompanion data) {
    return NodeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      label: data.label.present ? data.label.value : this.label,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      style: data.style.present ? data.style.value : this.style,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('label: $label, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('style: $style')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, label, x, y, style);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.label == this.label &&
          other.x == this.x &&
          other.y == this.y &&
          other.style == this.style);
}

class NodesCompanion extends UpdateCompanion<NodeRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> label;
  final Value<double?> x;
  final Value<double?> y;
  final Value<NodeStyle> style;
  final Value<int> rowid;
  const NodesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.label = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.style = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String label,
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.style = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : label = Value(label);
  static Insertable<NodeRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? label,
    Expression<double>? x,
    Expression<double>? y,
    Expression<String>? style,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (label != null) 'label': label,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (style != null) 'style': style,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? label,
    Value<double?>? x,
    Value<double?>? y,
    Value<NodeStyle>? style,
    Value<int>? rowid,
  }) {
    return NodesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      style: style ?? this.style,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(
        $NodesTable.$converterstyle.toSql(style.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('label: $label, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('style: $style, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodeTypeLinksTable extends NodeTypeLinks
    with TableInfo<$NodeTypeLinksTable, NodeTypeLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeTypeLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<String> typeId = GeneratedColumn<String>(
    'type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES node_types (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [nodeId, typeId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_type_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeTypeLinkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('type_id')) {
      context.handle(
        _typeIdMeta,
        typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_typeIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nodeId, typeId};
  @override
  NodeTypeLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeTypeLinkRow(
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      typeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $NodeTypeLinksTable createAlias(String alias) {
    return $NodeTypeLinksTable(attachedDatabase, alias);
  }
}

class NodeTypeLinkRow extends DataClass implements Insertable<NodeTypeLinkRow> {
  final String nodeId;
  final String typeId;

  /// Keeps the user's chosen order (it doesn't affect the resolved style).
  final int position;
  const NodeTypeLinkRow({
    required this.nodeId,
    required this.typeId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_id'] = Variable<String>(nodeId);
    map['type_id'] = Variable<String>(typeId);
    map['position'] = Variable<int>(position);
    return map;
  }

  NodeTypeLinksCompanion toCompanion(bool nullToAbsent) {
    return NodeTypeLinksCompanion(
      nodeId: Value(nodeId),
      typeId: Value(typeId),
      position: Value(position),
    );
  }

  factory NodeTypeLinkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeTypeLinkRow(
      nodeId: serializer.fromJson<String>(json['nodeId']),
      typeId: serializer.fromJson<String>(json['typeId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeId': serializer.toJson<String>(nodeId),
      'typeId': serializer.toJson<String>(typeId),
      'position': serializer.toJson<int>(position),
    };
  }

  NodeTypeLinkRow copyWith({String? nodeId, String? typeId, int? position}) =>
      NodeTypeLinkRow(
        nodeId: nodeId ?? this.nodeId,
        typeId: typeId ?? this.typeId,
        position: position ?? this.position,
      );
  NodeTypeLinkRow copyWithCompanion(NodeTypeLinksCompanion data) {
    return NodeTypeLinkRow(
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeTypeLinkRow(')
          ..write('nodeId: $nodeId, ')
          ..write('typeId: $typeId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(nodeId, typeId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeTypeLinkRow &&
          other.nodeId == this.nodeId &&
          other.typeId == this.typeId &&
          other.position == this.position);
}

class NodeTypeLinksCompanion extends UpdateCompanion<NodeTypeLinkRow> {
  final Value<String> nodeId;
  final Value<String> typeId;
  final Value<int> position;
  final Value<int> rowid;
  const NodeTypeLinksCompanion({
    this.nodeId = const Value.absent(),
    this.typeId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodeTypeLinksCompanion.insert({
    required String nodeId,
    required String typeId,
    required int position,
    this.rowid = const Value.absent(),
  }) : nodeId = Value(nodeId),
       typeId = Value(typeId),
       position = Value(position);
  static Insertable<NodeTypeLinkRow> custom({
    Expression<String>? nodeId,
    Expression<String>? typeId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeId != null) 'node_id': nodeId,
      if (typeId != null) 'type_id': typeId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodeTypeLinksCompanion copyWith({
    Value<String>? nodeId,
    Value<String>? typeId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return NodeTypeLinksCompanion(
      nodeId: nodeId ?? this.nodeId,
      typeId: typeId ?? this.typeId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (typeId.present) {
      map['type_id'] = Variable<String>(typeId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeTypeLinksCompanion(')
          ..write('nodeId: $nodeId, ')
          ..write('typeId: $typeId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EdgesTable extends Edges with TableInfo<$EdgesTable, EdgeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EdgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<String> typeId = GeneratedColumn<String>(
    'type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES edge_types (id)',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EdgeStyle, String> style =
      GeneratedColumn<String>(
        'style',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<EdgeStyle>($EdgesTable.$converterstyle);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    sourceId,
    targetId,
    typeId,
    label,
    style,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'edges';
  @override
  VerificationContext validateIntegrity(
    Insertable<EdgeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('type_id')) {
      context.handle(
        _typeIdMeta,
        typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_typeIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EdgeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EdgeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      typeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      style: $EdgesTable.$converterstyle.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}style'],
        )!,
      ),
    );
  }

  @override
  $EdgesTable createAlias(String alias) {
    return $EdgesTable(attachedDatabase, alias);
  }

  static TypeConverter<EdgeStyle, String> $converterstyle =
      const EdgeStyleConverter();
}

class EdgeRow extends DataClass implements Insertable<EdgeRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Parent end. Deleting either node deletes the edge.
  final String sourceId;

  /// Child end.
  final String targetId;
  final String typeId;
  final String? label;
  final EdgeStyle style;
  const EdgeRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceId,
    required this.targetId,
    required this.typeId,
    this.label,
    required this.style,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['source_id'] = Variable<String>(sourceId);
    map['target_id'] = Variable<String>(targetId);
    map['type_id'] = Variable<String>(typeId);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    {
      map['style'] = Variable<String>($EdgesTable.$converterstyle.toSql(style));
    }
    return map;
  }

  EdgesCompanion toCompanion(bool nullToAbsent) {
    return EdgesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sourceId: Value(sourceId),
      targetId: Value(targetId),
      typeId: Value(typeId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      style: Value(style),
    );
  }

  factory EdgeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EdgeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      targetId: serializer.fromJson<String>(json['targetId']),
      typeId: serializer.fromJson<String>(json['typeId']),
      label: serializer.fromJson<String?>(json['label']),
      style: serializer.fromJson<EdgeStyle>(json['style']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'sourceId': serializer.toJson<String>(sourceId),
      'targetId': serializer.toJson<String>(targetId),
      'typeId': serializer.toJson<String>(typeId),
      'label': serializer.toJson<String?>(label),
      'style': serializer.toJson<EdgeStyle>(style),
    };
  }

  EdgeRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sourceId,
    String? targetId,
    String? typeId,
    Value<String?> label = const Value.absent(),
    EdgeStyle? style,
  }) => EdgeRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sourceId: sourceId ?? this.sourceId,
    targetId: targetId ?? this.targetId,
    typeId: typeId ?? this.typeId,
    label: label.present ? label.value : this.label,
    style: style ?? this.style,
  );
  EdgeRow copyWithCompanion(EdgesCompanion data) {
    return EdgeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      label: data.label.present ? data.label.value : this.label,
      style: data.style.present ? data.style.value : this.style,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EdgeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId, ')
          ..write('typeId: $typeId, ')
          ..write('label: $label, ')
          ..write('style: $style')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    sourceId,
    targetId,
    typeId,
    label,
    style,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EdgeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sourceId == this.sourceId &&
          other.targetId == this.targetId &&
          other.typeId == this.typeId &&
          other.label == this.label &&
          other.style == this.style);
}

class EdgesCompanion extends UpdateCompanion<EdgeRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> sourceId;
  final Value<String> targetId;
  final Value<String> typeId;
  final Value<String?> label;
  final Value<EdgeStyle> style;
  final Value<int> rowid;
  const EdgesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.targetId = const Value.absent(),
    this.typeId = const Value.absent(),
    this.label = const Value.absent(),
    this.style = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EdgesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String sourceId,
    required String targetId,
    required String typeId,
    this.label = const Value.absent(),
    this.style = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       targetId = Value(targetId),
       typeId = Value(typeId);
  static Insertable<EdgeRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? sourceId,
    Expression<String>? targetId,
    Expression<String>? typeId,
    Expression<String>? label,
    Expression<String>? style,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sourceId != null) 'source_id': sourceId,
      if (targetId != null) 'target_id': targetId,
      if (typeId != null) 'type_id': typeId,
      if (label != null) 'label': label,
      if (style != null) 'style': style,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EdgesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? sourceId,
    Value<String>? targetId,
    Value<String>? typeId,
    Value<String?>? label,
    Value<EdgeStyle>? style,
    Value<int>? rowid,
  }) {
    return EdgesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      typeId: typeId ?? this.typeId,
      label: label ?? this.label,
      style: style ?? this.style,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (typeId.present) {
      map['type_id'] = Variable<String>(typeId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(
        $EdgesTable.$converterstyle.toSql(style.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EdgesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId, ')
          ..write('typeId: $typeId, ')
          ..write('label: $label, ')
          ..write('style: $style, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WaypointsTable extends Waypoints
    with TableInfo<$WaypointsTable, WaypointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaypointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, x, y];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'waypoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaypointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaypointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaypointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
    );
  }

  @override
  $WaypointsTable createAlias(String alias) {
    return $WaypointsTable(attachedDatabase, alias);
  }
}

class WaypointRow extends DataClass implements Insertable<WaypointRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double x;
  final double y;
  const WaypointRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.x,
    required this.y,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    return map;
  }

  WaypointsCompanion toCompanion(bool nullToAbsent) {
    return WaypointsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      x: Value(x),
      y: Value(y),
    );
  }

  factory WaypointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaypointRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
    };
  }

  WaypointRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? x,
    double? y,
  }) => WaypointRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    x: x ?? this.x,
    y: y ?? this.y,
  );
  WaypointRow copyWithCompanion(WaypointsCompanion data) {
    return WaypointRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaypointRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('x: $x, ')
          ..write('y: $y')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, x, y);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaypointRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.x == this.x &&
          other.y == this.y);
}

class WaypointsCompanion extends UpdateCompanion<WaypointRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<double> x;
  final Value<double> y;
  final Value<int> rowid;
  const WaypointsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WaypointsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required double x,
    required double y,
    this.rowid = const Value.absent(),
  }) : x = Value(x),
       y = Value(y);
  static Insertable<WaypointRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<double>? x,
    Expression<double>? y,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WaypointsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<double>? x,
    Value<double>? y,
    Value<int>? rowid,
  }) {
    return WaypointsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      x: x ?? this.x,
      y: y ?? this.y,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaypointsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EdgeWaypointsTable extends EdgeWaypoints
    with TableInfo<$EdgeWaypointsTable, EdgeWaypointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EdgeWaypointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _edgeIdMeta = const VerificationMeta('edgeId');
  @override
  late final GeneratedColumn<String> edgeId = GeneratedColumn<String>(
    'edge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES edges (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _waypointIdMeta = const VerificationMeta(
    'waypointId',
  );
  @override
  late final GeneratedColumn<String> waypointId = GeneratedColumn<String>(
    'waypoint_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES waypoints (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [edgeId, waypointId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'edge_waypoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<EdgeWaypointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('edge_id')) {
      context.handle(
        _edgeIdMeta,
        edgeId.isAcceptableOrUnknown(data['edge_id']!, _edgeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_edgeIdMeta);
    }
    if (data.containsKey('waypoint_id')) {
      context.handle(
        _waypointIdMeta,
        waypointId.isAcceptableOrUnknown(data['waypoint_id']!, _waypointIdMeta),
      );
    } else if (isInserting) {
      context.missing(_waypointIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {edgeId, position};
  @override
  EdgeWaypointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EdgeWaypointRow(
      edgeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edge_id'],
      )!,
      waypointId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waypoint_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $EdgeWaypointsTable createAlias(String alias) {
    return $EdgeWaypointsTable(attachedDatabase, alias);
  }
}

class EdgeWaypointRow extends DataClass implements Insertable<EdgeWaypointRow> {
  final String edgeId;
  final String waypointId;

  /// 0-based order from source to target.
  final int position;
  const EdgeWaypointRow({
    required this.edgeId,
    required this.waypointId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['edge_id'] = Variable<String>(edgeId);
    map['waypoint_id'] = Variable<String>(waypointId);
    map['position'] = Variable<int>(position);
    return map;
  }

  EdgeWaypointsCompanion toCompanion(bool nullToAbsent) {
    return EdgeWaypointsCompanion(
      edgeId: Value(edgeId),
      waypointId: Value(waypointId),
      position: Value(position),
    );
  }

  factory EdgeWaypointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EdgeWaypointRow(
      edgeId: serializer.fromJson<String>(json['edgeId']),
      waypointId: serializer.fromJson<String>(json['waypointId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'edgeId': serializer.toJson<String>(edgeId),
      'waypointId': serializer.toJson<String>(waypointId),
      'position': serializer.toJson<int>(position),
    };
  }

  EdgeWaypointRow copyWith({
    String? edgeId,
    String? waypointId,
    int? position,
  }) => EdgeWaypointRow(
    edgeId: edgeId ?? this.edgeId,
    waypointId: waypointId ?? this.waypointId,
    position: position ?? this.position,
  );
  EdgeWaypointRow copyWithCompanion(EdgeWaypointsCompanion data) {
    return EdgeWaypointRow(
      edgeId: data.edgeId.present ? data.edgeId.value : this.edgeId,
      waypointId: data.waypointId.present
          ? data.waypointId.value
          : this.waypointId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EdgeWaypointRow(')
          ..write('edgeId: $edgeId, ')
          ..write('waypointId: $waypointId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(edgeId, waypointId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EdgeWaypointRow &&
          other.edgeId == this.edgeId &&
          other.waypointId == this.waypointId &&
          other.position == this.position);
}

class EdgeWaypointsCompanion extends UpdateCompanion<EdgeWaypointRow> {
  final Value<String> edgeId;
  final Value<String> waypointId;
  final Value<int> position;
  final Value<int> rowid;
  const EdgeWaypointsCompanion({
    this.edgeId = const Value.absent(),
    this.waypointId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EdgeWaypointsCompanion.insert({
    required String edgeId,
    required String waypointId,
    required int position,
    this.rowid = const Value.absent(),
  }) : edgeId = Value(edgeId),
       waypointId = Value(waypointId),
       position = Value(position);
  static Insertable<EdgeWaypointRow> custom({
    Expression<String>? edgeId,
    Expression<String>? waypointId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (edgeId != null) 'edge_id': edgeId,
      if (waypointId != null) 'waypoint_id': waypointId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EdgeWaypointsCompanion copyWith({
    Value<String>? edgeId,
    Value<String>? waypointId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return EdgeWaypointsCompanion(
      edgeId: edgeId ?? this.edgeId,
      waypointId: waypointId ?? this.waypointId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (edgeId.present) {
      map['edge_id'] = Variable<String>(edgeId.value);
    }
    if (waypointId.present) {
      map['waypoint_id'] = Variable<String>(waypointId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EdgeWaypointsCompanion(')
          ..write('edgeId: $edgeId, ')
          ..write('waypointId: $waypointId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NodeTypesTable nodeTypes = $NodeTypesTable(this);
  late final $EdgeTypesTable edgeTypes = $EdgeTypesTable(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $NodeTypeLinksTable nodeTypeLinks = $NodeTypeLinksTable(this);
  late final $EdgesTable edges = $EdgesTable(this);
  late final $WaypointsTable waypoints = $WaypointsTable(this);
  late final $EdgeWaypointsTable edgeWaypoints = $EdgeWaypointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    nodeTypes,
    edgeTypes,
    nodes,
    nodeTypeLinks,
    edges,
    waypoints,
    edgeWaypoints,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('node_type_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('edges', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('edges', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'edges',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('edge_waypoints', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'waypoints',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('edge_waypoints', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$NodeTypesTableCreateCompanionBuilder = NodeTypesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  required String name,
  Value<String?> parentId,
  Value<NodeStyle> style,
  Value<bool> builtIn,
  Value<int> rowid,
});
typedef $$NodeTypesTableUpdateCompanionBuilder = NodeTypesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<String?> parentId,
  Value<NodeStyle> style,
  Value<bool> builtIn,
  Value<int> rowid,
});

final class $$NodeTypesTableReferences
    extends BaseReferences<_$AppDatabase, $NodeTypesTable, NodeTypeRow> {
  $$NodeTypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NodeTypesTable _parentIdTable(_$AppDatabase db) =>
      db.nodeTypes.createAlias('node_types__parent_id__node_types__id');

  $$NodeTypesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$NodeTypesTableTableManager(
      $_db,
      $_db.nodeTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$NodeTypeLinksTable, List<NodeTypeLinkRow>>
  _nodeTypeLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nodeTypeLinks,
    aliasName: 'node_types__id__node_type_links__type_id',
  );

  $$NodeTypeLinksTableProcessedTableManager get nodeTypeLinksRefs {
    final manager = $$NodeTypeLinksTableTableManager(
      $_db,
      $_db.nodeTypeLinks,
    ).filter((f) => f.typeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodeTypeLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NodeTypesTableFilterComposer
    extends Composer<_$AppDatabase, $NodeTypesTable> {
  $$NodeTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NodeStyle, NodeStyle, String> get style =>
      $composableBuilder(
        column: $table.style,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );

  $$NodeTypesTableFilterComposer get parentId {
    final $$NodeTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.nodeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypesTableFilterComposer(
            $db: $db,
            $table: $db.nodeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> nodeTypeLinksRefs(
    Expression<bool> Function($$NodeTypeLinksTableFilterComposer f) f,
  ) {
    final $$NodeTypeLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeTypeLinks,
      getReferencedColumn: (t) => t.typeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypeLinksTableFilterComposer(
            $db: $db,
            $table: $db.nodeTypeLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NodeTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $NodeTypesTable> {
  $$NodeTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodeTypesTableOrderingComposer get parentId {
    final $$NodeTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.nodeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypesTableOrderingComposer(
            $db: $db,
            $table: $db.nodeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodeTypesTable> {
  $$NodeTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NodeStyle, String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  $$NodeTypesTableAnnotationComposer get parentId {
    final $$NodeTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.nodeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> nodeTypeLinksRefs<T extends Object>(
    Expression<T> Function($$NodeTypeLinksTableAnnotationComposer a) f,
  ) {
    final $$NodeTypeLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeTypeLinks,
      getReferencedColumn: (t) => t.typeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypeLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeTypeLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NodeTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodeTypesTable,
          NodeTypeRow,
          $$NodeTypesTableFilterComposer,
          $$NodeTypesTableOrderingComposer,
          $$NodeTypesTableAnnotationComposer,
          $$NodeTypesTableCreateCompanionBuilder,
          $$NodeTypesTableUpdateCompanionBuilder,
          (NodeTypeRow, $$NodeTypesTableReferences),
          NodeTypeRow,
          PrefetchHooks Function({bool parentId, bool nodeTypeLinksRefs})
        > {
  $$NodeTypesTableTableManager(_$AppDatabase db, $NodeTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<NodeStyle> style = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeTypesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                parentId: parentId,
                style: style,
                builtIn: builtIn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<NodeStyle> style = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeTypesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                parentId: parentId,
                style: style,
                builtIn: builtIn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodeTypesTable, NodeTypeRow>(table),
                  $$NodeTypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({parentId = false, nodeTypeLinksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (nodeTypeLinksRefs) db.nodeTypeLinks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $$NodeTypesTableReferences
                                ._parentIdTable(db),
                            referencedColumn: $$NodeTypesTableReferences
                                ._parentIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (nodeTypeLinksRefs)
                        await $_getPrefetchedDataByColumns<
                          NodeTypeRow,
                          $NodeTypesTable,
                          NodeTypeLinkRow,
                          $NodeTypeLinksTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodeTypesTableReferences
                              ._nodeTypeLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodeTypesTableReferences(
                                db,
                                table,
                                p0,
                              ).nodeTypeLinksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'type_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NodeTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodeTypesTable,
      NodeTypeRow,
      $$NodeTypesTableFilterComposer,
      $$NodeTypesTableOrderingComposer,
      $$NodeTypesTableAnnotationComposer,
      $$NodeTypesTableCreateCompanionBuilder,
      $$NodeTypesTableUpdateCompanionBuilder,
      (NodeTypeRow, $$NodeTypesTableReferences),
      NodeTypeRow,
      PrefetchHooks Function({bool parentId, bool nodeTypeLinksRefs})
    >;
typedef $$EdgeTypesTableCreateCompanionBuilder = EdgeTypesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  required String name,
  Value<String?> parentId,
  Value<EdgeStyle> style,
  Value<bool> builtIn,
  Value<int> rowid,
});
typedef $$EdgeTypesTableUpdateCompanionBuilder = EdgeTypesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<String?> parentId,
  Value<EdgeStyle> style,
  Value<bool> builtIn,
  Value<int> rowid,
});

final class $$EdgeTypesTableReferences
    extends BaseReferences<_$AppDatabase, $EdgeTypesTable, EdgeTypeRow> {
  $$EdgeTypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EdgeTypesTable _parentIdTable(_$AppDatabase db) =>
      db.edgeTypes.createAlias('edge_types__parent_id__edge_types__id');

  $$EdgeTypesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$EdgeTypesTableTableManager(
      $_db,
      $_db.edgeTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EdgesTable, List<EdgeRow>> _edgesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.edges,
    aliasName: 'edge_types__id__edges__type_id',
  );

  $$EdgesTableProcessedTableManager get edgesRefs {
    final manager = $$EdgesTableTableManager(
      $_db,
      $_db.edges,
    ).filter((f) => f.typeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_edgesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EdgeTypesTableFilterComposer
    extends Composer<_$AppDatabase, $EdgeTypesTable> {
  $$EdgeTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EdgeStyle, EdgeStyle, String> get style =>
      $composableBuilder(
        column: $table.style,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );

  $$EdgeTypesTableFilterComposer get parentId {
    final $$EdgeTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.edgeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeTypesTableFilterComposer(
            $db: $db,
            $table: $db.edgeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> edgesRefs(
    Expression<bool> Function($$EdgesTableFilterComposer f) f,
  ) {
    final $$EdgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.edges,
      getReferencedColumn: (t) => t.typeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgesTableFilterComposer(
            $db: $db,
            $table: $db.edges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EdgeTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $EdgeTypesTable> {
  $$EdgeTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );

  $$EdgeTypesTableOrderingComposer get parentId {
    final $$EdgeTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.edgeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeTypesTableOrderingComposer(
            $db: $db,
            $table: $db.edgeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EdgeTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EdgeTypesTable> {
  $$EdgeTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EdgeStyle, String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  $$EdgeTypesTableAnnotationComposer get parentId {
    final $$EdgeTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.edgeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.edgeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> edgesRefs<T extends Object>(
    Expression<T> Function($$EdgesTableAnnotationComposer a) f,
  ) {
    final $$EdgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.edges,
      getReferencedColumn: (t) => t.typeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgesTableAnnotationComposer(
            $db: $db,
            $table: $db.edges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EdgeTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EdgeTypesTable,
          EdgeTypeRow,
          $$EdgeTypesTableFilterComposer,
          $$EdgeTypesTableOrderingComposer,
          $$EdgeTypesTableAnnotationComposer,
          $$EdgeTypesTableCreateCompanionBuilder,
          $$EdgeTypesTableUpdateCompanionBuilder,
          (EdgeTypeRow, $$EdgeTypesTableReferences),
          EdgeTypeRow,
          PrefetchHooks Function({bool parentId, bool edgesRefs})
        > {
  $$EdgeTypesTableTableManager(_$AppDatabase db, $EdgeTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EdgeTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EdgeTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EdgeTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<EdgeStyle> style = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EdgeTypesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                parentId: parentId,
                style: style,
                builtIn: builtIn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<EdgeStyle> style = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EdgeTypesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                parentId: parentId,
                style: style,
                builtIn: builtIn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EdgeTypesTable, EdgeTypeRow>(table),
                  $$EdgeTypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false, edgesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (edgesRefs) db.edges],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (parentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.parentId,
                        referencedTable: $$EdgeTypesTableReferences
                            ._parentIdTable(db),
                        referencedColumn: $$EdgeTypesTableReferences
                            ._parentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (edgesRefs)
                    await $_getPrefetchedDataByColumns<
                      EdgeTypeRow,
                      $EdgeTypesTable,
                      EdgeRow,
                      $EdgesTable
                    >(
                      currentTable: table,
                      referencedTable: $$EdgeTypesTableReferences
                          ._edgesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$EdgeTypesTableReferences(db, table, p0).edgesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'type_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EdgeTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EdgeTypesTable,
      EdgeTypeRow,
      $$EdgeTypesTableFilterComposer,
      $$EdgeTypesTableOrderingComposer,
      $$EdgeTypesTableAnnotationComposer,
      $$EdgeTypesTableCreateCompanionBuilder,
      $$EdgeTypesTableUpdateCompanionBuilder,
      (EdgeTypeRow, $$EdgeTypesTableReferences),
      EdgeTypeRow,
      PrefetchHooks Function({bool parentId, bool edgesRefs})
    >;
typedef $$NodesTableCreateCompanionBuilder = NodesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  required String label,
  Value<double?> x,
  Value<double?> y,
  Value<NodeStyle> style,
  Value<int> rowid,
});
typedef $$NodesTableUpdateCompanionBuilder = NodesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> label,
  Value<double?> x,
  Value<double?> y,
  Value<NodeStyle> style,
  Value<int> rowid,
});

final class $$NodesTableReferences
    extends BaseReferences<_$AppDatabase, $NodesTable, NodeRow> {
  $$NodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NodeTypeLinksTable, List<NodeTypeLinkRow>>
  _nodeTypeLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nodeTypeLinks,
    aliasName: 'nodes__id__node_type_links__node_id',
  );

  $$NodeTypeLinksTableProcessedTableManager get nodeTypeLinksRefs {
    final manager = $$NodeTypeLinksTableTableManager(
      $_db,
      $_db.nodeTypeLinks,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodeTypeLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NodesTableFilterComposer extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NodeStyle, NodeStyle, String> get style =>
      $composableBuilder(
        column: $table.style,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> nodeTypeLinksRefs(
    Expression<bool> Function($$NodeTypeLinksTableFilterComposer f) f,
  ) {
    final $$NodeTypeLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeTypeLinks,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypeLinksTableFilterComposer(
            $db: $db,
            $table: $db.nodeTypeLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NodesTableOrderingComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NodeStyle, String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  Expression<T> nodeTypeLinksRefs<T extends Object>(
    Expression<T> Function($$NodeTypeLinksTableAnnotationComposer a) f,
  ) {
    final $$NodeTypeLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeTypeLinks,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypeLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeTypeLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodesTable,
          NodeRow,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (NodeRow, $$NodesTableReferences),
          NodeRow,
          PrefetchHooks Function({bool nodeTypeLinksRefs})
        > {
  $$NodesTableTableManager(_$AppDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<NodeStyle> style = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                label: label,
                x: x,
                y: y,
                style: style,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String label,
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<NodeStyle> style = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                label: label,
                x: x,
                y: y,
                style: style,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodesTable, NodeRow>(table),
                  $$NodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({nodeTypeLinksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (nodeTypeLinksRefs) db.nodeTypeLinks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (nodeTypeLinksRefs)
                    await $_getPrefetchedDataByColumns<
                      NodeRow,
                      $NodesTable,
                      NodeTypeLinkRow,
                      $NodeTypeLinksTable
                    >(
                      currentTable: table,
                      referencedTable: $$NodesTableReferences
                          ._nodeTypeLinksRefsTable(db),
                      managerFromTypedResult: (p0) => $$NodesTableReferences(
                        db,
                        table,
                        p0,
                      ).nodeTypeLinksRefs,
                      currentColumn: 'id',
                      referencedColumn: 'node_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodesTable,
      NodeRow,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (NodeRow, $$NodesTableReferences),
      NodeRow,
      PrefetchHooks Function({bool nodeTypeLinksRefs})
    >;
typedef $$NodeTypeLinksTableCreateCompanionBuilder =
    NodeTypeLinksCompanion Function({
      required String nodeId,
      required String typeId,
      required int position,
      Value<int> rowid,
    });
typedef $$NodeTypeLinksTableUpdateCompanionBuilder =
    NodeTypeLinksCompanion Function({
      Value<String> nodeId,
      Value<String> typeId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$NodeTypeLinksTableReferences
    extends
        BaseReferences<_$AppDatabase, $NodeTypeLinksTable, NodeTypeLinkRow> {
  $$NodeTypeLinksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NodesTable _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('node_type_links__node_id__nodes__id');

  $$NodesTableProcessedTableManager get nodeId {
    final $_column = $_itemColumn<String>('node_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NodeTypesTable _typeIdTable(_$AppDatabase db) =>
      db.nodeTypes.createAlias('node_type_links__type_id__node_types__id');

  $$NodeTypesTableProcessedTableManager get typeId {
    final $_column = $_itemColumn<String>('type_id')!;

    final manager = $$NodeTypesTableTableManager(
      $_db,
      $_db.nodeTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_typeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NodeTypeLinksTableFilterComposer
    extends Composer<_$AppDatabase, $NodeTypeLinksTable> {
  $$NodeTypeLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$NodesTableFilterComposer get nodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodeTypesTableFilterComposer get typeId {
    final $$NodeTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.typeId,
      referencedTable: $db.nodeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypesTableFilterComposer(
            $db: $db,
            $table: $db.nodeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeTypeLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $NodeTypeLinksTable> {
  $$NodeTypeLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodesTableOrderingComposer get nodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodeTypesTableOrderingComposer get typeId {
    final $$NodeTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.typeId,
      referencedTable: $db.nodeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypesTableOrderingComposer(
            $db: $db,
            $table: $db.nodeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeTypeLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodeTypeLinksTable> {
  $$NodeTypeLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$NodesTableAnnotationComposer get nodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodeTypesTableAnnotationComposer get typeId {
    final $$NodeTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.typeId,
      referencedTable: $db.nodeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeTypeLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodeTypeLinksTable,
          NodeTypeLinkRow,
          $$NodeTypeLinksTableFilterComposer,
          $$NodeTypeLinksTableOrderingComposer,
          $$NodeTypeLinksTableAnnotationComposer,
          $$NodeTypeLinksTableCreateCompanionBuilder,
          $$NodeTypeLinksTableUpdateCompanionBuilder,
          (NodeTypeLinkRow, $$NodeTypeLinksTableReferences),
          NodeTypeLinkRow,
          PrefetchHooks Function({bool nodeId, bool typeId})
        > {
  $$NodeTypeLinksTableTableManager(_$AppDatabase db, $NodeTypeLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeTypeLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeTypeLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeTypeLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nodeId = const Value.absent(),
                Value<String> typeId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeTypeLinksCompanion(
                nodeId: nodeId,
                typeId: typeId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeId,
                required String typeId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => NodeTypeLinksCompanion.insert(
                nodeId: nodeId,
                typeId: typeId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodeTypeLinksTable, NodeTypeLinkRow>(table),
                  $$NodeTypeLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({nodeId = false, typeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (nodeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nodeId,
                        referencedTable: $$NodeTypeLinksTableReferences
                            ._nodeIdTable(db),
                        referencedColumn: $$NodeTypeLinksTableReferences
                            ._nodeIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (typeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.typeId,
                        referencedTable: $$NodeTypeLinksTableReferences
                            ._typeIdTable(db),
                        referencedColumn: $$NodeTypeLinksTableReferences
                            ._typeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NodeTypeLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodeTypeLinksTable,
      NodeTypeLinkRow,
      $$NodeTypeLinksTableFilterComposer,
      $$NodeTypeLinksTableOrderingComposer,
      $$NodeTypeLinksTableAnnotationComposer,
      $$NodeTypeLinksTableCreateCompanionBuilder,
      $$NodeTypeLinksTableUpdateCompanionBuilder,
      (NodeTypeLinkRow, $$NodeTypeLinksTableReferences),
      NodeTypeLinkRow,
      PrefetchHooks Function({bool nodeId, bool typeId})
    >;
typedef $$EdgesTableCreateCompanionBuilder = EdgesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  required String sourceId,
  required String targetId,
  required String typeId,
  Value<String?> label,
  Value<EdgeStyle> style,
  Value<int> rowid,
});
typedef $$EdgesTableUpdateCompanionBuilder = EdgesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> sourceId,
  Value<String> targetId,
  Value<String> typeId,
  Value<String?> label,
  Value<EdgeStyle> style,
  Value<int> rowid,
});

final class $$EdgesTableReferences
    extends BaseReferences<_$AppDatabase, $EdgesTable, EdgeRow> {
  $$EdgesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NodesTable _sourceIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('edges__source_id__nodes__id');

  $$NodesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NodesTable _targetIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('edges__target_id__nodes__id');

  $$NodesTableProcessedTableManager get targetId {
    final $_column = $_itemColumn<String>('target_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EdgeTypesTable _typeIdTable(_$AppDatabase db) =>
      db.edgeTypes.createAlias('edges__type_id__edge_types__id');

  $$EdgeTypesTableProcessedTableManager get typeId {
    final $_column = $_itemColumn<String>('type_id')!;

    final manager = $$EdgeTypesTableTableManager(
      $_db,
      $_db.edgeTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_typeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EdgeWaypointsTable, List<EdgeWaypointRow>>
  _edgeWaypointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.edgeWaypoints,
    aliasName: 'edges__id__edge_waypoints__edge_id',
  );

  $$EdgeWaypointsTableProcessedTableManager get edgeWaypointsRefs {
    final manager = $$EdgeWaypointsTableTableManager(
      $_db,
      $_db.edgeWaypoints,
    ).filter((f) => f.edgeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_edgeWaypointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EdgesTableFilterComposer extends Composer<_$AppDatabase, $EdgesTable> {
  $$EdgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EdgeStyle, EdgeStyle, String> get style =>
      $composableBuilder(
        column: $table.style,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$NodesTableFilterComposer get sourceId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableFilterComposer get targetId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EdgeTypesTableFilterComposer get typeId {
    final $$EdgeTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.typeId,
      referencedTable: $db.edgeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeTypesTableFilterComposer(
            $db: $db,
            $table: $db.edgeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> edgeWaypointsRefs(
    Expression<bool> Function($$EdgeWaypointsTableFilterComposer f) f,
  ) {
    final $$EdgeWaypointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.edgeWaypoints,
      getReferencedColumn: (t) => t.edgeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeWaypointsTableFilterComposer(
            $db: $db,
            $table: $db.edgeWaypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EdgesTableOrderingComposer
    extends Composer<_$AppDatabase, $EdgesTable> {
  $$EdgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodesTableOrderingComposer get sourceId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableOrderingComposer get targetId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EdgeTypesTableOrderingComposer get typeId {
    final $$EdgeTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.typeId,
      referencedTable: $db.edgeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeTypesTableOrderingComposer(
            $db: $db,
            $table: $db.edgeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EdgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EdgesTable> {
  $$EdgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EdgeStyle, String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  $$NodesTableAnnotationComposer get sourceId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableAnnotationComposer get targetId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EdgeTypesTableAnnotationComposer get typeId {
    final $$EdgeTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.typeId,
      referencedTable: $db.edgeTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.edgeTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> edgeWaypointsRefs<T extends Object>(
    Expression<T> Function($$EdgeWaypointsTableAnnotationComposer a) f,
  ) {
    final $$EdgeWaypointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.edgeWaypoints,
      getReferencedColumn: (t) => t.edgeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeWaypointsTableAnnotationComposer(
            $db: $db,
            $table: $db.edgeWaypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EdgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EdgesTable,
          EdgeRow,
          $$EdgesTableFilterComposer,
          $$EdgesTableOrderingComposer,
          $$EdgesTableAnnotationComposer,
          $$EdgesTableCreateCompanionBuilder,
          $$EdgesTableUpdateCompanionBuilder,
          (EdgeRow, $$EdgesTableReferences),
          EdgeRow,
          PrefetchHooks Function({
            bool sourceId,
            bool targetId,
            bool typeId,
            bool edgeWaypointsRefs,
          })
        > {
  $$EdgesTableTableManager(_$AppDatabase db, $EdgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EdgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EdgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EdgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String> typeId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<EdgeStyle> style = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EdgesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sourceId: sourceId,
                targetId: targetId,
                typeId: typeId,
                label: label,
                style: style,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String sourceId,
                required String targetId,
                required String typeId,
                Value<String?> label = const Value.absent(),
                Value<EdgeStyle> style = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EdgesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sourceId: sourceId,
                targetId: targetId,
                typeId: typeId,
                label: label,
                style: style,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EdgesTable, EdgeRow>(table),
                  $$EdgesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourceId = false,
                targetId = false,
                typeId = false,
                edgeWaypointsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (edgeWaypointsRefs) db.edgeWaypoints,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceId,
                            referencedTable: $$EdgesTableReferences
                                ._sourceIdTable(db),
                            referencedColumn: $$EdgesTableReferences
                                ._sourceIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (targetId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.targetId,
                            referencedTable: $$EdgesTableReferences
                                ._targetIdTable(db),
                            referencedColumn: $$EdgesTableReferences
                                ._targetIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (typeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.typeId,
                            referencedTable: $$EdgesTableReferences
                                ._typeIdTable(db),
                            referencedColumn: $$EdgesTableReferences
                                ._typeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (edgeWaypointsRefs)
                        await $_getPrefetchedDataByColumns<
                          EdgeRow,
                          $EdgesTable,
                          EdgeWaypointRow,
                          $EdgeWaypointsTable
                        >(
                          currentTable: table,
                          referencedTable: $$EdgesTableReferences
                              ._edgeWaypointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EdgesTableReferences(
                                db,
                                table,
                                p0,
                              ).edgeWaypointsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'edge_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EdgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EdgesTable,
      EdgeRow,
      $$EdgesTableFilterComposer,
      $$EdgesTableOrderingComposer,
      $$EdgesTableAnnotationComposer,
      $$EdgesTableCreateCompanionBuilder,
      $$EdgesTableUpdateCompanionBuilder,
      (EdgeRow, $$EdgesTableReferences),
      EdgeRow,
      PrefetchHooks Function({
        bool sourceId,
        bool targetId,
        bool typeId,
        bool edgeWaypointsRefs,
      })
    >;
typedef $$WaypointsTableCreateCompanionBuilder = WaypointsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  required double x,
  required double y,
  Value<int> rowid,
});
typedef $$WaypointsTableUpdateCompanionBuilder = WaypointsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<double> x,
  Value<double> y,
  Value<int> rowid,
});

final class $$WaypointsTableReferences
    extends BaseReferences<_$AppDatabase, $WaypointsTable, WaypointRow> {
  $$WaypointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EdgeWaypointsTable, List<EdgeWaypointRow>>
  _edgeWaypointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.edgeWaypoints,
    aliasName: 'waypoints__id__edge_waypoints__waypoint_id',
  );

  $$EdgeWaypointsTableProcessedTableManager get edgeWaypointsRefs {
    final manager = $$EdgeWaypointsTableTableManager(
      $_db,
      $_db.edgeWaypoints,
    ).filter((f) => f.waypointId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_edgeWaypointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WaypointsTableFilterComposer
    extends Composer<_$AppDatabase, $WaypointsTable> {
  $$WaypointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> edgeWaypointsRefs(
    Expression<bool> Function($$EdgeWaypointsTableFilterComposer f) f,
  ) {
    final $$EdgeWaypointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.edgeWaypoints,
      getReferencedColumn: (t) => t.waypointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeWaypointsTableFilterComposer(
            $db: $db,
            $table: $db.edgeWaypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WaypointsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaypointsTable> {
  $$WaypointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaypointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaypointsTable> {
  $$WaypointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  Expression<T> edgeWaypointsRefs<T extends Object>(
    Expression<T> Function($$EdgeWaypointsTableAnnotationComposer a) f,
  ) {
    final $$EdgeWaypointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.edgeWaypoints,
      getReferencedColumn: (t) => t.waypointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgeWaypointsTableAnnotationComposer(
            $db: $db,
            $table: $db.edgeWaypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WaypointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaypointsTable,
          WaypointRow,
          $$WaypointsTableFilterComposer,
          $$WaypointsTableOrderingComposer,
          $$WaypointsTableAnnotationComposer,
          $$WaypointsTableCreateCompanionBuilder,
          $$WaypointsTableUpdateCompanionBuilder,
          (WaypointRow, $$WaypointsTableReferences),
          WaypointRow,
          PrefetchHooks Function({bool edgeWaypointsRefs})
        > {
  $$WaypointsTableTableManager(_$AppDatabase db, $WaypointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaypointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaypointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaypointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaypointsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                x: x,
                y: y,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required double x,
                required double y,
                Value<int> rowid = const Value.absent(),
              }) => WaypointsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                x: x,
                y: y,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WaypointsTable, WaypointRow>(table),
                  $$WaypointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({edgeWaypointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (edgeWaypointsRefs) db.edgeWaypoints,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (edgeWaypointsRefs)
                    await $_getPrefetchedDataByColumns<
                      WaypointRow,
                      $WaypointsTable,
                      EdgeWaypointRow,
                      $EdgeWaypointsTable
                    >(
                      currentTable: table,
                      referencedTable: $$WaypointsTableReferences
                          ._edgeWaypointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WaypointsTableReferences(
                            db,
                            table,
                            p0,
                          ).edgeWaypointsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'waypoint_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WaypointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaypointsTable,
      WaypointRow,
      $$WaypointsTableFilterComposer,
      $$WaypointsTableOrderingComposer,
      $$WaypointsTableAnnotationComposer,
      $$WaypointsTableCreateCompanionBuilder,
      $$WaypointsTableUpdateCompanionBuilder,
      (WaypointRow, $$WaypointsTableReferences),
      WaypointRow,
      PrefetchHooks Function({bool edgeWaypointsRefs})
    >;
typedef $$EdgeWaypointsTableCreateCompanionBuilder =
    EdgeWaypointsCompanion Function({
      required String edgeId,
      required String waypointId,
      required int position,
      Value<int> rowid,
    });
typedef $$EdgeWaypointsTableUpdateCompanionBuilder =
    EdgeWaypointsCompanion Function({
      Value<String> edgeId,
      Value<String> waypointId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$EdgeWaypointsTableReferences
    extends
        BaseReferences<_$AppDatabase, $EdgeWaypointsTable, EdgeWaypointRow> {
  $$EdgeWaypointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EdgesTable _edgeIdTable(_$AppDatabase db) =>
      db.edges.createAlias('edge_waypoints__edge_id__edges__id');

  $$EdgesTableProcessedTableManager get edgeId {
    final $_column = $_itemColumn<String>('edge_id')!;

    final manager = $$EdgesTableTableManager(
      $_db,
      $_db.edges,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_edgeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WaypointsTable _waypointIdTable(_$AppDatabase db) =>
      db.waypoints.createAlias('edge_waypoints__waypoint_id__waypoints__id');

  $$WaypointsTableProcessedTableManager get waypointId {
    final $_column = $_itemColumn<String>('waypoint_id')!;

    final manager = $$WaypointsTableTableManager(
      $_db,
      $_db.waypoints,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_waypointIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EdgeWaypointsTableFilterComposer
    extends Composer<_$AppDatabase, $EdgeWaypointsTable> {
  $$EdgeWaypointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$EdgesTableFilterComposer get edgeId {
    final $$EdgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.edgeId,
      referencedTable: $db.edges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgesTableFilterComposer(
            $db: $db,
            $table: $db.edges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WaypointsTableFilterComposer get waypointId {
    final $$WaypointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.waypointId,
      referencedTable: $db.waypoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaypointsTableFilterComposer(
            $db: $db,
            $table: $db.waypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EdgeWaypointsTableOrderingComposer
    extends Composer<_$AppDatabase, $EdgeWaypointsTable> {
  $$EdgeWaypointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$EdgesTableOrderingComposer get edgeId {
    final $$EdgesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.edgeId,
      referencedTable: $db.edges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgesTableOrderingComposer(
            $db: $db,
            $table: $db.edges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WaypointsTableOrderingComposer get waypointId {
    final $$WaypointsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.waypointId,
      referencedTable: $db.waypoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaypointsTableOrderingComposer(
            $db: $db,
            $table: $db.waypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EdgeWaypointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EdgeWaypointsTable> {
  $$EdgeWaypointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$EdgesTableAnnotationComposer get edgeId {
    final $$EdgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.edgeId,
      referencedTable: $db.edges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EdgesTableAnnotationComposer(
            $db: $db,
            $table: $db.edges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WaypointsTableAnnotationComposer get waypointId {
    final $$WaypointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.waypointId,
      referencedTable: $db.waypoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaypointsTableAnnotationComposer(
            $db: $db,
            $table: $db.waypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EdgeWaypointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EdgeWaypointsTable,
          EdgeWaypointRow,
          $$EdgeWaypointsTableFilterComposer,
          $$EdgeWaypointsTableOrderingComposer,
          $$EdgeWaypointsTableAnnotationComposer,
          $$EdgeWaypointsTableCreateCompanionBuilder,
          $$EdgeWaypointsTableUpdateCompanionBuilder,
          (EdgeWaypointRow, $$EdgeWaypointsTableReferences),
          EdgeWaypointRow,
          PrefetchHooks Function({bool edgeId, bool waypointId})
        > {
  $$EdgeWaypointsTableTableManager(_$AppDatabase db, $EdgeWaypointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EdgeWaypointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EdgeWaypointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EdgeWaypointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> edgeId = const Value.absent(),
                Value<String> waypointId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EdgeWaypointsCompanion(
                edgeId: edgeId,
                waypointId: waypointId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String edgeId,
                required String waypointId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => EdgeWaypointsCompanion.insert(
                edgeId: edgeId,
                waypointId: waypointId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EdgeWaypointsTable, EdgeWaypointRow>(table),
                  $$EdgeWaypointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({edgeId = false, waypointId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (edgeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.edgeId,
                        referencedTable: $$EdgeWaypointsTableReferences
                            ._edgeIdTable(db),
                        referencedColumn: $$EdgeWaypointsTableReferences
                            ._edgeIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (waypointId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.waypointId,
                        referencedTable: $$EdgeWaypointsTableReferences
                            ._waypointIdTable(db),
                        referencedColumn: $$EdgeWaypointsTableReferences
                            ._waypointIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EdgeWaypointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EdgeWaypointsTable,
      EdgeWaypointRow,
      $$EdgeWaypointsTableFilterComposer,
      $$EdgeWaypointsTableOrderingComposer,
      $$EdgeWaypointsTableAnnotationComposer,
      $$EdgeWaypointsTableCreateCompanionBuilder,
      $$EdgeWaypointsTableUpdateCompanionBuilder,
      (EdgeWaypointRow, $$EdgeWaypointsTableReferences),
      EdgeWaypointRow,
      PrefetchHooks Function({bool edgeId, bool waypointId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NodeTypesTableTableManager get nodeTypes =>
      $$NodeTypesTableTableManager(_db, _db.nodeTypes);
  $$EdgeTypesTableTableManager get edgeTypes =>
      $$EdgeTypesTableTableManager(_db, _db.edgeTypes);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
  $$NodeTypeLinksTableTableManager get nodeTypeLinks =>
      $$NodeTypeLinksTableTableManager(_db, _db.nodeTypeLinks);
  $$EdgesTableTableManager get edges =>
      $$EdgesTableTableManager(_db, _db.edges);
  $$WaypointsTableTableManager get waypoints =>
      $$WaypointsTableTableManager(_db, _db.waypoints);
  $$EdgeWaypointsTableTableManager get edgeWaypoints =>
      $$EdgeWaypointsTableTableManager(_db, _db.edgeWaypoints);
}
