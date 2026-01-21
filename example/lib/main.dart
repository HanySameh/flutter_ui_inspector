import 'package:flutter/material.dart';
import 'package:flutter_ui_inspector/flutter_ui_inspector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable inspector panel with long press gesture
  // UiInspectorPanel.enable(gesture: InspectorGesture.longPress);

  // Configure inspector features
  UiInspectorConfig.enabled = true;
  UiInspectorConfig.showRebuildCount = true;
  UiInspectorConfig.showStateBadge = true;
  UiInspectorConfig.trackPerformance = true;
  UiInspectorConfig.enableHeatmap = true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Inspector Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: UiInspectorPanelHost(
        gesture: InspectorGesture.longPress,
        child: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isEmpty = false;
  List<String> _items = [];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _simulateLoading() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isEmpty = false;
    });

    // Artificial delay to demonstrate performance tracking
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isLoading = false;
      _items = List.generate(10, (i) => 'Item ${i + 1}');
    });
  }

  Future<void> _simulateError() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  void _simulateEmpty() {
    setState(() {
      _isEmpty = true;
      _hasError = false;
      _items = [];
    });
  }

  void _reset() {
    setState(() {
      _counter = 0;
      _isLoading = false;
      _hasError = false;
      _isEmpty = false;
      _items = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('UI Inspector Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Counter section - demonstrates excessive rebuilds
            UiInspector(
              name: 'CounterSection',
              loading: _isLoading,
              error: _hasError,
              empty: _isEmpty,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Counter: $_counter',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _incrementCounter,
                        child: const Text('Increment (causes rebuilds)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _simulateLoading,
                  child: const Text('Load Data'),
                ),
                ElevatedButton(
                  onPressed: _simulateError,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simulate Error'),
                ),
                ElevatedButton(
                  onPressed: _simulateEmpty,
                  child: const Text('Show Empty'),
                ),
                ElevatedButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
            const SizedBox(height: 16),

            // List section - demonstrates rebuild tracking
            UiInspector(
              name: 'ItemList',
              loading: _isLoading,
              error: _hasError,
              empty: _isEmpty || _items.isEmpty,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items List',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_hasError)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Error loading items',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      else if (_items.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No items available'),
                          ),
                        )
                      else
                        ..._items.map((item) {
                          // Each item wrapped in RebuildTracker to show individual rebuilds
                          return RebuildTracker(
                            name: item,
                            child: ListTile(
                              title: Text(item),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _items.remove(item);
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inspector Features',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Long press anywhere to open inspector panel\n'
                      '• Rebuild badges show in top-right (red if >10 rebuilds)\n'
                      '• State badges show in bottom-left (loading/error/empty/ready)\n'
                      '• Heatmap overlay shows rebuild intensity\n'
                      '• Panel shows FPS, jank frames, and widget stats',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
