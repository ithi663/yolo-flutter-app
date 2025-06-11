import 'package:flutter/services.dart';

class ModelDiscoveryDebugger {
  static const MethodChannel _channel = MethodChannel('yolo_single_image_channel');

  /// Test all model discovery mechanisms
  static Future<void> debugModelDiscovery() async {
    print('🔍 Starting model discovery debug...\n');

    // 1. Print iOS native model info
    try {
      print('📱 Calling iOS printModelInfo...');
      await _channel.invokeMethod('printModelInfo');
      print('✅ iOS printModelInfo completed\n');
    } catch (e) {
      print('❌ Error calling printModelInfo: $e\n');
    }

    // 2. Get available models list
    try {
      print('📋 Getting available models list...');
      final List<dynamic> models = await _channel.invokeMethod('getAvailableModels');
      print('✅ Available models: ${models.length}');
      for (int i = 0; i < models.length; i++) {
        print('  ${i + 1}. ${models[i]}');
      }
      print('');
    } catch (e) {
      print('❌ Error getting available models: $e\n');
    }

    // 3. Test specific model checks
    final testModels = ['yolo11n', 'yolo11n.mlpackage', 'yolov8n'];

    for (final model in testModels) {
      print('🧪 Testing model: $model');
      try {
        final result = await _channel.invokeMethod('checkModelExists', {
          'modelPath': model,
        });
        print('  Result: $result');
      } catch (e) {
        print('  Error: $e');
      }
      print('');
    }

    print('🏁 Model discovery debug completed!\n');
  }
}

// Example usage:
// await ModelDiscoveryDebugger.debugModelDiscovery();
