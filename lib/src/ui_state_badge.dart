import 'package:flutter/material.dart';
import 'debug_guard.dart';
import 'inspector_config.dart';

/// Logical UI state for a widget.
///
/// Used to categorize widget states for visual debugging, helping developers
/// quickly identify which widgets are in problematic states during development.
enum UiState {
  /// Widget is actively loading data.
  loading,

  /// Widget has encountered an error.
  error,

  /// Widget has no data to display.
  empty,

  /// Widget is ready and displaying content normally.
  ready,
}

/// Overlays a small badge showing the current UI state of a widget.
///
/// The badge appears at the bottom-left corner and uses color coding to
/// quickly communicate state: amber for loading, red for errors, blue for
/// empty, and green for ready. This helps identify state-related issues
/// without inspecting code or logs.
class UiStateBadge extends StatelessWidget {
  const UiStateBadge({
    super.key,
    required this.name,
    required this.state,
    required this.child,
  });

  /// Unique identifier for this widget, shown in the badge.
  final String name;

  /// Current UI state to display.
  final UiState state;

  /// The widget to wrap with the state badge overlay.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!DebugGuard.enabled) {
      return child;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: UiInspectorConfig.showStateBadgeNotifier,
      builder: (context, showBadge, _) {
        if (!showBadge) {
          return child;
        }

        final color = _stateColor(state);
        final label = '$name • ${state.name.toUpperCase()}';

        return Stack(
          children: [
            child,
            Positioned(
              left: 4,
              bottom: 4,
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _stateColor(UiState state) {
    switch (state) {
      case UiState.loading:
        return Colors.amber;
      case UiState.error:
        return Colors.red;
      case UiState.empty:
        return Colors.blue;
      case UiState.ready:
        return Colors.green;
    }
  }
}
