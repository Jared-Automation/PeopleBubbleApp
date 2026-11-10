import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/style.dart';
import '../canvas/canvas_layout_cache.dart';
import '../canvas/graph_painter.dart';

/// How a style field is edited.
enum FieldKind { color, number, toggle, choice }

/// One editable style field. [key] matches the style's JSON / `setFields`
/// names, so the editor works on plain maps for both bubbles and lines.
class StyleFieldSpec {
  const StyleFieldSpec(
    this.key,
    this.label,
    this.kind, {
    this.choices = const [],
    this.min = 0,
    this.max = 1,
    this.step = 1,
  });

  final String key;
  final String label;
  final FieldKind kind;

  /// For [FieldKind.choice]: stored value → shown name.
  final List<(Object, String)> choices;
  final double min, max, step;
}

/// Android's built-in font families. No downloads or bundled files.
const fontChoices = <(Object, String)>[
  ('Roboto', 'Default'),
  ('serif', 'Serif'),
  ('monospace', 'Monospace'),
  ('cursive', 'Handwriting'),
  ('casual', 'Casual'),
];

const _lineStyleChoices = <(Object, String)>[
  ('solid', 'Solid'),
  ('dotted', 'Dotted'),
  ('dashed', 'Dashed'),
];

const nodeStyleFields = [
  StyleFieldSpec('fontFamily', 'Font', FieldKind.choice, choices: fontChoices),
  StyleFieldSpec('fontColor', 'Text colour', FieldKind.color),
  StyleFieldSpec('fontSize', 'Text size', FieldKind.number, min: 8, max: 40),
  StyleFieldSpec('bold', 'Bold', FieldKind.toggle),
  StyleFieldSpec(
    'shape',
    'Shape',
    FieldKind.choice,
    choices: [
      ('roundedRect', 'Rounded'),
      ('rectangle', 'Rectangle'),
      ('ellipse', 'Oval'),
      ('circle', 'Circle'),
    ],
  ),
  StyleFieldSpec(
    'width',
    'Min width',
    FieldKind.number,
    min: 40,
    max: 300,
    step: 4,
  ),
  StyleFieldSpec(
    'height',
    'Min height',
    FieldKind.number,
    min: 24,
    max: 200,
    step: 4,
  ),
  StyleFieldSpec('fillColor', 'Fill', FieldKind.color),
  StyleFieldSpec('outlineColor', 'Outline colour', FieldKind.color),
  StyleFieldSpec(
    'outlineWidth',
    'Outline width',
    FieldKind.number,
    max: 8,
    step: 0.5,
  ),
  StyleFieldSpec(
    'outlineStyle',
    'Outline style',
    FieldKind.choice,
    choices: _lineStyleChoices,
  ),
  StyleFieldSpec('hidden', 'Hide what’s under it', FieldKind.toggle),
];

/// Line fields. [withHierarchy] adds the hierarchical switch, which only
/// types may set (not single lines).
List<StyleFieldSpec> edgeStyleFields({required bool withHierarchy}) => [
  const StyleFieldSpec('color', 'Colour', FieldKind.color),
  const StyleFieldSpec(
    'width',
    'Width',
    FieldKind.number,
    min: 0.5,
    max: 10,
    step: 0.5,
  ),
  const StyleFieldSpec(
    'lineStyle',
    'Line style',
    FieldKind.choice,
    choices: _lineStyleChoices,
  ),
  const StyleFieldSpec(
    'arrowhead',
    'Arrowhead',
    FieldKind.choice,
    choices: [('none', 'None'), ('end', 'At the child')],
  ),
  if (withHierarchy)
    const StyleFieldSpec('hierarchical', 'Parent → child', FieldKind.toggle),
];

/// Edits the fields set at one layer (a type, or one item's overrides).
///
/// [own] holds what this layer sets; [inherited] holds the value each field
/// would have without it. Unset fields show the inherited value greyed out
/// with "inherited"; changing one sets it here, and the reset button clears
/// it again.
class StyleFieldsEditor extends StatelessWidget {
  const StyleFieldsEditor({
    super.key,
    required this.fields,
    required this.own,
    required this.inherited,
    required this.onChanged,
  });

  final List<StyleFieldSpec> fields;
  final Map<String, Object> own;
  final Map<String, Object> inherited;
  final ValueChanged<Map<String, Object>> onChanged;

  void _set(String key, Object? value) {
    final next = {...own};
    if (value == null) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final f in fields)
          _FieldRow(
            spec: f,
            value: own[f.key] ?? inherited[f.key],
            isSet: own.containsKey(f.key),
            onChanged: (v) => _set(f.key, v),
            onReset: () => _set(f.key, null),
            muted: theme.colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.spec,
    required this.value,
    required this.isSet,
    required this.onChanged,
    required this.onReset,
    required this.muted,
  });

  final StyleFieldSpec spec;
  final Object? value;
  final bool isSet;
  final ValueChanged<Object> onChanged;
  final VoidCallback onReset;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: isSet ? 1 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 116,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec.label, style: theme.textTheme.bodyMedium),
                  if (!isSet)
                    Text(
                      'inherited',
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey('field-${spec.key}'),
                child: _control(context),
              ),
            ),
            SizedBox(
              width: 48,
              child: isSet
                  ? IconButton(
                      tooltip: 'Inherit ${spec.label.toLowerCase()}',
                      icon: const Icon(Icons.undo, size: 20),
                      onPressed: onReset,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _control(BuildContext context) {
    switch (spec.kind) {
      case FieldKind.color:
        final color = value is int ? value! as int : 0xFF9E9E9E;
        return Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              final picked = await showColorPicker(
                context,
                title: spec.label,
                initial: color,
              );
              if (picked != null) onChanged(picked);
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _Swatch(color: color, size: 32),
            ),
          ),
        );
      case FieldKind.number:
        final v = (value is num ? (value! as num).toDouble() : spec.min)
            .clamp(spec.min, spec.max)
            .toDouble();
        final divisions = ((spec.max - spec.min) / spec.step).round();
        return Row(
          children: [
            Expanded(
              child: Slider(
                value: v,
                min: spec.min,
                max: spec.max,
                divisions: divisions,
                label: _formatNumber(v),
                onChanged: (x) => onChanged(x),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(_formatNumber(v), textAlign: TextAlign.end),
            ),
          ],
        );
      case FieldKind.toggle:
        return Align(
          alignment: Alignment.centerLeft,
          child: Switch(value: value == true, onChanged: (x) => onChanged(x)),
        );
      case FieldKind.choice:
        final known = spec.choices.any((c) => c.$1 == value);
        return DropdownButton<Object>(
          isExpanded: true,
          value: known ? value : null,
          hint: Text(value?.toString() ?? ''),
          items: [
            for (final (v, name) in spec.choices)
              DropdownMenuItem(
                value: v,
                child: Text(
                  name,
                  style: spec.key == 'fontFamily'
                      ? TextStyle(fontFamily: v as String)
                      : null,
                ),
              ),
          ],
          onChanged: (x) {
            if (x != null) onChanged(x);
          },
        );
    }
  }
}

String _formatNumber(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, this.size = 36, this.selected = false});

  final int color;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(color),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 3 : 1,
        ),
      ),
    );
  }
}

/// Preset colours: Material's main hues plus greys, black and white.
const presetColors = <int>[
  0xFFE91E63, 0xFFF44336, 0xFFFF9800, 0xFFFFC107, 0xFFFFEB3B, //
  0xFF8BC34A, 0xFF4CAF50, 0xFF009688, 0xFF00BCD4, 0xFF2196F3,
  0xFF3F51B5, 0xFF673AB7, 0xFF9C27B0, 0xFF795548, 0xFF607D8B,
  0xFFFFFFFF, 0xFFE0E0E0, 0xFF9E9E9E, 0xFF616161, 0xFF212121,
];

/// Parses "#RRGGBB", "RRGGBB" or "AARRGGBB" into an ARGB int.
int? parseHexColor(String text) {
  var hex = text.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  return int.tryParse(hex, radix: 16);
}

String hexOf(int color) =>
    '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// A grid of preset swatches plus a hex field. Returns the chosen ARGB
/// colour, or null if cancelled.
Future<int?> showColorPicker(
  BuildContext context, {
  required String title,
  required int initial,
}) => showDialog<int>(
  context: context,
  builder: (_) => _ColorPickerDialog(title: title, initial: initial),
);

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.title, required this.initial});

  final String title;
  final int initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late int _color = widget.initial;
  late final _hex = TextEditingController(text: hexOf(widget.initial));

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in presetColors)
                  Semantics(
                    button: true,
                    label: hexOf(c),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() {
                        _color = c;
                        _hex.text = hexOf(c);
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: _Swatch(color: c, selected: c == _color),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Swatch(color: _color),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hex,
                    decoration: const InputDecoration(labelText: 'Hex'),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                    ],
                    onChanged: (t) {
                      final c = parseHexColor(t);
                      if (c != null) setState(() => _color = c);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('Use colour'),
        ),
      ],
    );
  }
}

/// A bubble drawn exactly as on the canvas, for previews.
class BubblePreview extends StatefulWidget {
  const BubblePreview({super.key, required this.style, required this.label});

  /// A fully resolved style (every field set).
  final NodeStyle style;
  final String label;

  @override
  State<BubblePreview> createState() => _BubblePreviewState();
}

class _BubblePreviewState extends State<BubblePreview> {
  final _cache = CanvasLayoutCache();

  @override
  void dispose() {
    _cache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = _cache.node(widget.label, widget.style);
    return CustomPaint(
      size: Size(layout.size.width + 8, layout.size.height + 8),
      painter: _BubblePainter(widget.style, layout),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.style, this.layout);

  final NodeStyle style;
  final NodeLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final w = layout.size.width, h = layout.size.height;
    paintBubble(
      canvas,
      style,
      Rectangle((size.width - w) / 2, (size.height - h) / 2, w, h),
      layout.text,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.style != style || old.layout != layout;
}

/// A short sample of a line in [style], for previews.
class LinePreview extends StatelessWidget {
  const LinePreview({super.key, required this.style, this.width = 72});

  final EdgeStyle style;
  final double width;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(width, 24), painter: _LinePainter(style));
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.style);

  final EdgeStyle style;

  @override
  void paint(Canvas canvas, Size size) => paintLineSample(
    canvas,
    style,
    Offset(4, size.height / 2),
    Offset(size.width - 4, size.height / 2),
  );

  @override
  bool shouldRepaint(_LinePainter old) => old.style != style;
}
