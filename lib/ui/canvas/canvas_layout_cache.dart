import 'dart:math';

import 'package:flutter/painting.dart';

import '../../domain/geometry.dart';
import '../../domain/style.dart';

/// A bubble's measured size and its laid-out label.
class NodeLayout {
  const NodeLayout(this.size, this.text);

  final BoxSize size;
  final TextPainter text;
}

/// Measures labels once and reuses the result. Text layout is the expensive
/// part of drawing a bubble, and most frames redraw the same labels.
class CanvasLayoutCache {
  static const _hPad = 12.0, _vPad = 8.0, _maxEntries = 4000;

  final _nodes = <(String, NodeStyle), NodeLayout>{};
  final _edgeLabels = <(String, int), TextPainter>{};

  /// Size and label layout for a bubble. The bubble grows to fit its label up
  /// to twice its type's width, then wraps to two lines and ends with "…".
  NodeLayout node(String label, NodeStyle style) {
    final key = (label, style);
    final cached = _nodes[key];
    if (cached != null) return cached;
    if (_nodes.length >= _maxEntries) _clearNodes();

    final minWidth = style.width!, maxWidth = style.width! * 2;
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          color: Color(style.fontColor!),
          fontWeight: style.bold! ? FontWeight.bold : FontWeight.normal,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth - 2 * _hPad);

    var width = (text.width + 2 * _hPad).clamp(minWidth, maxWidth);
    var height = max(style.height!, text.height + 2 * _vPad);
    if (style.shape == NodeShape.circle) width = height = max(width, height);
    if (style.shape == NodeShape.ellipse) {
      // An ellipse's inscribed text area is smaller than its box.
      width = min(maxWidth * 1.2, width * 1.15);
      height *= 1.1;
    }
    return _nodes[key] = NodeLayout((width: width, height: height), text);
  }

  /// A line label in [color], e.g. "siblings".
  TextPainter edgeLabel(String label, int color) {
    final key = (label, color);
    return _edgeLabels[key] ??= TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: 11, color: Color(color)),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 160);
  }

  void _clearNodes() {
    for (final layout in _nodes.values) {
      layout.text.dispose();
    }
    _nodes.clear();
  }

  void dispose() {
    _clearNodes();
    for (final t in _edgeLabels.values) {
      t.dispose();
    }
    _edgeLabels.clear();
  }
}
