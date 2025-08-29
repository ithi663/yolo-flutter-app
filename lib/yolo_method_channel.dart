// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'yolo_platform_interface.dart';
import 'yolo_result.dart';

/// An implementation of [YOLOPlatform] that uses method channels.
///
/// This class provides the default implementation for communicating
/// with platform-specific YOLO implementations through Flutter's
/// method channel API. It handles single image predictions and
/// other static YOLO operations.
///
/// This implementation is automatically registered as the default
/// platform interface and should not be instantiated directly.
class YOLOMethodChannel extends YOLOPlatform {
  /// The method channel used to interact with the native platform.
  ///
  /// This channel is used for single image predictions and other
  /// operations that don't require a platform view.
  @visibleForTesting
  final methodChannel = const MethodChannel('yolo_single_image_channel');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> setModel(int viewId, String modelPath, String task) async {
    await methodChannel.invokeMethod<void>('setModel', {
      'viewId': viewId,
      'modelPath': modelPath,
      'task': task,
    });
  }

  @override
  Future<List<YOLOResult>> detectInImage(
    Uint8List imageBytes, {
    required String modelPath,
    required String task,
    bool useBundledModel = false,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int maxDetections = 100,
    bool generateAnnotatedImage = false,
  }) async {
    final results = await methodChannel.invokeListMethod<dynamic>('detectInImage', {
      'imageBytes': imageBytes,
      'modelPath': modelPath,
      'task': task,
      'useBundledModel': useBundledModel,
      'confidenceThreshold': confidenceThreshold,
      'iouThreshold': iouThreshold,
      'maxDetections': maxDetections,
      'generateAnnotatedImage': generateAnnotatedImage,
    });
    return _parseResults(results);
  }

  @override
  Future<List<YOLOResult>> detectInImageFile(
    String imagePath, {
    required String modelPath,
    required String task,
    bool useBundledModel = false,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int maxDetections = 100,
    bool generateAnnotatedImage = false,
  }) async {
    final results = await methodChannel.invokeListMethod<dynamic>('detectInImageFile', {
      'imagePath': imagePath,
      'modelPath': modelPath,
      'task': task,
      'useBundledModel': useBundledModel,
      'confidenceThreshold': confidenceThreshold,
      'iouThreshold': iouThreshold,
      'maxDetections': maxDetections,
      'generateAnnotatedImage': generateAnnotatedImage,
    });
    return _parseResults(results);
  }

  /// Parses the raw results from the platform channel into YOLOResult objects.
  ///
  /// The results are expected to be a list of maps, where each map represents
  /// a detection result with keys like 'classIndex', 'className', 'confidence',
  /// 'boundingBox', etc.
  List<YOLOResult> _parseResults(List<dynamic>? results) {
    if (results == null || results.isEmpty) {
      return <YOLOResult>[];
    }

    return results
        .whereType<Map<dynamic, dynamic>>()
        .map((result) => YOLOResult.fromMap(result))
        .toList();
  }
}
