import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/domain/style.dart';
import 'package:people_bubble/services/graph_service.dart';
import 'package:people_bubble/ui/types/type_editor_screen.dart';

import 'harness.dart';

const pink = 0xFFE91E63, blue = 0xFF2196F3;

/// Partner (pink outline) and Friend (no outline) under Person; Sam is both.
late String partner, friend, sam;

Future<void> seedTypes(GraphService g) async {
  partner = await g.createNodeType(
    name: 'Partner',
    parentId: SeedIds.person,
    style: const NodeStyle(outlineColor: pink),
  );
  friend = await g.createNodeType(name: 'Friend', parentId: SeedIds.person);
  sam = await g.createNode(label: 'Sam', typeIds: [partner, friend]);
}

Future<void> openTypes(AppHarness app) async {
  await app.tester.tap(find.byTooltip('More'));
  await app.tester.pumpAndSettle();
  await app.tester.tap(find.text('Types'));
  await app.settle();
}

/// Taps the colour swatch of field [key] and picks preset [color].
Future<void> pickColor(WidgetTester tester, String key, int color) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(ValueKey('field-$key')),
      matching: find.byType(InkWell),
    ),
  );
  await tester.pumpAndSettle();
  final hex =
      '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  await tester.tap(find.bySemanticsLabel(hex));
  await tester.pump();
  await tester.tap(find.text('Use colour'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the ⋮ menu opens Types with both trees', (tester) async {
    final app = await AppHarness.start(tester);
    await openTypes(app);

    expect(find.text('Node'), findsOneWidget);
    expect(find.text('Person'), findsWidgets);
    expect(find.text('Thing'), findsWidgets);
    expect(find.text('base type · unused'), findsOneWidget);

    await tester.tap(find.text('Line types'));
    await app.settle();
    for (final name in ['Edge', 'Likes', 'Loves', 'Dislikes', 'Related']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
  });

  testWidgets('+ creates a subtype with the fields you set', (tester) async {
    final app = await AppHarness.start(tester);
    await openTypes(app);
    await tester.tap(find.byTooltip('New subtype of Person'));
    await app.settle();

    expect(find.text('New bubble type'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Gamer');
    await pickColor(tester, 'outlineColor', blue);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await app.settle();

    final s = await app.snapshot();
    final gamer = s.nodeTypes.byId.values.firstWhere((t) => t.name == 'Gamer');
    expect(gamer.parentId, SeedIds.person);
    expect(gamer.style, const NodeStyle(outlineColor: blue));
    expect(find.byType(TypeEditorScreen), findsNothing, reason: 'closed');
  });

  testWidgets('an edit that would make bubbles conflict is blocked live', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, seed: seedTypes);
    await openTypes(app);
    await tester.tap(find.text('Friend'));
    await app.settle();

    await pickColor(tester, 'outlineColor', blue);
    expect(
      find.textContaining("Can't save: this would give 1 bubble"),
      findsOneWidget,
    );
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNull);

    // Back to inherited: allowed again.
    await tester.tap(find.byTooltip('Inherit outline colour'));
    await tester.pump();
    expect(find.textContaining("Can't save"), findsNothing);
  });

  testWidgets('deleting a type in use says what changes, then does it', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, seed: seedTypes);
    await openTypes(app);
    await tester.tap(find.text('Friend'));
    await app.settle();
    await tester.tap(find.byTooltip('Delete type'));
    await tester.pumpAndSettle();

    expect(find.text('1 bubble loses this type.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await app.settle();

    final s = await app.snapshot();
    expect(s.nodeTypes.byId.containsKey(friend), isFalse);
    expect(s.nodes[sam]!.typeIds, [partner]);
  });

  testWidgets('built-in types can be edited but not deleted', (tester) async {
    final app = await AppHarness.start(tester);
    await openTypes(app);
    await tester.tap(find.text('Thing').first);
    await app.settle();
    expect(find.text('Edit type'), findsOneWidget);
    expect(find.byTooltip('Delete type'), findsNothing);
  });

  testWidgets('item style: overrides save, and Reset to type clears them', (
    tester,
  ) async {
    final app = await AppHarness.start(
      tester,
      seed: seedTypes,
      startOnList: true,
    );
    // Swipe right on the row for Edit.
    await tester.drag(find.text('Sam'), const Offset(300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await app.settle();
    await tester.tap(find.text('Bubble style…'));
    await app.settle();
    expect(find.text('Style: Sam'), findsOneWidget);

    // Person makes it bold; switch that off for Sam alone.
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('field-bold')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await app.settle();

    var s = await app.snapshot();
    expect(s.nodes[sam]!.overrides, const NodeStyle(bold: false));
    expect(s.styleOf(s.nodes[sam]!).bold, isFalse);
    expect(s.styleOf(s.nodes[sam]!).outlineColor, pink, reason: 'type kept');

    await tester.tap(find.text('Bubble style…'));
    await app.settle();
    await tester.tap(find.text('Reset to type'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await app.settle();
    s = await app.snapshot();
    expect(s.nodes[sam]!.overrides, NodeStyle.empty);
  });

  testWidgets('a line type can be restyled, hierarchy included', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await openTypes(app);
    await tester.tap(find.text('Line types'));
    await app.settle();
    await tester.tap(find.text('Likes'));
    await app.settle();

    final hierarchy = find.descendant(
      of: find.byKey(const ValueKey('field-hierarchical')),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(hierarchy).value, isTrue, reason: 'inherited');
    await tester.tap(hierarchy);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await app.settle();

    final s = await app.snapshot();
    expect(s.edgeTypes.byId[SeedIds.likes]!.style.hierarchical, isFalse);
    expect(
      s.edgeTypes.resolve([SeedIds.loves]).hierarchical,
      isFalse,
      reason: 'Loves inherits it',
    );
  });
}
