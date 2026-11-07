import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/radial_menu.dart';

/// One slice of the wheel.
class WheelItem {
  const WheelItem({
    required this.label,
    required this.icon,
    this.onSelected,
    this.more,
    this.comingSoon = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onSelected;

  /// Set for the "More" slice: these open as an outer ring.
  final List<WheelItem>? more;

  /// Shown greyed out with "soon", so slice positions never shift when the
  /// feature arrives.
  final bool comingSoon;

  bool get isMore => more != null;
}

/// The wheel itself, drawn over the canvas around [center]. It only draws;
/// the canvas decides which slot is [hovered] while a finger slides. Taps
/// (once the finger has lifted and the wheel stayed open) go to [onTap], with
/// null for the centre or anywhere outside the wheel.
class RadialWheel extends StatelessWidget {
  const RadialWheel({
    super.key,
    required this.center,
    required this.title,
    required this.items,
    required this.onTap,
    this.hovered,
    this.moreOpen = false,
    this.geometry = const RadialGeometry(),
  });

  final Offset center;
  final String title;
  final List<WheelItem> items;
  final WheelSlot? hovered;
  final bool moreOpen;
  final ValueChanged<WheelSlot?> onTap;
  final RadialGeometry geometry;

  int? get moreIndex {
    final i = items.indexWhere((item) => item.isMore);
    return i < 0 ? null : i;
  }

  List<WheelItem> get outerItems =>
      moreOpen && moreIndex != null ? items[moreIndex!].more! : const [];

  /// The slot at [local] (relative to the whole overlay), or null.
  WheelSlot? slotAt(Offset local) {
    final d = local - center;
    if (d.distance > geometry.outerRadius + 24) return null;
    if (!moreOpen && d.distance > geometry.innerRadius + 24) return null;
    return geometry.slotAt(
      d.dx,
      d.dy,
      innerCount: items.length,
      outerCount: moreOpen ? outerItems.length : null,
      moreIndex: moreOpen ? moreIndex : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final iconRadius = (geometry.deadZone + geometry.innerRadius) / 2;
    final outerIconRadius = (geometry.innerRadius + geometry.outerRadius) / 2;

    Widget label(WheelItem item, double angle, double radius, bool isHovered) {
      final enabled = item.onSelected != null || item.isMore;
      final color = !enabled || item.comingSoon
          ? colors.onSurface.withValues(alpha: 0.38)
          : isHovered
          ? colors.onPrimaryContainer
          : colors.onSurface;
      return Positioned(
        left: center.dx + radius * cos(angle) - 36,
        top: center.dy + radius * sin(angle) - 24,
        width: 72,
        height: 48,
        child: IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 22, color: color),
              Text(
                item.comingSoon ? '${item.label} (soon)' : item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Taps anywhere: a slot, or outside/centre to close.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onTap(slotAt(d.localPosition)),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WheelPainter(
                center: center,
                geometry: geometry,
                innerCount: items.length,
                outerCount: outerItems.length,
                moreIndex: moreIndex,
                hovered: hovered,
                surface: colors.surfaceContainerHigh,
                outerSurface: colors.surfaceContainerHighest,
                hoverColor: colors.primaryContainer,
                divider: colors.outlineVariant,
                shadow: theme.shadowColor,
              ),
            ),
          ),
        ),
        for (final (i, item) in items.indexed)
          label(
            item,
            RadialGeometry.sliceCenter(i, items.length),
            iconRadius,
            hovered == (ring: 0, index: i),
          ),
        for (final (i, item) in outerItems.indexed)
          label(
            item,
            RadialGeometry.outerCenter(
              i,
              outerCount: outerItems.length,
              moreIndex: moreIndex!,
              innerCount: items.length,
            ),
            outerIconRadius,
            hovered == (ring: 1, index: i),
          ),
        // The item's name in the middle; lifting there keeps the wheel open.
        Positioned(
          left: center.dx - geometry.deadZone,
          top: center.dy - geometry.deadZone,
          width: 2 * geometry.deadZone,
          height: 2 * geometry.deadZone,
          child: IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.center,
    required this.geometry,
    required this.innerCount,
    required this.outerCount,
    required this.moreIndex,
    required this.hovered,
    required this.surface,
    required this.outerSurface,
    required this.hoverColor,
    required this.divider,
    required this.shadow,
  });

  final Offset center;
  final RadialGeometry geometry;
  final int innerCount;
  final int outerCount;
  final int? moreIndex;
  final WheelSlot? hovered;
  final Color surface, outerSurface, hoverColor, divider, shadow;

  Path _slice(double from, double sweep, double inner, double outer) => Path()
    ..arcTo(Rect.fromCircle(center: center, radius: outer), from, sweep, true)
    ..arcTo(
      Rect.fromCircle(center: center, radius: inner),
      from + sweep,
      -sweep,
      false,
    )
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final width = RadialGeometry.sliceAngle(innerCount);
    final gap = 0.02;

    // Main ring.
    final ring = Path()
      ..addOval(Rect.fromCircle(center: center, radius: geometry.innerRadius));
    canvas.drawShadow(ring, shadow, 6, true);
    canvas.drawPath(ring, Paint()..color = surface);
    for (var i = 0; i < innerCount; i++) {
      final start = RadialGeometry.sliceCenter(i, innerCount) - width / 2;
      if (hovered == (ring: 0, index: i)) {
        canvas.drawPath(
          _slice(
            start + gap,
            width - 2 * gap,
            geometry.deadZone,
            geometry.innerRadius - 4,
          ),
          Paint()..color = hoverColor,
        );
      }
      final edge = Offset(cos(start), sin(start));
      canvas.drawLine(
        center + edge * geometry.deadZone,
        center + edge * geometry.innerRadius,
        Paint()
          ..color = divider
          ..strokeWidth = 1,
      );
    }
    canvas.drawCircle(
      center,
      geometry.deadZone,
      Paint()
        ..color = divider
        ..style = PaintingStyle.stroke,
    );

    // "More" ring: an arc of slots centred on the More slice.
    final more = moreIndex;
    if (more == null || outerCount == 0) return;
    for (var i = 0; i < outerCount; i++) {
      final mid = RadialGeometry.outerCenter(
        i,
        outerCount: outerCount,
        moreIndex: more,
        innerCount: innerCount,
      );
      final path = _slice(
        mid - width / 2 + gap,
        width - 2 * gap,
        geometry.innerRadius + 4,
        geometry.outerRadius,
      );
      canvas.drawShadow(path, shadow, 4, true);
      canvas.drawPath(
        path,
        Paint()
          ..color = hovered == (ring: 1, index: i) ? hoverColor : outerSurface,
      );
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.center != center ||
      old.hovered != hovered ||
      old.innerCount != innerCount ||
      old.outerCount != outerCount ||
      old.surface != surface;
}
