import 'package:flutter/material.dart';
import 'debug_guard.dart';
import 'inspector_config.dart';
import 'registry/widget_registry.dart';
import 'ui_state_badge.dart';

/// Tracks how many times a widget rebuilds and displays a badge with the count.
///
/// Excessive rebuilds are a common performance issue in Flutter apps. This widget
/// helps identify widgets that rebuild more often than expected by showing a
/// badge that turns red when rebuilds exceed [UiInspectorConfig.rebuildWarningThreshold].
/// The badge appears at the top-right corner and ignores pointer events to avoid
/// interfering with widget interactions.
class RebuildTracker extends StatefulWidget {
  const RebuildTracker({super.key, required this.name, required this.child});

  /// Unique identifier for this widget, shown in the rebuild badge.
  final String name;

  /// The widget whose rebuilds should be tracked.
  final Widget child;

  @override
  State<RebuildTracker> createState() => _RebuildTrackerState();
}

class _RebuildTrackerState extends State<RebuildTracker> {
  late final String _id;
  int _rebuilds = 0;

  @override
  void initState() {
    super.initState();
    _id = '${widget.name}_${DateTime.now().microsecondsSinceEpoch}_$hashCode';
    if (_trackingEnabled) {
      UiInspectorRegistry.register(
        _id,
        WidgetStats(name: widget.name, rebuilds: 0, state: UiState.ready),
      );
    }
  }

  bool get _trackingEnabled =>
      DebugGuard.enabled && UiInspectorConfig.showRebuildCount;

  void _increment() {
    _rebuilds += 1;
    UiInspectorRegistry.updateRebuild(_id);
  }

  @override
  void dispose() {
    UiInspectorRegistry.remove(_id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_trackingEnabled) {
      return widget.child;
    }

    _increment();

    final color = _rebuilds >= UiInspectorConfig.rebuildWarningThreshold
        ? Colors.red
        : Colors.blueAccent;

    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 4,
          top: 4,
          child: IgnorePointer(
            ignoring: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '🔁 $_rebuilds',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
