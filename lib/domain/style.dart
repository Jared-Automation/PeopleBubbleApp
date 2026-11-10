/// Style values for nodes and edges.
///
/// Every field is nullable: `null` means "not set here, inherit it". A type
/// sets only the fields it cares about; resolution layers styles on top of
/// each other with [Style.mergeOver]. Colors are ARGB ints (e.g. 0xFFE91E63)
/// so this file stays free of Flutter imports.
library;

enum NodeShape { roundedRect, rectangle, ellipse, circle }

enum LineStyle { solid, dotted, dashed }

enum Arrowhead { none, end }

/// Shared shape of [NodeStyle] and [EdgeStyle], so type hierarchies,
/// resolution and conflict checks work on either.
abstract interface class Style<S> {
  /// A copy of this style with every unset field filled from [base].
  /// Fields set here win.
  S mergeOver(S base);

  /// The fields that are set, keyed by field name. Values are JSON-safe
  /// (enums as their name), so two maps compare field by field.
  Map<String, Object> get setFields;
}

class NodeStyle implements Style<NodeStyle> {
  const NodeStyle({
    this.fontFamily,
    this.fontColor,
    this.fontSize,
    this.bold,
    this.shape,
    this.width,
    this.height,
    this.fillColor,
    this.outlineColor,
    this.outlineWidth,
    this.outlineStyle,
    this.hidden,
  });

  /// Builds a style from [setFields]-shaped JSON. Unknown keys and values of
  /// the wrong type are ignored, so a bad import can't crash the app.
  factory NodeStyle.fromJson(Map<String, Object?> json) => NodeStyle(
    fontFamily: _string(json['fontFamily']),
    fontColor: _int(json['fontColor']),
    fontSize: _double(json['fontSize']),
    bold: _bool(json['bold']),
    shape: _enum(NodeShape.values, json['shape']),
    width: _double(json['width']),
    height: _double(json['height']),
    fillColor: _int(json['fillColor']),
    outlineColor: _int(json['outlineColor']),
    outlineWidth: _double(json['outlineWidth']),
    outlineStyle: _enum(LineStyle.values, json['outlineStyle']),
    hidden: _bool(json['hidden']),
  );

  static const empty = NodeStyle();

  /// Hard-coded fallback for every field, used under the base `Node` type.
  static const appDefaults = NodeStyle(
    fontFamily: 'Roboto',
    fontColor: 0xFF212121,
    fontSize: 14,
    bold: false,
    shape: NodeShape.ellipse,
    width: 96,
    height: 48,
    fillColor: 0xFFFFFFFF,
    outlineColor: 0xFF757575,
    outlineWidth: 1.5,
    outlineStyle: LineStyle.solid,
    hidden: false,
  );

  final String? fontFamily;
  final int? fontColor;
  final double? fontSize;
  final bool? bold;
  final NodeShape? shape;
  final double? width;
  final double? height;
  final int? fillColor;
  final int? outlineColor;
  final double? outlineWidth;
  final LineStyle? outlineStyle;

  /// Greys out everything under this bubble until it, or something under
  /// it, is selected (or "Show hidden" is on). The bubble itself stays.
  final bool? hidden;

  @override
  NodeStyle mergeOver(NodeStyle base) => NodeStyle(
    fontFamily: fontFamily ?? base.fontFamily,
    fontColor: fontColor ?? base.fontColor,
    fontSize: fontSize ?? base.fontSize,
    bold: bold ?? base.bold,
    shape: shape ?? base.shape,
    width: width ?? base.width,
    height: height ?? base.height,
    fillColor: fillColor ?? base.fillColor,
    outlineColor: outlineColor ?? base.outlineColor,
    outlineWidth: outlineWidth ?? base.outlineWidth,
    outlineStyle: outlineStyle ?? base.outlineStyle,
    hidden: hidden ?? base.hidden,
  );

  @override
  Map<String, Object> get setFields => {
    'fontFamily': ?fontFamily,
    'fontColor': ?fontColor,
    'fontSize': ?fontSize,
    'bold': ?bold,
    'shape': ?shape?.name,
    'width': ?width,
    'height': ?height,
    'fillColor': ?fillColor,
    'outlineColor': ?outlineColor,
    'outlineWidth': ?outlineWidth,
    'outlineStyle': ?outlineStyle?.name,
    'hidden': ?hidden,
  };

  Map<String, Object> toJson() => setFields;

  @override
  bool operator ==(Object other) =>
      other is NodeStyle && _mapEquals(setFields, other.setFields);

  @override
  int get hashCode =>
      Object.hashAllUnordered(setFields.entries.map(_hashEntry));

  @override
  String toString() => 'NodeStyle($setFields)';
}

class EdgeStyle implements Style<EdgeStyle> {
  const EdgeStyle({
    this.width,
    this.lineStyle,
    this.color,
    this.arrowhead,
    this.hierarchical,
  });

  factory EdgeStyle.fromJson(Map<String, Object?> json) => EdgeStyle(
    width: _double(json['width']),
    lineStyle: _enum(LineStyle.values, json['lineStyle']),
    color: _int(json['color']),
    arrowhead: _enum(Arrowhead.values, json['arrowhead']),
    hierarchical: _bool(json['hierarchical']),
  );

  static const empty = EdgeStyle();

  static const appDefaults = EdgeStyle(
    width: 2,
    lineStyle: LineStyle.solid,
    color: 0xFF757575,
    arrowhead: Arrowhead.none,
    hierarchical: true,
  );

  final double? width;
  final LineStyle? lineStyle;
  final int? color;
  final Arrowhead? arrowhead;

  /// Whether edges of this type form the parent/child structure. Not a visual
  /// style, but it inherits down the type tree exactly like one. Only types
  /// set it; per-edge overrides may not.
  final bool? hierarchical;

  @override
  EdgeStyle mergeOver(EdgeStyle base) => EdgeStyle(
    width: width ?? base.width,
    lineStyle: lineStyle ?? base.lineStyle,
    color: color ?? base.color,
    arrowhead: arrowhead ?? base.arrowhead,
    hierarchical: hierarchical ?? base.hierarchical,
  );

  @override
  Map<String, Object> get setFields => {
    'width': ?width,
    'lineStyle': ?lineStyle?.name,
    'color': ?color,
    'arrowhead': ?arrowhead?.name,
    'hierarchical': ?hierarchical,
  };

  Map<String, Object> toJson() => setFields;

  @override
  bool operator ==(Object other) =>
      other is EdgeStyle && _mapEquals(setFields, other.setFields);

  @override
  int get hashCode =>
      Object.hashAllUnordered(setFields.entries.map(_hashEntry));

  @override
  String toString() => 'EdgeStyle($setFields)';
}

String? _string(Object? v) => v is String ? v : null;
int? _int(Object? v) => v is int ? v : null;
double? _double(Object? v) => v is num ? v.toDouble() : null;
bool? _bool(Object? v) => v is bool ? v : null;

T? _enum<T extends Enum>(List<T> values, Object? v) {
  for (final value in values) {
    if (value.name == v) return value;
  }
  return null;
}

bool _mapEquals(Map<String, Object> a, Map<String, Object> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

int _hashEntry(MapEntry<String, Object> e) => Object.hash(e.key, e.value);

/// Readable names for style fields, for messages like
/// "Partner and Friend both set outline color".
const styleFieldLabels = <String, String>{
  'fontFamily': 'font',
  'fontColor': 'text color',
  'fontSize': 'text size',
  'bold': 'bold',
  'shape': 'shape',
  'width': 'width',
  'height': 'height',
  'fillColor': 'fill color',
  'outlineColor': 'outline color',
  'outlineWidth': 'outline width',
  'outlineStyle': 'outline style',
  'lineStyle': 'line style',
  'color': 'color',
  'arrowhead': 'arrowhead',
  'hierarchical': 'hierarchy',
};
