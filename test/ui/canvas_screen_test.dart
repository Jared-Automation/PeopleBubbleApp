import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_bubble/domain/geometry.dart';
import 'package:people_bubble/services/sample_data.dart';
import 'package:people_bubble/ui/canvas/canvas_layout_cache.dart';
import 'package:people_bubble/ui/canvas/graph_painter.dart';

import 'harness.dart';

void main() {
  testWidgets('places the sample data without overlaps and paints it', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, seed: loadSampleData);

    // Placement runs once writes have paused (a 400 ms debounce on the fake
    // test clock), even while the canvas sits behind the List.
    await tester.pump(const Duration(milliseconds: 500));
    await app.settle();
    final s = await app.snapshot();
    expect(s.nodes.values.where((n) => !n.isPlaced), isEmpty);

    // No two bubbles overlap, using the same sizes the painter uses.
    final cache = CanvasLayoutCache();
    addTearDown(cache.dispose);
    final boxes = [
      for (final n in s.nodes.values)
        (
          n.label,
          boxAt(Point(n.x!, n.y!), cache.node(n.label, s.styleOf(n)).size),
        ),
    ];
    for (var i = 0; i < boxes.length; i++) {
      for (var j = i + 1; j < boxes.length; j++) {
        expect(
          overlapArea(boxes[i].$2, boxes[j].$2),
          0,
          reason: '${boxes[i].$1} overlaps ${boxes[j].$1}',
        );
      }
    }

    await tester.tap(find.text('Bubbles'));
    await app.settle();
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<GraphPainter>()
        .single;
    expect(painter.snapshot.nodes.length, s.nodes.length);

    await tester.tap(find.byTooltip('Zoom to fit'));
    await app.settle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('zoom to fit shows every bubble at a real zoom level', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, seed: loadLargeSample);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    await tester.pump(const Duration(milliseconds: 500));
    await app.settle();
    await tester.tap(find.text('Bubbles'));
    await app.settle();
    await tester.tap(find.byTooltip('Zoom to fit'));
    await app.settle();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final m = viewer.transformationController!.value;
    // 300 bubbles span thousands of units; fitting a phone means zooming out.
    expect(m.getMaxScaleOnAxis(), lessThan(0.5));

    // Every bubble centre lands inside the visible canvas.
    final canvasBox = tester.getRect(find.byType(InteractiveViewer));
    final s = await app.snapshot();
    for (final n in s.nodes.values) {
      final p = MatrixUtils.transformPoint(
        m,
        Offset(n.x! + 100000, n.y! + 100000),
      );
      expect(
        Rect.fromLTWH(0, 0, canvasBox.width, canvasBox.height).contains(p),
        isTrue,
        reason: '${n.label} at $p is off screen',
      );
    }
  });
}
