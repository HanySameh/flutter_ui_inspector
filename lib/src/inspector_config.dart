import 'package:flutter/foundation.dart';

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

  /// Notifier for rebuild count badge visibility changes.
  ///
  /// Listen to this to reactively update widgets when the setting changes.
  static final ValueNotifier<bool> showRebuildCountNotifier =
      ValueNotifier<bool>(showRebuildCount);

  /// Whether to show UI state badges (loading/error/empty/ready).
  static bool showStateBadge = true;

  /// Notifier for state badge visibility changes.
  ///
  /// Listen to this to reactively update widgets when the setting changes.
  static final ValueNotifier<bool> showStateBadgeNotifier =
      ValueNotifier<bool>(showStateBadge);

  /// Whether to track frame timings and calculate FPS.
  ///
  /// Enabling this subscribes to [SchedulerBinding.addTimingsCallback],
  /// which has minimal overhead but should only be enabled when needed.
  static bool trackPerformance = false;

  /// Whether to render the rebuild intensity heatmap overlay.
  static bool enableHeatmap = false;

  /// Notifier for heatmap visibility changes.
  ///
  /// Listen to this to reactively update widgets when the setting changes.
  static final ValueNotifier<bool> enableHeatmapNotifier =
      ValueNotifier<bool>(enableHeatmap);

  /// Updates [showRebuildCount] and notifies listeners.
  static void setShowRebuildCount(bool value) {
    showRebuildCount = value;
    showRebuildCountNotifier.value = value;
  }

  /// Updates [showStateBadge] and notifies listeners.
  static void setShowStateBadge(bool value) {
    showStateBadge = value;
    showStateBadgeNotifier.value = value;
  }

  /// Updates [enableHeatmap] and notifies listeners.
  static void setEnableHeatmap(bool value) {
    enableHeatmap = value;
    enableHeatmapNotifier.value = value;
  }

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
