// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:io';
import 'package:flutter/services.dart';
import 'yolo_task.dart';

/// Utility class for managing bundled YOLO models.
///
/// This class provides convenient methods for working with models that are
/// bundled directly in the plugin's native assets:
/// - iOS: Models in `/ios/Assets/models/` as .mlpackage directories
/// - Android: Models in `/android/src/main/assets/models/` as .tflite files
///
/// Bundled models provide better performance and offline capability compared
/// to downloaded models, as they are immediately available without network access.
class YOLOBundledModels {
  static const MethodChannel _channel = MethodChannel('yolo_single_image_channel');

  /// List of models that are typically bundled with the plugin.
  ///
  /// These are the standard models that ship with the Ultralytics YOLO plugin:
  /// - `yolo11n`: Nano model (fastest, smallest)
  /// - `yolo11n_int8`: Nano model with int8 quantization (Android only)
  /// - `yolo11n-seg`: Nano segmentation model
  static const List<String> availableModels = [
    'yolo11n',
    'yolo11n_int8',
    'yolo11n-seg',
  ];

  /// Checks if a specific model is bundled and available.
  ///
  /// This method verifies that the model exists in the platform's bundled assets:
  /// - iOS: Checks for `{modelName}.mlpackage` in `/ios/Assets/models/`
  /// - Android: Checks for `{modelName}.tflite` in `/android/src/main/assets/models/`
  ///
  /// Example:
  /// ```dart
  /// bool isAvailable = await YOLOBundledModels.isModelAvailable('yolo11n');
  /// if (isAvailable) {
  ///   print('yolo11n model is bundled and ready to use');
  /// }
  /// ```
  ///
  /// Returns `true` if the model is bundled and available, `false` otherwise.
  static Future<bool> isModelAvailable(String modelName) async {
    try {
      final result = await _channel.invokeMethod('checkModelExists', {
        'modelPath': modelName,
      });

      if (result is Map) {
        final exists = result['exists'] as bool? ?? false;
        final location = result['location'] as String? ?? '';

        // Consider model available if it's in plugin bundle or main bundle
        return exists &&
            (location.contains('plugin_bundle') ||
                location.contains('main_bundle') ||
                location.contains('assets'));
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Gets a list of all bundled models that are actually available on the device.
  ///
  /// This method checks each model in [availableModels] to see if it's actually
  /// bundled and available on the current platform.
  ///
  /// Example:
  /// ```dart
  /// List<String> bundledModels = await YOLOBundledModels.getAvailableModels();
  /// print('Available bundled models: $bundledModels');
  /// ```
  ///
  /// Returns a list of model names that are bundled and available.
  static Future<List<String>> getAvailableModels() async {
    final available = <String>[];

    for (final model in availableModels) {
      if (await isModelAvailable(model)) {
        available.add(model);
      }
    }

    return available;
  }

  /// Gets the recommended bundled model for a specific task.
  ///
  /// This method returns the best bundled model available for the given task:
  /// - Detection: `yolo11n`
  /// - Segmentation: `yolo11n-seg`
  /// - Classification: `yolo11n`
  /// - Pose: `yolo11n`
  /// - OBB: `yolo11n`
  ///
  /// Example:
  /// ```dart
  /// String? model = await YOLOBundledModels.getRecommendedModel(YOLOTask.detect);
  /// if (model != null) {
  ///   final yolo = YOLO(
  ///     modelPath: model,
  ///     task: YOLOTask.detect,
  ///     useBundledModel: true,
  ///   );
  /// }
  /// ```
  ///
  /// Returns the recommended model name if available, or `null` if no suitable
  /// bundled model is found.
  static Future<String?> getRecommendedModel(YOLOTask task) async {
    String preferredModel;

    switch (task) {
      case YOLOTask.segment:
        preferredModel = 'yolo11n-seg';
        break;
      case YOLOTask.detect:
      case YOLOTask.classify:
      case YOLOTask.pose:
      case YOLOTask.obb:
        preferredModel = 'yolo11n';
        break;
    }

    // Check if preferred model is available
    if (await isModelAvailable(preferredModel)) {
      return preferredModel;
    }

    // Fallback to any available model
    final available = await getAvailableModels();
    return available.isNotEmpty ? available.first : null;
  }

  /// Gets the platform-specific file extension for bundled models.
  ///
  /// Returns:
  /// - `.mlpackage` for iOS
  /// - `.tflite` for Android
  /// - `.tflite` for other platforms (default)
  static String getPlatformModelExtension() {
    if (Platform.isIOS) {
      return '.mlpackage';
    } else {
      return '.tflite';
    }
  }

  /// Gets the platform-specific bundled models directory.
  ///
  /// Returns:
  /// - `/ios/Assets/models/` for iOS
  /// - `/android/src/main/assets/models/` for Android
  /// - `/assets/models/` for other platforms (default)
  static String getBundledModelsDirectory() {
    if (Platform.isIOS) {
      return '/ios/Assets/models/';
    } else if (Platform.isAndroid) {
      return '/android/src/main/assets/models/';
    } else {
      return '/assets/models/';
    }
  }

  /// Validates that a model name is suitable for bundled model usage.
  ///
  /// This method checks if the provided model path looks like a simple model name
  /// rather than a full path, which is required when using bundled models.
  ///
  /// Example:
  /// ```dart
  /// bool isValid = YOLOBundledModels.isValidBundledModelName('yolo11n'); // true
  /// bool isInvalid = YOLOBundledModels.isValidBundledModelName('assets/models/yolo11n.tflite'); // false
  /// ```
  ///
  /// Returns `true` if the model name is valid for bundled model usage.
  static bool isValidBundledModelName(String modelPath) {
    // Should not contain path separators
    if (modelPath.contains('/') || modelPath.contains('\\')) {
      return false;
    }

    // Should not contain file extensions (they're added automatically)
    if (modelPath.contains('.')) {
      return false;
    }

    // Should not be empty
    if (modelPath.trim().isEmpty) {
      return false;
    }

    return true;
  }
}
