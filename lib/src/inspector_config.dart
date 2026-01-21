/// Global configuration for inspector behavior.
///
/// Uses static fields to avoid passing config through widget trees,
/// making it easy to toggle features at runtime during development.
class UiInspectorConfig {
  /// Master switch for all inspector features.
  ///
  /// When false, all inspector widgets return their children unchanged,
  /// providing a quick way to disable inspection without removing widgets.
  static bool enabled = true;

  /// Whether to show rebuild count badges on tracked widgets.
  static bool showRebuildCount = true;

  /// Whether to show UI state badges (loading/error/empty/ready).
  static bool showStateBadge = true;

  /// Whether to track frame timings and calculate FPS.
  ///
  /// Enabling this subscribes to [SchedulerBinding.addTimingsCallback],
  /// which has minimal overhead but should only be enabled when needed.
  static bool trackPerformance = false;

  /// Whether to render the rebuild intensity heatmap overlay.
  static bool enableHeatmap = false;

  /// Rebuild count threshold that triggers red badge coloring.
  ///
  /// Widgets exceeding this threshold are highlighted in red to quickly
  /// identify potential performance issues from excessive rebuilds.
  static int rebuildWarningThreshold = 10;

  /// Frame duration threshold (ms) for classifying frames as janky.
  ///
  /// Frames exceeding build+raster time of this value are counted as jank,
  /// helping identify performance degradation during development.
  static double jankFrameThresholdMs = 16.0;
}
