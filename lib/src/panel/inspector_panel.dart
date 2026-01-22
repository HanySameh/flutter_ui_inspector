import 'dart:async';
import 'package:flutter/material.dart';
import '../debug_guard.dart';
import '../inspector_config.dart';
import '../registry/widget_registry.dart';
import '../performance/frame_tracker.dart';
import '../heatmap/rebuild_heatmap.dart';

enum InspectorGesture { longPress, tripleTap }

class UiInspectorPanelHost extends StatefulWidget {
  final Widget child;
  final InspectorGesture gesture;

  const UiInspectorPanelHost({
    super.key,
    required this.child,
    this.gesture = InspectorGesture.longPress,
  });

  @override
  State<UiInspectorPanelHost> createState() => _UiInspectorPanelHostState();
}

class _UiInspectorPanelHostState extends State<UiInspectorPanelHost> {
  OverlayEntry? _entry;
  final ValueNotifier<bool> _visible = ValueNotifier(false);
  int _tapCount = 0;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);
  Offset _position = const Offset(16, 100); // Default starting position

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachOverlay());
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _visible.dispose();
    super.dispose();
  }

  void _attachOverlay() {
    if (!DebugGuard.enabled || !UiInspectorConfig.enabled) return;
    if (_entry != null) return;
    if (!mounted) return;

    // Try to get overlay, retry if not available yet
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Retry on next frame if overlay not ready
      WidgetsBinding.instance.addPostFrameCallback((_) => _attachOverlay());
      return;
    }

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Heatmap overlay (always rendered, shows/hides based on config)
          const Positioned.fill(child: RebuildHeatmap()),
          // Gesture detector and panel
          ValueListenableBuilder<bool>(
            valueListenable: _visible,
            builder: (context, isVisible, _) => Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPress: widget.gesture == InspectorGesture.longPress
                        ? _toggle
                        : null,
                    onTap: widget.gesture == InspectorGesture.tripleTap
                        ? _handleTap
                        : null,
                  ),
                ),
                if (isVisible)
                  Positioned(
                    left: _position.dx,
                    top: _position.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _position += details.delta;
                        });
                      },
                      child: _PanelCard(
                        onClose: _toggle,
                        onRebuild: () => _entry?.markNeedsBuild(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    overlay.insert(_entry!);

    if (UiInspectorConfig.trackPerformance) {
      FrameTracker.start();
    }
  }

  void _toggle() => _visible.value = !_visible.value;

  void _handleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 600) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }
    _lastTap = now;
    if (_tapCount >= 3) {
      _tapCount = 0;
      _toggle();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// --- Panel Card with real-time updates ---
class _PanelCard extends StatefulWidget {
  const _PanelCard({required this.onClose, required this.onRebuild});

  final VoidCallback onClose;
  final VoidCallback onRebuild;

  @override
  State<_PanelCard> createState() => _PanelCardState();
}

class _PanelCardState extends State<_PanelCard> {
  Timer? _updateTimer;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Update every 500ms for real-time stats
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        widget.onRebuild();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use theme-aware colors
    final surfaceColor = isDark
        ? Colors.grey.shade900.withValues(alpha: 0.95)
        : Colors.grey.shade50.withValues(alpha: 0.95);
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondaryColor = isDark ? Colors.white70 : Colors.black54;

    final widgets = UiInspectorRegistry.all();
    final total = widgets.length;
    final mostRebuilt = UiInspectorRegistry.mostRebuilt();
    final maxRebuilds = mostRebuilt?.rebuilds ?? 0;
    final fps = FrameTracker.fps;
    final jank = FrameTracker.totalJankFrames;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 240, maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inspector',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: textSecondaryColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoLine('Widgets', '$total', textColor, textSecondaryColor),
              _infoLine(
                'Most rebuilt',
                mostRebuilt?.name ?? '—',
                textColor,
                textSecondaryColor,
              ),
              _infoLine(
                'Max rebuilds',
                '$maxRebuilds',
                textColor,
                textSecondaryColor,
              ),
              _infoLine(
                'Max Freq',
                '${mostRebuilt?.rebuildsPerSecond.toStringAsFixed(1) ?? 0.0}/s',
                textColor,
                textSecondaryColor,
              ),
              _infoLine(
                'Avg FPS',
                fps.toStringAsFixed(1),
                textColor,
                textSecondaryColor,
              ),
              _infoLine('Jank frames', '$jank', textColor, textSecondaryColor),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                style: TextStyle(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Filter widgets...',
                  hintStyle: TextStyle(
                    color: textSecondaryColor.withValues(alpha: 0.5),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: textSecondaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: textSecondaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _toggleButton(
                    label: 'Rebuild badges',
                    value: UiInspectorConfig.showRebuildCount,
                    onChanged: (v) {
                      UiInspectorConfig.setShowRebuildCount(v);
                      widget.onRebuild();
                    },
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  _toggleButton(
                    label: 'State badges',
                    value: UiInspectorConfig.showStateBadge,
                    onChanged: (v) {
                      UiInspectorConfig.setShowStateBadge(v);
                      widget.onRebuild();
                    },
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  _toggleButton(
                    label: 'Heatmap',
                    value: UiInspectorConfig.enableHeatmap,
                    onChanged: (v) {
                      UiInspectorConfig.setEnableHeatmap(v);
                      widget.onRebuild();
                    },
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  _actionButton(
                    'Reset',
                    () {
                      UiInspectorRegistry.reset();
                      widget.onRebuild();
                    },
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(
                      'Search Results',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widgets
                        .where(
                          (w) => w.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .take(5)
                        .map(
                          (w) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    w.name,
                                    style: TextStyle(
                                      color: textSecondaryColor,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${w.rebuilds} (${w.frequency.toStringAsFixed(1)}/s)',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (widgets
                        .where(
                          (w) => w.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'No matches',
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(
    String label,
    String value,
    Color textColor,
    Color textSecondaryColor,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textSecondaryColor, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _toggleButton({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
    required bool isDark,
  }) => FilterChip(
    label: Text(
      label,
      style: TextStyle(
        color: value
            ? (isDark ? Colors.white : Colors.white)
            : (isDark ? Colors.white70 : Colors.black87),
        fontSize: 11,
      ),
    ),
    selected: value,
    onSelected: onChanged,
    selectedColor: colorScheme.primary,
    backgroundColor: isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05),
    checkmarkColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  Widget _actionButton(
    String label,
    VoidCallback onTap, {
    required ColorScheme colorScheme,
    required bool isDark,
  }) => ActionChip(
    label: Text(
      label,
      style: TextStyle(
        color: isDark ? Colors.white70 : Colors.black87,
        fontSize: 11,
      ),
    ),
    onPressed: onTap,
    backgroundColor: isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}
