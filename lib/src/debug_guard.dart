import 'package:flutter/foundation.dart';

/// Central guard to ensure inspector code never executes in release builds.
///
/// This prevents any inspector overhead from affecting production performance
/// and ensures the package has zero impact when compiled in release mode.
class DebugGuard {
  const DebugGuard._();

  /// Returns true only when running in debug mode.
  ///
  /// Used throughout the package to gate all inspector functionality,
  /// allowing tree-shaking to eliminate inspector code in release builds.
  static bool get enabled => kDebugMode;
}
