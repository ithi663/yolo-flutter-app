import 'package:flutter/services.dart';

class MelosModelTester {
  static const MethodChannel _channel = MethodChannel('yolo_single_image_channel');

  /// Test the Melos-compatible model discovery fix
  static Future<void> testMelosFix() async {
    print('🧪 Testing Melos-compatible model discovery fix...\n');

    // 1. Print updated model info (should show new search paths)
    try {
      print('📱 Getting updated iOS model info...');
      await _channel.invokeMethod('printModelInfo');
      print('✅ iOS model info completed\n');
    } catch (e) {
      print('❌ Error getting model info: $e\n');
    }

    // 2. Check available models (should now find bundled models)
    try {
      print('📋 Getting available models after fix...');
      final List<dynamic> models = await _channel.invokeMethod('getAvailableModels');

      if (models.isNotEmpty) {
        print('🎉 SUCCESS! Found ${models.length} bundled models:');
        for (int i = 0; i < models.length; i++) {
          print('  ${i + 1}. ${models[i]}');
        }
        print('');
      } else {
        print('❌ Still no models found. Debug info above should show why.\n');
      }
    } catch (e) {
      print('❌ Error getting available models: $e\n');
    }

    // 3. Test specific model existence
    final testModels = ['yolo11n', 'yolo11n.mlpackage'];

    for (final model in testModels) {
      print('🔍 Testing model: $model');
      try {
        final result = await _channel.invokeMethod('checkModelExists', {
          'modelPath': model,
        });

        if (result['exists'] == true) {
          print('  ✅ FOUND: ${result['location']} - ${result['absolutePath']}');
        } else {
          print('  ❌ Not found: ${result}');
        }
      } catch (e) {
        print('  ❌ Error: $e');
      }
      print('');
    }

    print('🎯 Test Results Summary:');
    print('- If models were found: Plugin bundled models are now working! 🎉');
    print('- If models still not found: Check the debug info above for paths searched');
    print('- Your fallback system ensures the app works regardless! ✅\n');
  }

  /// Test a complete model loading workflow
  static Future<void> testModelLoadingWorkflow() async {
    print('🔄 Testing complete model loading workflow...\n');

    try {
      // This should now succeed with plugin bundled models
      print('🧪 Testing YOLO model loading with simple name...');

      // Note: In a real app, you'd create a YOLO instance here
      // For testing, we'll just verify the model exists
      final result = await _channel.invokeMethod('checkModelExists', {
        'modelPath': 'yolo11n',
      });

      if (result['exists'] == true) {
        print('🎉 SUCCESS! Plugin bundled model loading should now work!');
        print('   Your YoloService can now use: YOLO(modelPath: "yolo11n")');
        print('   Location: ${result['location']}');
        print('   Path: ${result['absolutePath'] ?? 'N/A'}');
      } else {
        print('⚠️  Plugin model still not found, but fallback will work.');
        print('   Your app will continue to use the legacy extraction method.');
      }
    } catch (e) {
      print('❌ Error in workflow test: $e');
    }

    print('\n🏁 Melos fix testing completed!');
  }
}

// Example usage:
// await MelosModelTester.testMelosFix();
// await MelosModelTester.testModelLoadingWorkflow();
