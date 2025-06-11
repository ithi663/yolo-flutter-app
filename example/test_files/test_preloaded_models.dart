import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PreloadedModelsTest extends StatefulWidget {
  const PreloadedModelsTest({super.key});

  @override
  State<PreloadedModelsTest> createState() => _PreloadedModelsTestState();
}

class _PreloadedModelsTestState extends State<PreloadedModelsTest> {
  final List<String> _logs = [];
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toLocal().toString().split('.')[0]}] $message');
    });
    print(message);
  }

  Future<void> _testPreloadedModels() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _addLog('🚀 Testing Preloaded YOLO Models');
    _addLog('=====================================');

    try {
      const platform = MethodChannel('ultralytics_yolo');

      // Test 1: Print model discovery info
      _addLog('📊 Test 1: Model Discovery Debug Info');
      try {
        await platform.invokeMethod('printModelInfo');
        _addLog('✅ Model discovery info printed to iOS console');
        _addLog('   Check Xcode console for detailed output');
      } catch (e) {
        _addLog('❌ Error getting model info: $e');
      }

      // Test 2: Check for preloaded models
      _addLog('\n📊 Test 2: Preloaded Model Detection');
      final testModels = ['yolo11n', 'yolo11n.mlpackage'];

      for (final model in testModels) {
        try {
          final result = await platform.invokeMethod('checkModelExists', {'modelPath': model});

          if (result is Map) {
            final exists = result['exists'] as bool? ?? false;
            final location = result['location'] as String? ?? 'unknown';

            if (exists && location.contains('plugin_bundle')) {
              _addLog('✅ $model: Found in $location (PRELOADED!)');
            } else if (exists) {
              _addLog('⚠️  $model: Found in $location (fallback)');
            } else {
              _addLog('❌ $model: Not found');
            }
          }
        } catch (e) {
          _addLog('❌ Error checking $model: $e');
        }
      }

      // Test 3: Try loading a model to test the full pipeline
      _addLog('\n📊 Test 3: Model Loading Test');
      try {
        // Create instance
        await platform.invokeMethod('createInstance', {'instanceId': 'preload_test'});

        // Try to load yolo11n
        final loadResult = await platform.invokeMethod(
            'loadModel', {'instanceId': 'preload_test', 'modelPath': 'yolo11n', 'task': 'detect'});

        if (loadResult == true) {
          _addLog('✅ yolo11n loaded successfully!');
          _addLog('   This should show "plugin bundled model" if preloaded');
        } else {
          _addLog('❌ Model loading failed');
        }

        // Clean up
        await platform.invokeMethod('removeInstance', {'instanceId': 'preload_test'});
      } catch (e) {
        _addLog('❌ Model loading test failed: $e');

        // Try cleanup
        try {
          await platform.invokeMethod('removeInstance', {'instanceId': 'preload_test'});
        } catch (_) {}
      }

      _addLog('\n🎯 Test Results Summary:');
      _addLog('=====================================');
      _addLog('If you see "Found in plugin_bundle" → Preloaded models working! 🎉');
      _addLog('If you see "Not found" → Follow PRELOAD_YOLO_SETUP.md guide');
      _addLog('If loading works → Your app will be faster! ⚡');
      _addLog('If loading fails → Legacy fallback will work 🛡️');

      _addLog('\n📋 Next Steps:');
      _addLog('1. Check iOS console for "Found preloaded model" messages');
      _addLog('2. If no preloaded models found, add Resources folder to Xcode');
      _addLog('3. Your app works either way thanks to fallback system!');
    } catch (e) {
      _addLog('❌ Test failed with error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preloaded Models Test'),
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
                  'Preloaded YOLO Models Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This test checks if yolo11n is preloaded in the app bundle.\n'
                  'Preloaded models = faster loading, no extraction delay!\n\n'
                  'If preloading isn\'t working, your legacy system will still work perfectly.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isRunning ? null : _testPreloadedModels,
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
                            Text('Testing...'),
                          ],
                        )
                      : const Text('Test Preloaded Models'),
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
                              : log.contains('⚠️')
                                  ? Colors.orange
                                  : log.contains('📊') || log.contains('🎯')
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
