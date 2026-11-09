import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/data/seed.dart';
import 'package:people_bubble/services/graph_service.dart';

import 'harness.dart';

Future<void> seedTwo(GraphService g) async {
  final sam = await g.createNode(label: 'Sam', typeIds: [SeedIds.person]);
  await g.createChildNode(
    parentId: sam,
    label: 'Tea',
    edgeTypeId: SeedIds.likes,
  );
  await g.createNodeType(name: 'Gamer', parentId: SeedIds.person);
}

Future<void> openDeleteAll(AppHarness app) async {
  await app.tester.tap(find.byTooltip('More').last);
  await app.tester.pumpAndSettle();
  await app.tester.tap(find.text('Delete everything'));
  await app.tester.pumpAndSettle();
}

void main() {
  testWidgets('says what goes, deletes on confirm, and can be undone', (
    tester,
  ) async {
    final app = await AppHarness.start(
      tester,
      seed: seedTwo,
      startOnList: true,
    );
    await openDeleteAll(app);

    expect(find.text('Delete everything?'), findsOneWidget);
    expect(
      find.textContaining('all 2 bubbles, 1 line and 1 custom type'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Delete everything'));
    await app.settle();

    var s = await app.snapshot();
    expect(s.nodes, isEmpty);
    expect(
      s.nodeTypes.byId.values.map((t) => t.name),
      isNot(contains('Gamer')),
    );
    expect(s.nodeTypes.byId.containsKey(SeedIds.person), isTrue);
    expect(find.text('No one here yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await app.settle();
    s = await app.snapshot();
    expect(s.nodes.length, 2);
    expect(find.text('Sam'), findsOneWidget);
  });

  testWidgets('Cancel deletes nothing', (tester) async {
    final app = await AppHarness.start(
      tester,
      seed: seedTwo,
      startOnList: true,
    );
    await openDeleteAll(app);
    await tester.tap(find.text('Cancel'));
    await app.settle();
    expect((await app.snapshot()).nodes.length, 2);
  });

  testWidgets('with nothing to delete it just says so', (tester) async {
    final app = await AppHarness.start(tester, startOnList: true);
    await openDeleteAll(app);
    expect(find.text('Delete everything?'), findsNothing);
    expect(find.text('Nothing to delete.'), findsOneWidget);
  });
}
