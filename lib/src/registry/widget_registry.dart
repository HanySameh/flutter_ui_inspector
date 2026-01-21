import '../ui_state_badge.dart';

/// Statistics tracked for a single widget instance.
///
/// Stores rebuild count, current UI state, and last update timestamp
/// to enable performance analysis and debugging insights.
class WidgetStats {
  WidgetStats({
    required this.name,
    this.rebuilds = 0,
    this.state = UiState.ready,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Widget name/identifier.
  final String name;

  /// Number of times this widget has rebuilt.
  int rebuilds;

  /// Current UI state of the widget.
  UiState state;

  /// Timestamp of the last update to these stats.
  DateTime lastUpdated;
}

/// Global registry storing widget statistics for inspector features.
///
/// Uses a simple in-memory map for O(1) updates and lookups. This design
/// avoids streams or ChangeNotifiers to minimize overhead, as the registry
/// is primarily queried by the inspector panel rather than driving UI updates.
class UiInspectorRegistry {
  UiInspectorRegistry._();

  static final Map<String, WidgetStats> _widgets = <String, WidgetStats>{};

  /// Registers or replaces statistics for a widget instance.
  ///
  /// Called automatically by [RebuildTracker] when widgets are created.
  /// The [id] should be unique per widget instance to avoid collisions.
  static void register(String id, WidgetStats stats) {
    _widgets[id] = stats..lastUpdated = DateTime.now();
  }

  /// Increments the rebuild counter for a tracked widget.
  ///
  /// Called automatically by [RebuildTracker] on each rebuild to maintain
  /// accurate rebuild counts for performance analysis.
  static void updateRebuild(String id) {
    final stats = _widgets[id];
    if (stats != null) {
      stats.rebuilds += 1;
      stats.lastUpdated = DateTime.now();
    }
  }

  /// Updates the UI state for a tracked widget.
  ///
  /// Called automatically by [UiInspector] when widget state changes,
  /// enabling the inspector panel to display current state information.
  static void updateState(String id, UiState state) {
    final stats = _widgets[id];
    if (stats != null) {
      stats.state = state;
      stats.lastUpdated = DateTime.now();
    }
  }

  /// Returns all currently tracked widget statistics.
  ///
  /// Returns an unmodifiable list to prevent external mutation of registry data.
  static List<WidgetStats> all() => List.unmodifiable(_widgets.values);

  /// Returns the widget with the highest rebuild count.
  ///
  /// Useful for identifying performance hotspots. Returns null if no widgets
  /// are currently tracked.
  static WidgetStats? mostRebuilt() {
    if (_widgets.isEmpty) return null;
    WidgetStats? top;
    for (final stats in _widgets.values) {
      if (top == null || stats.rebuilds > top.rebuilds) {
        top = stats;
      }
    }
    return top;
  }

  /// Clears all tracked widget statistics.
  ///
  /// Useful for resetting inspector state during development or testing.
  static void reset() {
    _widgets.clear();
  }

  /// Removes a widget from tracking.
  ///
  /// Called automatically by [RebuildTracker] when widgets are disposed
  /// to prevent memory leaks from accumulating stale entries.
  static void remove(String id) {
    _widgets.remove(id);
  }
}
