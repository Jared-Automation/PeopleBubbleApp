import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Opt-in frame timing log for performance checks on a real phone:
///
///     flutter run --profile --dart-define=PERF_LOG=true
///
/// Every 120 frames it prints build (UI thread) and raster (GPU thread) times
/// to the device log (`adb logcat | grep PERF`). `GraphService` also logs
/// how long each save takes. A frame must finish both in
/// about 16 ms (60 Hz) or 8 ms (120 Hz) to be smooth.
const perfLogEnabled = bool.fromEnvironment('PERF_LOG');

void startPerfLogIfEnabled() {
  if (!perfLogEnabled) return;
  final batch = <FrameTiming>[];
  SchedulerBinding.instance.addTimingsCallback((timings) {
    batch.addAll(timings);
    if (batch.length < 120) return;
    double ms(Duration d) => d.inMicroseconds / 1000;
    List<double> sorted(Iterable<double> v) => v.toList()..sort();
    final build = sorted(batch.map((t) => ms(t.buildDuration)));
    final raster = sorted(batch.map((t) => ms(t.rasterDuration)));
    String stats(List<double> v) =>
        'p50 ${v[v.length ~/ 2].toStringAsFixed(1)} '
        'p90 ${v[(v.length * 0.9).floor()].toStringAsFixed(1)} '
        'max ${v.last.toStringAsFixed(1)}';
    final slow = batch.where((t) => ms(t.totalSpan) > 16.7).length;
    debugPrint(
      'PERF ${batch.length} frames | build ${stats(build)} ms | '
      'raster ${stats(raster)} ms | over 16.7 ms: $slow',
    );
    batch.clear();
  });
}
