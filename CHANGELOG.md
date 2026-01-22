# 1.1.0

- **Feat**: Added draggable inspector panel (drag from title bar).
- **Feat**: Added widget filtering and search in the inspector panel.
- **Feat**: Implemented settings persistence/saved state using `shared_preferences`.
- **Feat**: Added console logging for rebuild warnings (`logOnRebuildWarning`).
- **Feat**: Added rebuild frequency statistics (rebuilds/sec).
- **Feat**: Improved heatmap visuals with vignette effect.
- **Chore**: Updated example app with new features.

## 1.0.3

- Updated README with support email and improved support sections

## 1.0.2

- Updated README screenshot URLs to use GitHub raw URLs for better pub.dev display

## 1.0.1

- Fixed deprecated `withOpacity` calls, replaced with `withValues(alpha:)`
- Improved panel overlay attachment with retry logic
- Enhanced real-time updates for badges and heatmap
- Fixed theme-aware panel styling

## 1.0.0

- Initial release.
- Rebuild tracking badges per widget.
- UI state inspector badges (loading, error, empty, ready).
- Debug-only guard to avoid release impact.
- FPS and frame timing tracking.
- Floating inspector panel with gestures.
- Rebuild heatmap overlay.
