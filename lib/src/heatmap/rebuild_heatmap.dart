import 'package:flutter/material.dart';
import '../debug_guard.dart';
import '../inspector_config.dart';
import '../registry/widget_registry.dart';

/// Overlay widget that visualizes rebuild intensity across the screen.
///
/// Renders a semi-transparent red overlay whose opacity increases with
/// rebuild frequency. This provides a quick visual indicator of which
/// areas of the UI are experiencing the most rebuild activity, helping
/// identify performance hotspots at a glance.
class RebuildHeatmap extends StatelessWidget {
  const RebuildHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DebugGuard.enabled) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: UiInspectorConfig.enableHeatmapNotifier,
      builder: (context, enableHeatmap, _) {
        if (!enableHeatmap) {
          return const SizedBox.shrink();
        }

        final widgets = UiInspectorRegistry.all();
        final maxRebuilds = widgets.isEmpty
            ? 0
            : widgets.map((w) => w.rebuilds).reduce((a, b) => a > b ? a : b);

        // Normalize intensity: 0..1 based on threshold and observed max.
        final threshold = UiInspectorConfig.rebuildWarningThreshold;
        final intensity = maxRebuilds == 0
            ? 0.0
            : (maxRebuilds / threshold).clamp(0.0, 1.0);

        // Render a subtle red overlay; higher rebuild counts => more opacity.
        return IgnorePointer(
          ignoring: true,
          child: Container(
            color: Colors.red.withValues(alpha: intensity * 0.35),
          ),
        );
      },
    );
  }
}
