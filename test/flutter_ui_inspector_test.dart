import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_inspector/flutter_ui_inspector.dart';
import 'package:flutter_ui_inspector/src/registry/widget_registry.dart';
import 'package:flutter_ui_inspector/src/heatmap/rebuild_heatmap.dart';
import 'package:flutter_ui_inspector/src/ui_state_badge.dart';

void main() {
  setUp(() {
    // Reset config to defaults
    UiInspectorConfig.enabled = true;
    UiInspectorConfig.showRebuildCount = true;
    UiInspectorConfig.showStateBadge = true;
    UiInspectorConfig.trackPerformance = false;
    UiInspectorConfig.enableHeatmap = false;
    UiInspectorConfig.rebuildWarningThreshold = 10;
    UiInspectorConfig.jankFrameThresholdMs = 16.0;
    UiInspectorRegistry.reset();
  });

  test('config defaults are present', () {
    expect(UiInspectorConfig.enabled, isTrue);
    expect(UiInspectorConfig.showRebuildCount, isTrue);
    expect(UiInspectorConfig.showStateBadge, isTrue);
    expect(UiInspectorConfig.trackPerformance, isFalse);
    expect(UiInspectorConfig.enableHeatmap, isFalse);
    expect(UiInspectorConfig.rebuildWarningThreshold, 10);
    expect(UiInspectorConfig.jankFrameThresholdMs, 16.0);
  });

  testWidgets('UiStateBadge shows label when enabled', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: UiStateBadge(
          name: 'UserList',
          state: UiState.loading,
          child: Text('child'),
        ),
      ),
    );
    expect(find.text('UserList • LOADING'), findsOneWidget);
  });

  testWidgets('UiStateBadge hides when disabled', (tester) async {
    UiInspectorConfig.showStateBadge = false;
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: UiStateBadge(
          name: 'UserList',
          state: UiState.ready,
          child: Text('child'),
        ),
      ),
    );
    expect(find.textContaining('UserList'), findsNothing);
    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('RebuildTracker increments and shows badge', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RebuildTracker(name: 'Item', child: Text('hello')),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
    // initial build increments once
    expect(find.textContaining('🔁 '), findsOneWidget);

    // Trigger another rebuild
    await tester.pump();
    await tester.pump();

    // Badge still present; registry reflects rebuilds.
    expect(find.textContaining('🔁 '), findsOneWidget);
    final stats = UiInspectorRegistry.mostRebuilt();
    expect(stats?.rebuilds ?? 0, greaterThanOrEqualTo(1));
  });

  testWidgets('RebuildTracker unregisters on dispose', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RebuildTracker(name: 'Temp', child: Text('temp')),
      ),
    );
    expect(UiInspectorRegistry.all().length, 1);

    await tester.pumpWidget(const SizedBox());
    expect(UiInspectorRegistry.all().length, 0);
  });

  testWidgets('UiInspector applies state priority and wraps child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: UiInspector(
          name: 'User',
          loading: true,
          error: true,
          empty: true,
          child: Text('body'),
        ),
      ),
    );
    // error has highest priority
    expect(find.text('User • ERROR'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('UiInspector respects disabled config', (tester) async {
    UiInspectorConfig.enabled = false;
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: UiInspector(name: 'User', loading: true, child: Text('body')),
      ),
    );
    expect(find.text('User • LOADING'), findsNothing);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('RebuildHeatmap renders overlay when enabled', (tester) async {
    UiInspectorConfig.enableHeatmap = true;
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RebuildHeatmap(),
      ),
    );
    expect(find.byType(IgnorePointer), findsOneWidget);
  });

  testWidgets('Inspector panel enable does not throw', (tester) async {
    UiInspectorPanel.enable(gesture: InspectorGesture.longPress);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('home'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
