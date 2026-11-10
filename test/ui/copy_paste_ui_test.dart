import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/graph.dart';

import 'canvas_helpers.dart';

/// A fake system clipboard: Copy writes it, Paste reads it.
String? fakeClipboard;

void mockClipboard(WidgetTester tester) {
  fakeClipboard = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          fakeClipboard = (call.arguments as Map)['text'] as String?;
          return null;
        case 'Clipboard.getData':
          return {'text': fakeClipboard};
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

/// Long-presses world point [at], then picks [labels] in turn.
Future<void> wheel(
  WidgetTester tester,
  Point<double> at,
  List<String> labels,
) async {
  final finger = await longPress(tester, screenOf(tester, at));
  await finger.up();
  await tester.pumpAndSettle();
  for (final label in labels) {
    await tester.tapAt(slice(tester, label));
    await tester.pumpAndSettle();
  }
}

Iterable<GraphNode> named(GraphSnapshot s, String label) =>
    s.nodes.values.where((n) => n.label == label);

void main() {
  testWidgets('canvas: Copy, then Paste under another bubble', (tester) async {
    mockClipboard(tester);
    final app = await openCanvas(tester);

    // Before copying, there's no Paste under.
    await wheel(tester, const Point(0, 0), ['More']);
    expect(
      wheelOf(tester).items
          .firstWhere((i) => i.isMore)
          .more!
          .map((i) => i.label),
      isNot(contains('Paste under')),
    );
    await tester.tapAt(slice(tester, 'Copy'));
    await tester.pumpAndSettle();
    expect(find.text('Copied “Sam” and 1 under it'), findsOneWidget);
    expect(fakeClipboard, 'Sam\n  Sushi');

    // Jazz is at (600, 0).
    await wheel(tester, const Point(600, 0), ['More', 'Paste under']);
    await app.settle();

    final s = await app.snapshot();
    final samCopy = named(s, 'Sam').firstWhere((n) => n.id != sam);
    final jazz = named(s, 'Jazz').single;
    expect(
      s.edges.values.any(
        (e) => e.sourceId == jazz.id && e.targetId == samCopy.id,
      ),
      isTrue,
    );
    expect(named(s, 'Sushi').length, 2);
    expect(find.text('Pasted “Sam” under “Jazz”'), findsOneWidget);
  });

  testWidgets('canvas: empty-space Paste uses the copy while it is on the '
      'clipboard', (tester) async {
    mockClipboard(tester);
    final app = await openCanvas(tester);
    await wheel(tester, const Point(0, 0), ['More', 'Copy']);

    await wheel(tester, const Point(300, 500), ['Paste']);
    await app.settle();
    var s = await app.snapshot();
    final samCopy = named(s, 'Sam').firstWhere((n) => n.id != sam);
    expect(samCopy.x, closeTo(300, 1));
    expect(samCopy.y, closeTo(500, 1));
    expect(named(s, 'Sushi').length, 2, reason: 'the whole group');

    // Text copied elsewhere since wins: one bubble per line, as before.
    fakeClipboard = 'Zed';
    await wheel(tester, const Point(600, 400), ['Paste']);
    await app.settle();
    s = await app.snapshot();
    expect(named(s, 'Zed').length, 1);
    expect(named(s, 'Sam').length, 2, reason: 'no third Sam');
  });

  testWidgets('list: swipe right to Copy, then Paste under another row', (
    tester,
  ) async {
    mockClipboard(tester);
    final app = await openCanvas(tester);
    await tester.tap(find.text('List'));
    await app.settle();

    Future<void> swipeRight(String label) async {
      await tester.drag(find.text(label).first, const Offset(400, 0));
      await tester.pumpAndSettle();
    }

    await swipeRight('Sam');
    expect(find.text('Paste'), findsNothing, reason: 'nothing copied yet');
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    await swipeRight('Jazz');
    await tester.tap(find.text('Paste'));
    await app.settle();

    final s = await app.snapshot();
    expect(named(s, 'Sam').length, 2);
    expect(named(s, 'Sushi').length, 2);
    // Pasted under Jazz, so the list shows it there.
    expect(find.text('Sam'), findsNWidgets(2));
  });
}
