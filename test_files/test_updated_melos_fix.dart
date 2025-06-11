import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdatedMelosFixTest extends StatefulWidget {
  const UpdatedMelosFixTest({super.key});

  @override
  State<UpdatedMelosFixTest> createState() => _UpdatedMelosFixTestState();
}

class _UpdatedMelosFixTestState extends State<UpdatedMelosFixTest> {
  final List<String> _logs = [];
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toLocal().toString().split('.')[0]}] $message');
    });
    print(message);
  }

  Future<void> _runUpdatedTests() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _addLog('🚀 Starting Updated Melos Compatibility Tests');
    _addLog('=====================================');

    try {
      // Test 1: Check model discovery improvements
      _addLog('📊 Test 1: Enhanced Model Discovery');
      await _testModelDiscovery();

      // Test 2: Test updated checkModelExists
      _addLog('\n📊 Test 2: Updated checkModelExists Method');
      await _testCheckModelExists();

      // Test 3: Test updated resolveModelPath
      _addLog('\n📊 Test 3: Updated resolveModelPath Method');
      await _testResolveModelPath();

      // Test 4: Test actual model loading with new discovery
      _addLog('\n📊 Test 4: Plugin Bundled Model Loading');
      await _testPluginBundledModelLoading();

      _addLog('\n✅ All updated tests completed!');
      _addLog('=====================================');
    } catch (e) {
      _addLog('❌ Test failed with error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _testModelDiscovery() async {
    try {
      const platform = MethodChannel('ultralytics_yolo');

      // Call the debug method to see what models are available
      final result = await platform.invokeMethod('printModelInfo');
      _addLog('✅ Model discovery info printed to iOS console');
      _addLog('Check Xcode console for detailed model discovery output');
    } catch (e) {
      _addLog('❌ Model discovery test failed: $e');
    }
  }

  Future<void> _testCheckModelExists() async {
    const platform = MethodChannel('ultralytics_yolo');

    final testModels = [
      'yolo11n',
      'yolo11n.mlpackage',
      'yolov8n',
      'yolov8n.mlpackage',
      'nonexistent_model'
    ];

    for (final modelName in testModels) {
      try {
        _addLog('🔍 Testing checkModelExists for: $modelName');

        final result = await platform.invokeMethod('checkModelExists', {'modelPath': modelName});

        if (result is Map) {
          final exists = result['exists'] as bool? ?? false;
          final location = result['location'] as String? ?? 'unknown';
          final path = result['path'] as String? ?? 'unknown';

          if (exists) {
            _addLog('  ✅ Found: location=$location');
            if (result.containsKey('absolutePath')) {
              _addLog('     Path: ${result['absolutePath']}');
            }
          } else {
            _addLog('  ❌ Not found: location=$location');
          }
        }
      } catch (e) {
        _addLog('  ❌ Error checking $modelName: $e');
      }
    }
  }

  Future<void> _testResolveModelPath() async {
    _addLog('Testing model path resolution with iOS console output...');
    _addLog('(Check Xcode console for "Found plugin bundle model" messages)');

    // This will be tested during actual model loading
    // The resolveModelPath method will be called internally
    _addLog('✅ Model path resolution will be tested during loading');
  }

  Future<void> _testPluginBundledModelLoading() async {
    const platform = MethodChannel('ultralytics_yolo');

    // Test models that should be in the plugin bundle
    final testModels = ['yolo11n', 'yolo11n-seg', 'yolov8n'];

    for (final modelName in testModels) {
      try {
        _addLog('🔄 Testing plugin bundled loading: $modelName');

        // Create instance
        await platform.invokeMethod('createInstance', {'instanceId': 'test_$modelName'});

        // Try to load model (this will test both checkModelExists and resolveModelPath)
        final loadResult = await platform.invokeMethod('loadModel',
            {'instanceId': 'test_$modelName', 'modelPath': modelName, 'task': 'detect'});

        if (loadResult == true) {
          _addLog('  ✅ Plugin bundled loading successful for $modelName');

          // Clean up
          await platform.invokeMethod('removeInstance', {'instanceId': 'test_$modelName'});
        } else {
          _addLog('  ❌ Plugin bundled loading failed for $modelName');
        }
      } catch (e) {
        _addLog('  ❌ Error loading $modelName: $e');

        // Try to clean up even if loading failed
        try {
          await platform.invokeMethod('removeInstance', {'instanceId': 'test_$modelName'});
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updated Melos Fix Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Updated Melos Compatibility Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This test verifies the updated fixes for:\n'
                  '• Enhanced plugin bundle model discovery\n'
                  '• Updated checkModelExists method\n'
                  '• Updated resolveModelPath method\n'
                  '• Consistent search logic across all components',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isRunning ? null : _runUpdatedTests,
                  child: _isRunning
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Running Tests...'),
                          ],
                        )
                      : const Text('Run Updated Tests'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: log.contains('❌')
                          ? Colors.red
                          : log.contains('✅')
                              ? Colors.green
                              : log.contains('🔍') || log.contains('🔄')
                                  ? Colors.blue
                                  : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
