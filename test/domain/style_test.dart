import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/style.dart';

void main() {
  group('NodeStyle', () {
    test('mergeOver keeps set fields and fills the rest from base', () {
      const top = NodeStyle(outlineColor: 1, bold: true);
      const base = NodeStyle(outlineColor: 2, fontSize: 12);
      expect(
        top.mergeOver(base),
        const NodeStyle(outlineColor: 1, bold: true, fontSize: 12),
      );
    });

    test('setFields lists only set fields, enums by name', () {
      const style = NodeStyle(shape: NodeShape.circle, width: 10);
      expect(style.setFields, {'shape': 'circle', 'width': 10.0});
    });

    test('round-trips through JSON text', () {
      const style = NodeStyle(
        fontFamily: 'serif',
        fontSize: 14,
        outlineStyle: LineStyle.dashed,
        fillColor: 0xFF000000,
        bold: false,
      );
      final decoded = jsonDecode(jsonEncode(style.toJson()));
      expect(NodeStyle.fromJson(decoded as Map<String, Object?>), style);
    });

    test('fromJson ignores unknown keys and wrong value types', () {
      final style = NodeStyle.fromJson({
        'outlineColor': 'pink',
        'shape': 'hexagon',
        'mystery': 1,
        'fontSize': 12,
      });
      expect(style, const NodeStyle(fontSize: 12));
    });

    test('appDefaults sets every field', () {
      expect(NodeStyle.appDefaults.setFields.length, 12);
      expect(EdgeStyle.appDefaults.setFields.length, 5);
    });
  });

  group('EdgeStyle', () {
    test('round-trips through JSON', () {
      const style = EdgeStyle(
        arrowhead: Arrowhead.end,
        hierarchical: false,
        width: 3,
      );
      expect(EdgeStyle.fromJson(style.toJson()), style);
    });
  });
}
