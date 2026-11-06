import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/style.dart';
import 'package:people_bubble/domain/types.dart';

import 'fixtures.dart';

void main() {
  final types = canonicalNodeTypes;

  group('chain', () {
    test('lists ancestors top first', () {
      expect(types.chain('partner').map((t) => t.id), [
        'node',
        'person',
        'partner',
      ]);
    });

    test('stops on a parent cycle in bad data', () {
      final looped = TypeHierarchy.nodes([
        const NodeTypeDef(
          id: 'a',
          name: 'A',
          parentId: 'b',
          style: NodeStyle(),
        ),
        const NodeTypeDef(
          id: 'b',
          name: 'B',
          parentId: 'a',
          style: NodeStyle(),
        ),
      ]);
      expect(looped.chain('a').map((t) => t.id), ['b', 'a']);
    });

    test('parentWouldCreateCycle blocks self and descendants', () {
      expect(types.parentWouldCreateCycle('person', 'person'), isTrue);
      expect(types.parentWouldCreateCycle('person', 'partner'), isTrue);
      expect(types.parentWouldCreateCycle('partner', 'friend'), isFalse);
    });
  });

  group('conflicts (canonical example)', () {
    test('Partner + Board Gamer is allowed', () {
      expect(types.conflicts(['partner', 'gamer']), isEmpty);
    });

    test('Board Gamer + Friend is allowed', () {
      expect(types.conflicts(['gamer', 'friend']), isEmpty);
    });

    test('Partner + Friend conflicts on outline color', () {
      final conflicts = types.conflicts(['partner', 'friend']);
      expect(conflicts, hasLength(1));
      expect(conflicts.single.typeA, 'partner');
      expect(conflicts.single.typeB, 'friend');
      expect(conflicts.single.fields, ['outlineColor']);
    });

    test('Person + Thing conflicts on shape', () {
      expect(types.conflicts(['person', 'thing']).single.fields, ['shape']);
    });

    test('a type and its own ancestor never conflict', () {
      // Loves overrides Likes' color, but Likes is just redundant.
      expect(canonicalEdgeTypes.conflicts(['likes', 'loves']), isEmpty);
    });

    test('conflictsIfAdded explains why a picker option is greyed out', () {
      final reasons = types.conflictsIfAdded('friend', ['partner', 'gamer']);
      expect(reasons.single.typeA, 'partner');
      expect(reasons.single.fields, ['outlineColor']);
      expect(types.conflictsIfAdded('gamer', ['partner']), isEmpty);
    });
  });

  group('normalize', () {
    test('drops ancestors of other assigned types', () {
      expect(types.normalize(['person', 'partner', 'node']), ['partner']);
    });

    test('drops duplicates and unknown ids, keeps order', () {
      expect(types.normalize(['gamer', 'nope', 'partner', 'gamer']), [
        'gamer',
        'partner',
      ]);
    });
  });

  group('resolve', () {
    test('no types falls back to the base type', () {
      expect(types.resolve([]), NodeStyle.appDefaults);
    });

    test('layers defaults, then ancestors top-down, then overrides', () {
      final style = types.resolve([
        'partner',
        'gamer',
      ], overrides: const NodeStyle(fontSize: 30));
      expect(style.outlineColor, pink); // Partner
      expect(style.outlineStyle, LineStyle.dotted); // Board Gamer
      expect(style.shape, NodeShape.roundedRect); // Person
      expect(style.fillColor, NodeStyle.appDefaults.fillColor); // base
      expect(style.fontSize, 30); // override beats Person's 18
    });

    test('order of non-conflicting types does not matter', () {
      expect(
        types.resolve(['partner', 'gamer']),
        types.resolve(['gamer', 'partner']),
      );
    });

    test('edge hierarchical flag is inherited', () {
      expect(canonicalEdgeTypes.resolve(['loves']).hierarchical, isTrue);
      expect(canonicalEdgeTypes.resolve(['related']).hierarchical, isFalse);
    });
  });

  group('nodesBrokenByTypeEdit', () {
    final nodes = {
      'sam': ['partner', 'gamer'],
      'priya': ['friend', 'gamer'],
      'alex': ['friend'],
    };

    test('lists nodes whose types would start conflicting', () {
      // Board Gamer now also sets a green outline: clashes with Partner's pink
      // and Friend's blue, but Alex has only one type.
      final edited = types.byId['gamer']!.copyWith(
        style: const NodeStyle(
          outlineStyle: LineStyle.dotted,
          outlineColor: 0xFF00FF00,
        ),
      );
      final broken = nodesBrokenByTypeEdit(types, edited, nodes);
      expect(broken.keys, unorderedEquals(['sam', 'priya']));
      expect(broken['sam']!.single.fields, ['outlineColor']);
    });

    test('a harmless edit breaks nothing', () {
      final edited = types.byId['gamer']!.copyWith(
        style: const NodeStyle(outlineStyle: LineStyle.dashed),
      );
      expect(nodesBrokenByTypeEdit(types, edited, nodes), isEmpty);
    });
  });
}
