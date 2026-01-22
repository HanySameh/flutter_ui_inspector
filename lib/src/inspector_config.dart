import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global configuration for inspector behavior.
///
/// Uses static fields to avoid passing config through widget trees,
/// making it easy to toggle features at runtime during development.
class UiInspectorConfig {
  static final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

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
  static final ValueNotifier<bool> showStateBadgeNotifier = ValueNotifier<bool>(
    showStateBadge,
  );

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
  static final ValueNotifier<bool> enableHeatmapNotifier = ValueNotifier<bool>(
    enableHeatmap,
  );

  // Setters moved to persistence region below

  static int rebuildWarningThreshold = 10;

  /// Whether to log a warning to the console when specific widgets exceed the threshold.
  static bool logOnRebuildWarning = false;

  /// Frame duration threshold (ms) for classifying frames as janky.
  ///
  /// Frames exceeding build+raster time of this value are counted as jank,
  /// helping identify performance degradation during development.
  static double jankFrameThresholdMs = 16.0;

  // --- Persistence ---

  static SharedPreferences? _prefs;
  static const _keyRebuildCount = 'flutter_ui_inspector_rebuild_count';
  static const _keyStateBadge = 'flutter_ui_inspector_state_badge';
  static const _keyHeatmap = 'flutter_ui_inspector_heatmap';

  /// Initialize configuration and load saved settings.
  static Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();

    // Load saved values
    if (_prefs!.containsKey(_keyRebuildCount)) {
      showRebuildCount = _prefs!.getBool(_keyRebuildCount) ?? true;
      showRebuildCountNotifier.value = showRebuildCount;
    }
    if (_prefs!.containsKey(_keyStateBadge)) {
      showStateBadge = _prefs!.getBool(_keyStateBadge) ?? true;
      showStateBadgeNotifier.value = showStateBadge;
    }
    if (_prefs!.containsKey(_keyHeatmap)) {
      enableHeatmap = _prefs!.getBool(_keyHeatmap) ?? false;
      enableHeatmapNotifier.value = enableHeatmap;
    }
  }

  /// Updates [showRebuildCount], saves to prefs, and notifies listeners.
  static void setShowRebuildCount(bool value) {
    showRebuildCount = value;
    showRebuildCountNotifier.value = value;
    _prefs?.setBool(_keyRebuildCount, value);
  }

  /// Updates [showStateBadge], saves to prefs, and notifies listeners.
  static void setShowStateBadge(bool value) {
    showStateBadge = value;
    showStateBadgeNotifier.value = value;
    _prefs?.setBool(_keyStateBadge, value);
  }

  /// Updates [enableHeatmap], saves to prefs, and notifies listeners.
  static void setEnableHeatmap(bool value) {
    enableHeatmap = value;
    enableHeatmapNotifier.value = value;
    _prefs?.setBool(_keyHeatmap, value);
  }
}
