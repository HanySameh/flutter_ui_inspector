import 'package:flutter/material.dart';
import '../debug_guard.dart';
import '../inspector_config.dart';
import '../registry/widget_registry.dart';
import '../performance/frame_tracker.dart';

/// Gesture types that can activate the inspector panel.
///
/// Provides options to avoid conflicts with app-specific gestures.
enum InspectorGesture {
  /// Long press anywhere on screen to toggle panel.
  longPress,

  /// Triple tap anywhere on screen to toggle panel.
  tripleTap,
}

/// Floating inspector panel providing global statistics and controls.
///
/// Displays widget counts, rebuild statistics, FPS metrics, and provides
/// toggles for inspector features. Managed via [OverlayEntry] to appear
/// above all app content. Only active in debug mode to ensure zero
/// production impact.
class UiInspectorPanel {
  UiInspectorPanel._();

  static OverlayEntry? _entry;
  static final ValueNotifier<bool> _visible = ValueNotifier<bool>(false);
  static InspectorGesture _gesture = InspectorGesture.longPress;
  static int _tapCount = 0;
  static DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  /// Enables the inspector panel with the specified activation gesture.
  ///
  /// Should be called once during app initialization, typically in [main].
  /// The panel overlay is attached after the first frame to ensure the
  /// widget tree is fully built. Does nothing if not in debug mode.
  static void enable({InspectorGesture gesture = InspectorGesture.longPress}) {
    _gesture = gesture;
    if (!DebugGuard.enabled) return;
    _attach();
  }

  static void _attach() {
    if (_entry != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_entry != null) return;
      if (!UiInspectorConfig.enabled) return;
      final overlay = WidgetsBinding.instance.rootElement == null
          ? null
          : Overlay.maybeOf(
              WidgetsBinding.instance.rootElement!,
              rootOverlay: true,
            );
      if (overlay == null) return;

      _entry = OverlayEntry(
        builder: (context) {
          return ValueListenableBuilder<bool>(
            valueListenable: _visible,
            builder: (context, isVisible, _) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onLongPress: _gesture == InspectorGesture.longPress
                          ? _toggleVisible
                          : null,
                      onTap: _gesture == InspectorGesture.tripleTap
                          ? _handleTap
                          : null,
                    ),
                  ),
                  if (isVisible)
                    Positioned(
                      right: 16,
                      bottom: 32,
                      child: _PanelCard(onClose: _toggleVisible),
                    ),
                ],
              );
            },
          );
        },
      );

      overlay.insert(_entry!);
      // Start frame tracking if enabled in config.
      if (UiInspectorConfig.trackPerformance) {
        FrameTracker.start();
      }
    });
  }

  static void _toggleVisible() {
    _visible.value = !_visible.value;
  }

  static void _handleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 600) {
      _tapCount += 1;
    } else {
      _tapCount = 1;
    }
    _lastTap = now;
    if (_tapCount >= 3) {
      _tapCount = 0;
      _toggleVisible();
    }
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final widgets = UiInspectorRegistry.all();
    final total = widgets.length;
    final mostRebuilt = UiInspectorRegistry.mostRebuilt();
    final maxRebuilds = mostRebuilt?.rebuilds ?? 0;
    final fps = FrameTracker.fps;
    final jank = FrameTracker.totalJankFrames;

    return Material(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(8),
      elevation: 6,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 260),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inspector',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _infoLine('Widgets', '$total'),
              _infoLine('Most rebuilt', mostRebuilt?.name ?? '—'),
              _infoLine('Max rebuilds', '$maxRebuilds'),
              _infoLine('Avg FPS', fps.toStringAsFixed(1)),
              _infoLine('Jank frames', '$jank'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _toggleButton(
                    label: 'Rebuild badges',
                    value: UiInspectorConfig.showRebuildCount,
                    onChanged: (v) => UiInspectorConfig.showRebuildCount = v,
                  ),
                  _toggleButton(
                    label: 'State badges',
                    value: UiInspectorConfig.showStateBadge,
                    onChanged: (v) => UiInspectorConfig.showStateBadge = v,
                  ),
                  _toggleButton(
                    label: 'Heatmap',
                    value: UiInspectorConfig.enableHeatmap,
                    onChanged: (v) => UiInspectorConfig.enableHeatmap = v,
                  ),
                  _actionButton('Reset', () {
                    UiInspectorRegistry.reset();
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      selected: value,
      onSelected: onChanged,
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.white10,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      onPressed: onTap,
      backgroundColor: Colors.white12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}
