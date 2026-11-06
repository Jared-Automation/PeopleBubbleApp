import 'dart:math';

import '../data/seed.dart';
import '../domain/style.dart';
import 'graph_service.dart';

/// Made-up people and likes for development. Debug builds only; never real
/// data. Replaces everything currently in the database.
Future<void> loadSampleData(GraphService g) async {
  await g.clearAllData();

  final partner = await g.createNodeType(
    name: 'Partner',
    parentId: SeedIds.person,
    style: const NodeStyle(outlineColor: 0xFFE91E63, fontFamily: 'serif'),
  );
  final gamer = await g.createNodeType(
    name: 'Board Gamer',
    parentId: SeedIds.person,
    style: const NodeStyle(outlineStyle: LineStyle.dotted),
  );
  final friend = await g.createNodeType(
    name: 'Friend',
    parentId: SeedIds.person,
    style: const NodeStyle(outlineColor: 0xFF1E88E5),
  );
  final family = await g.createNodeType(
    name: 'Family',
    parentId: SeedIds.person,
    style: const NodeStyle(outlineColor: 0xFF8E24AA),
  );

  const likes = SeedIds.likes;
  const loves = SeedIds.loves;
  const dislikes = SeedIds.dislikes;
  const related = SeedIds.related;

  Future<String> person(String label, [List<String> types = const []]) =>
      g.createNode(label: label, typeIds: [SeedIds.person, ...types]);
  // Each thing is created together with its first line, like the add sheet
  // does, so the data is never in a half-linked state.
  Future<String> thing(
    String parent,
    String type,
    String label, [
    String? lineLabel,
  ]) async => (await g.createChildNode(
    parentId: parent,
    label: label,
    typeIds: [SeedIds.thing],
    edgeTypeId: type,
    edgeLabel: lineLabel,
  )).nodeId;
  Future<void> link(String from, String to, String type, [String? label]) =>
      g.createEdge(sourceId: from, targetId: to, typeId: type, label: label);

  final sam = await person('Sam', [partner, gamer]);
  final priya = await person('Priya', [friend, gamer]);
  final alex = await person('Alex', [friend]);
  final jordan = await person('Jordan', [friend]);
  final leo = await person('Leo', [friend, gamer]);
  final mia = await person('Mia', [family]);
  final rose = await person('Nana Rose', [family]);
  final theo = await person('Theo');

  // Shared things: one Sushi node under both Sam and Priya, and so on.
  final sushi = await thing(sam, loves, 'Sushi');
  await link(priya, sushi, likes);
  final cilantro = await thing(sam, dislikes, 'Cilantro');
  await link(leo, cilantro, dislikes);
  final coffee = await thing(sam, loves, 'Coffee');
  await thing(coffee, likes, 'Oat milk flat white', 'usually');
  final boardGames = await thing(sam, likes, 'Board games');
  await link(priya, boardGames, likes);
  await link(leo, boardGames, loves);
  await thing(boardGames, likes, 'Catan');
  await thing(boardGames, loves, 'Wingspan');
  await thing(boardGames, dislikes, 'Monopoly');
  final hiking = await thing(alex, loves, 'Hiking');
  await link(jordan, hiking, likes);
  final horror = await thing(jordan, loves, 'Horror movies');
  await link(mia, horror, dislikes);
  final sunflowers = await thing(rose, loves, 'Sunflowers');
  await link(mia, sunflowers, likes);
  await thing(theo, likes, 'Jazz');
  final spicy = await thing(priya, loves, 'Spicy food');
  await link(theo, spicy, dislikes);

  // Non-hierarchical links: shown as shadow rows in the list (Phase 3).
  await link(alex, jordan, related, 'siblings');
  await link(mia, rose, related, 'grandma');
  await link(sam, priya, related, 'best friends');
}

/// [people] people with [thingsPerPerson] things each (300 bubbles by
/// default), plus a couple of shared links per person, for the performance
/// check. Deterministic, so runs are comparable.
Future<void> loadLargeSample(
  GraphService g, {
  int people = 50,
  int thingsPerPerson = 5,
  int sharedPerPerson = 2,
}) async {
  await g.clearAllData();
  final random = Random(42);
  const edgeTypes = [SeedIds.likes, SeedIds.loves, SeedIds.dislikes];
  String anyType() => edgeTypes[random.nextInt(edgeTypes.length)];

  final things = <String>[];
  final ownThings = <String, Set<String>>{};
  for (var p = 0; p < people; p++) {
    final id = await g.createNode(
      label: 'Person ${p + 1}',
      typeIds: [SeedIds.person],
    );
    final mine = ownThings[id] = {};
    for (var t = 0; t < thingsPerPerson; t++) {
      final (:nodeId, edgeId: _) = await g.createChildNode(
        parentId: id,
        label: 'Thing ${things.length + 1}',
        typeIds: [SeedIds.thing],
        edgeTypeId: anyType(),
      );
      things.add(nodeId);
      mine.add(nodeId);
    }
    // Share a few things made by earlier people.
    for (var s = 0; s < sharedPerPerson && things.length > mine.length; s++) {
      final other = things[random.nextInt(things.length)];
      if (mine.add(other)) {
        await g.createEdge(sourceId: id, targetId: other, typeId: anyType());
      }
    }
  }
}
