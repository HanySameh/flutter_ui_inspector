/// A debug-only Flutter package for inspecting UI state, rebuilds, and performance.
///
/// This package provides visual overlays and metrics to help identify performance
/// issues during development. All inspector code is automatically disabled in
/// release builds, ensuring zero production impact.
library;

export 'src/inspector.dart';
export 'src/rebuild_tracker.dart';
export 'src/inspector_config.dart';
export 'src/panel/inspector_panel.dart';
