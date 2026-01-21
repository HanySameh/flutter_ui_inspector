import 'package:flutter/widgets.dart';
import 'debug_guard.dart';
import 'inspector_config.dart';
import 'rebuild_tracker.dart';
import 'registry/widget_registry.dart';
import 'ui_state_badge.dart';

/// Main inspector widget that tracks both UI state and rebuild frequency.
///
/// This widget combines [RebuildTracker] and [UiStateBadge] to provide
/// comprehensive inspection capabilities. It determines UI state using
/// priority: error > loading > empty > ready, ensuring the most critical
/// state is always displayed. State changes are automatically registered
/// in the global registry for panel display.
class UiInspector extends StatelessWidget {
  const UiInspector({
    super.key,
    required this.name,
    required this.child,
    this.loading = false,
    this.error = false,
    this.empty = false,
  });

  /// Unique identifier for this widget, used in badges and registry.
  final String name;

  /// The widget to inspect.
  final Widget child;

  /// Whether this widget is currently in a loading state.
  final bool loading;

  /// Whether this widget has encountered an error.
  final bool error;

  /// Whether this widget has no data to display.
  final bool empty;

  @override
  Widget build(BuildContext context) {
    if (!DebugGuard.enabled || !UiInspectorConfig.enabled) {
      return child;
    }

    final UiState state;
    if (error) {
      state = UiState.error;
    } else if (loading) {
      state = UiState.loading;
    } else if (empty) {
      state = UiState.empty;
    } else {
      state = UiState.ready;
    }

    // Update registry with latest state.
    UiInspectorRegistry.updateState(name, state);

    // Wrap with rebuild tracker, then state badge.
    final tracked = RebuildTracker(name: name, child: child);
    return UiStateBadge(name: name, state: state, child: tracked);
  }
}
