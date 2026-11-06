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

  Future<String> person(String label, [List<String> types = const []]) =>
      g.createNode(label: label, typeIds: [SeedIds.person, ...types]);
  Future<String> thing(String label) =>
      g.createNode(label: label, typeIds: [SeedIds.thing]);
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

  final sushi = await thing('Sushi');
  final cilantro = await thing('Cilantro');
  final coffee = await thing('Coffee');
  final flatWhite = await thing('Oat milk flat white');
  final boardGames = await thing('Board games');
  final catan = await thing('Catan');
  final wingspan = await thing('Wingspan');
  final monopoly = await thing('Monopoly');
  final hiking = await thing('Hiking');
  final horror = await thing('Horror movies');
  final sunflowers = await thing('Sunflowers');
  final jazz = await thing('Jazz');
  final spicy = await thing('Spicy food');

  const likes = SeedIds.likes;
  const loves = SeedIds.loves;
  const dislikes = SeedIds.dislikes;
  const related = SeedIds.related;

  // Shared things: one Sushi node under both Sam and Priya, and so on.
  await link(sam, sushi, loves);
  await link(priya, sushi, likes);
  await link(sam, cilantro, dislikes);
  await link(leo, cilantro, dislikes);
  await link(sam, coffee, loves);
  await link(coffee, flatWhite, likes, 'usually');
  await link(sam, boardGames, likes);
  await link(priya, boardGames, likes);
  await link(leo, boardGames, loves);
  await link(boardGames, catan, likes);
  await link(boardGames, wingspan, loves);
  await link(boardGames, monopoly, dislikes);
  await link(alex, hiking, loves);
  await link(jordan, hiking, likes);
  await link(jordan, horror, loves);
  await link(mia, horror, dislikes);
  await link(rose, sunflowers, loves);
  await link(mia, sunflowers, likes);
  await link(theo, jazz, likes);
  await link(priya, spicy, loves);
  await link(theo, spicy, dislikes);

  // Non-hierarchical links: shown as shadow rows in the list (Phase 3).
  await link(alex, jordan, related, 'siblings');
  await link(mia, rose, related, 'grandma');
  await link(sam, priya, related, 'best friends');
}

/// About [people] × (1 + [likesPerPerson]) nodes with shared things, for the
/// performance check. Deterministic, so runs are comparable.
Future<void> loadLargeSample(
  GraphService g, {
  int people = 50,
  int likesPerPerson = 5,
}) async {
  await g.clearAllData();
  final random = Random(42);
  final things = [
    for (var i = 0; i < people * likesPerPerson; i++)
      await g.createNode(label: 'Thing ${i + 1}', typeIds: [SeedIds.thing]),
  ];
  const edgeTypes = [SeedIds.likes, SeedIds.loves, SeedIds.dislikes];
  for (var p = 0; p < people; p++) {
    final id = await g.createNode(
      label: 'Person ${p + 1}',
      typeIds: [SeedIds.person],
    );
    final picked = <String>{};
    while (picked.length < likesPerPerson) {
      picked.add(things[random.nextInt(things.length)]);
    }
    for (final thing in picked) {
      await g.createEdge(
        sourceId: id,
        targetId: thing,
        typeId: edgeTypes[random.nextInt(edgeTypes.length)],
      );
    }
  }
}
