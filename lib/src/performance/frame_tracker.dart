import 'package:flutter/scheduler.dart';
import '../debug_guard.dart';
import '../inspector_config.dart';

/// Tracks frame timing metrics for performance analysis.
///
/// Subscribes to [SchedulerBinding.addTimingsCallback] to measure frame
/// durations and calculate FPS. Uses throttled pruning to minimize overhead
/// while maintaining accurate rolling averages over the last second.
class FrameTracker {
  FrameTracker._();

  static bool _listening = false;
  static int _totalJankFrames = 0;
  static int _totalSlowFrames = 0;
  static final List<DateTime> _frameTimes = <DateTime>[];
  static DateTime _lastPrune = DateTime.fromMillisecondsSinceEpoch(0);

  static bool get _active =>
      DebugGuard.enabled && UiInspectorConfig.trackPerformance;

  /// Begins tracking frame timings.
  ///
  /// Idempotent - safe to call multiple times. Only subscribes to timings
  /// callback when [UiInspectorConfig.trackPerformance] is enabled.
  static void start() {
    if (_listening) return;
    if (!_active) return;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _listening = true;
  }

  /// Stops tracking frame timings.
  ///
  /// Future frame timings will be ignored until [start] is called again.
  static void stop() {
    _listening = false;
  }

  static void _onTimings(List<FrameTiming> timings) {
    if (!_listening || !_active) return;

    final now = DateTime.now();
    // Throttle pruning work to at most ~60Hz (every ~16ms).
    final shouldPrune = now.difference(_lastPrune).inMilliseconds > 16;

    for (final timing in timings) {
      final buildMs = timing.buildDuration.inMilliseconds;
      final rasterMs = timing.rasterDuration.inMilliseconds;
      final totalMs = buildMs + rasterMs;

      if (totalMs > UiInspectorConfig.jankFrameThresholdMs) {
        _totalJankFrames++;
      }
      if (totalMs > 16) {
        _totalSlowFrames++;
      }

      _frameTimes.add(now);
    }

    if (shouldPrune) {
      _pruneOldFrames(now);
      _lastPrune = now;
    }
  }

  static void _pruneOldFrames(DateTime now) {
    final cutoff = now.subtract(const Duration(seconds: 1));
    while (_frameTimes.isNotEmpty && _frameTimes.first.isBefore(cutoff)) {
      _frameTimes.removeAt(0);
    }
  }

  /// Current frames per second calculated over the last second.
  ///
  /// Automatically prunes old frame timestamps before calculation to ensure
  /// accuracy. Returns 0 if no frames have been tracked yet.
  static double get fps {
    if (_frameTimes.isEmpty) return 0;
    final now = DateTime.now();
    _pruneOldFrames(now);
    final spanMs =
        (_frameTimes.last.millisecondsSinceEpoch -
                _frameTimes.first.millisecondsSinceEpoch)
            .clamp(1, 1000);
    return (_frameTimes.length * 1000) / spanMs;
  }

  /// Total count of frames that exceeded 16ms (build + raster time).
  ///
  /// Helps identify general performance degradation beyond the jank threshold.
  static int get totalSlowFrames => _totalSlowFrames;

  /// Total count of frames exceeding [UiInspectorConfig.jankFrameThresholdMs].
  ///
  /// Janky frames cause visible stuttering and are a key performance metric.
  static int get totalJankFrames => _totalJankFrames;
}
