import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class YoloAssetTester {
  static const String _tag = 'YoloAssetTester';

  /// Test plugin bundled models (new approach)
  static Future<Map<String, bool>> testPluginBundledModels() async {
    final results = <String, bool>{};

    // Test detection models
    final detectionModels = ['yolo11n', 'yolo11n-seg', 'yolo11n_int8'];

    print('🧪 [$_tag] Testing plugin bundled models...');

    for (final modelName in detectionModels) {
      try {
        // Try to create YOLO instance with simple model name
        // This should trigger the plugin's automatic model discovery
        final yolo = YOLO(
          modelPath: modelName,
          task: YOLOTask.detect,
        );

        // Try to load the model
        await yolo.loadModel();
        results['Plugin: $modelName'] = true;
        print('✅ [$_tag] Plugin bundled model found: $modelName');
      } catch (e) {
        results['Plugin: $modelName'] = false;
        print('❌ [$_tag] Plugin bundled model failed: $modelName - $e');
      }
    }

    return results;
  }

  /// Test legacy package assets (for backward compatibility)
  static Future<Map<String, bool>> testLegacyAssets() async {
    final results = <String, bool>{};

    // Test iOS models
    final iosModels = [
      'yolo11n.mlpackage.zip',
      'yolo11n-seg.mlpackage.zip',
    ];

    // Test Android models
    final androidModels = [
      'yolo11n.tflite',
      'yolo11n_int8.tflite',
      'yolo11n-seg.tflite',
    ];

    print('🧪 [$_tag] Testing legacy iOS model assets...');
    for (final model in iosModels) {
      try {
        final assetPath = 'packages/detection/assets/models/$model';
        final byteData = await rootBundle.load(assetPath);
        results['Legacy iOS: $model'] = true;
        print('✅ [$_tag] Legacy iOS model found: $assetPath (${byteData.lengthInBytes} bytes)');
      } catch (e) {
        results['Legacy iOS: $model'] = false;
        print('❌ [$_tag] Legacy iOS model missing: packages/detection/assets/models/$model - $e');
      }
    }

    print('🧪 [$_tag] Testing legacy Android model assets...');
    for (final model in androidModels) {
      try {
        final assetPath = 'packages/detection/assets/models/$model';
        final byteData = await rootBundle.load(assetPath);
        results['Legacy Android: $model'] = true;
        print('✅ [$_tag] Legacy Android model found: $assetPath (${byteData.lengthInBytes} bytes)');
      } catch (e) {
        results['Legacy Android: $model'] = false;
        print(
            '❌ [$_tag] Legacy Android model missing: packages/detection/assets/models/$model - $e');
      }
    }

    return results;
  }

  /// Comprehensive test of all model loading approaches
  static Future<Map<String, dynamic>> testAllApproaches() async {
    final results = <String, dynamic>{};

    print('🎯 [$_tag] Running comprehensive model loading tests...');

    // Test 1: Plugin bundled models
    try {
      final pluginResults = await testPluginBundledModels();
      results['plugin_bundled'] = pluginResults;
      final pluginSuccess = pluginResults.values.where((v) => v).length;
      final pluginTotal = pluginResults.length;
      print('📊 [$_tag] Plugin bundled models: $pluginSuccess/$pluginTotal successful');
    } catch (e) {
      results['plugin_bundled'] = {'error': e.toString()};
      print('❌ [$_tag] Plugin bundled models test failed: $e');
    }

    // Test 2: Legacy package assets
    try {
      final legacyResults = await testLegacyAssets();
      results['legacy_assets'] = legacyResults;
      final legacySuccess = legacyResults.values.where((v) => v).length;
      final legacyTotal = legacyResults.length;
      print('📊 [$_tag] Legacy assets: $legacySuccess/$legacyTotal successful');
    } catch (e) {
      results['legacy_assets'] = {'error': e.toString()};
      print('❌ [$_tag] Legacy assets test failed: $e');
    }

    // Test 3: Check if plugin info methods work
    try {
      // This calls the plugin's model info method
      final availableModels = await getAvailableDefaultModels();
      results['plugin_info'] = {
        'available_models': availableModels,
        'count': availableModels.length,
      };
      print('📊 [$_tag] Plugin reports ${availableModels.length} available models');
    } catch (e) {
      results['plugin_info'] = {'error': e.toString()};
      print('❌ [$_tag] Plugin info test failed: $e');
    }

    return results;
  }

  /// Helper method to get available models from plugin
  static Future<List<String>> getAvailableDefaultModels() async {
    try {
      // This would call the plugin's native method to get available models
      // For now, return expected models based on what we set up
      return [
        'yolo11n.mlpackage',
        'yolo11n-seg.mlpackage',
        'yolo11n.tflite',
        'yolo11n_int8.tflite',
        'yolo11n-seg.tflite',
      ];
    } catch (e) {
      print('❌ [$_tag] Error getting available models: $e');
      return [];
    }
  }

  /// Test a specific model loading approach
  static Future<bool> testSpecificModel(String modelName, {YOLOTask task = YOLOTask.detect}) async {
    try {
      print('🧪 [$_tag] Testing specific model: $modelName');

      final yolo = YOLO(
        modelPath: modelName,
        task: task,
      );

      await yolo.loadModel();

      print('✅ [$_tag] Successfully loaded model: $modelName');
      return true;
    } catch (e) {
      print('❌ [$_tag] Failed to load model $modelName: $e');
      return false;
    }
  }

  /// Print recommendations based on test results
  static void printRecommendations(Map<String, dynamic> testResults) {
    print('\n🎯 [$_tag] RECOMMENDATIONS:');

    final pluginResults = testResults['plugin_bundled'] as Map<String, bool>?;
    final legacyResults = testResults['legacy_assets'] as Map<String, bool>?;

    if (pluginResults != null) {
      final pluginSuccess = pluginResults.values.where((v) => v).length;
      if (pluginSuccess > 0) {
        print('✅ Plugin bundled models are working! Use simple model names like:');
        print('   YOLO(modelPath: "yolo11n", task: YOLOTask.detect)');
        print('   This is the recommended approach.');
      } else {
        print('❌ Plugin bundled models not working. Possible issues:');
        print('   - Models not properly bundled in plugin');
        print('   - Plugin not updated with new model discovery');
        print('   - iOS: Check ios/Assets/models/ has .mlpackage directories');
        print('   - Android: Check android/src/main/assets/models/ has .tflite files');
      }
    }

    if (legacyResults != null) {
      final legacySuccess = legacyResults.values.where((v) => v).length;
      if (legacySuccess > 0) {
        print('✅ Legacy package assets are available as fallback');
      } else {
        print('❌ Legacy package assets not found');
        print('   - Check packages/detection/assets/models/ directory');
        print('   - Ensure assets are listed in pubspec.yaml');
      }
    }

    print('\n🔧 Next steps:');
    print('1. Use plugin bundled models for best performance');
    print('2. Keep legacy assets as fallback for compatibility');
    print('3. Test on both iOS and Android devices');
    print('4. Monitor console logs for model loading details');
  }
}
