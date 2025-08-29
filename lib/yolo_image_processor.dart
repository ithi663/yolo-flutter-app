// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:typed_data';

import 'yolo_platform_interface.dart';
import 'yolo_result.dart';
import 'yolo_task.dart';

/// A class for performing YOLO object detection on static images.
///
/// This class provides a convenient high-level API for running YOLO inference
/// on individual images, either from memory (Uint8List) or from file paths.
/// It supports all YOLO tasks including detection, segmentation, classification,
/// pose estimation, and oriented bounding box detection.
///
/// Example usage:
/// ```dart
/// final processor = YOLOImageProcessor();
///
/// // Detect objects in an image file
/// final results = await processor.detectInImageFile(
///   'path/to/image.jpg',
///   modelPath: 'assets/models/yolo11n.tflite',
///   task: YOLOTask.detect,
///   confidenceThreshold: 0.4,
/// );
///
/// // Process results
/// for (final result in results) {
///   print('Detected ${result.className} with confidence ${result.confidence}');
///   print('Bounding box: ${result.boundingBox}');
/// }
/// ```
///
/// Example usage with bundled models:
/// ```dart
/// final processor = YOLOImageProcessor();
///
/// // Use bundled model (iOS: .mlpackage, Android: .tflite)
/// final results = await processor.detectInImageFile(
///   'path/to/image.jpg',
///   modelPath: 'yolo11n', // Just the model name
///   task: YOLOTask.detect,
///   useBundledModel: true, // Use bundled model if available
///   confidenceThreshold: 0.4,
/// );
/// ```
class YOLOImageProcessor {
  /// Get the platform instance dynamically to support testing
  YOLOPlatform get _platform => YOLOPlatform.instance;

  /// Detects objects in an in-memory image.
  ///
  /// This method takes raw image bytes and performs YOLO inference,
  /// returning a list of detection results.
  ///
  /// Parameters:
  /// - [imageBytes]: The raw image data as a Uint8List
  /// - [modelPath]: The path to the YOLO model file or model name for bundled models
  /// - [task]: The YOLO task type to perform
  /// - [useBundledModel]: Whether to prefer bundled models (iOS: .mlpackage, Android: .tflite)
  /// - [confidenceThreshold]: Minimum confidence score for detections (0.0-1.0)
  /// - [iouThreshold]: IoU threshold for Non-Maximum Suppression (0.0-1.0)
  /// - [maxDetections]: Maximum number of detections to return
  /// - [generateAnnotatedImage]: Whether to generate annotated image (disabled by default for performance)
  ///
  /// Returns a list of [YOLOResult] objects containing detection information.
  ///
  /// Example:
  /// ```dart
  /// final imageFile = File('path/to/image.jpg');
  /// final imageBytes = await imageFile.readAsBytes();
  ///
  /// final results = await processor.detectInImage(
  ///   imageBytes,
  ///   modelPath: 'assets/models/yolo11n.tflite',
  ///   task: YOLOTask.detect,
  ///   confidenceThreshold: 0.4,
  /// );
  /// ```
  ///
  /// Example with bundled model:
  /// ```dart
  /// final results = await processor.detectInImage(
  ///   imageBytes,
  ///   modelPath: 'yolo11n', // Just the model name
  ///   task: YOLOTask.detect,
  ///   useBundledModel: true, // Use bundled model
  ///   confidenceThreshold: 0.4,
  /// );
  /// ```
  ///
  /// Throws:
  /// - [ArgumentError] if imageBytes is empty or parameters are invalid
  /// - Platform-specific exceptions if inference fails
  Future<List<YOLOResult>> detectInImage(
    Uint8List imageBytes, {
    required String modelPath,
    required YOLOTask task,
    bool useBundledModel = false,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int maxDetections = 100,
    bool generateAnnotatedImage = false,
  }) async {
    _validateParameters(
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      maxDetections: maxDetections,
    );

    if (imageBytes.isEmpty) {
      throw ArgumentError('Image bytes cannot be empty');
    }

    return _platform.detectInImage(
      imageBytes,
      modelPath: modelPath,
      task: task.name,
      useBundledModel: useBundledModel,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      maxDetections: maxDetections,
      generateAnnotatedImage: generateAnnotatedImage,
    );
  }

  /// Detects objects in an image file.
  ///
  /// This method loads an image from a file path and performs YOLO inference,
  /// returning a list of detection results.
  ///
  /// Parameters:
  /// - [imagePath]: The path to the image file
  /// - [modelPath]: The path to the YOLO model file or model name for bundled models
  /// - [task]: The YOLO task type to perform
  /// - [useBundledModel]: Whether to prefer bundled models (iOS: .mlpackage, Android: .tflite)
  /// - [confidenceThreshold]: Minimum confidence score for detections (0.0-1.0)
  /// - [iouThreshold]: IoU threshold for Non-Maximum Suppression (0.0-1.0)
  /// - [maxDetections]: Maximum number of detections to return
  /// - [generateAnnotatedImage]: Whether to generate annotated image (disabled by default for performance)
  ///
  /// Returns a list of [YOLOResult] objects containing detection information.
  ///
  /// Example:
  /// ```dart
  /// final results = await processor.detectInImageFile(
  ///   'path/to/image.jpg',
  ///   modelPath: 'assets/models/yolo11n.tflite',
  ///   task: YOLOTask.detect,
  ///   confidenceThreshold: 0.4,
  /// );
  /// ```
  ///
  /// Example with bundled model:
  /// ```dart
  /// final results = await processor.detectInImageFile(
  ///   'path/to/image.jpg',
  ///   modelPath: 'yolo11n', // Just the model name
  ///   task: YOLOTask.detect,
  ///   useBundledModel: true, // Use bundled model
  ///   confidenceThreshold: 0.4,
  /// );
  /// ```
  ///
  /// Throws:
  /// - [ArgumentError] if imagePath is empty or parameters are invalid
  /// - Platform-specific exceptions if inference fails
  Future<List<YOLOResult>> detectInImageFile(
    String imagePath, {
    required String modelPath,
    required YOLOTask task,
    bool useBundledModel = false,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int maxDetections = 100,
    bool generateAnnotatedImage = false,
  }) async {
    _validateParameters(
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      maxDetections: maxDetections,
    );

    if (imagePath.isEmpty) {
      throw ArgumentError('Image path cannot be empty');
    }

    return _platform.detectInImageFile(
      imagePath,
      modelPath: modelPath,
      task: task.name,
      useBundledModel: useBundledModel,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      maxDetections: maxDetections,
      generateAnnotatedImage: generateAnnotatedImage,
    );
  }

  /// Validates the input parameters for detection methods.
  ///
  /// Throws [ArgumentError] if any parameter is invalid.
  void _validateParameters({
    required double confidenceThreshold,
    required double iouThreshold,
    required int maxDetections,
  }) {
    if (confidenceThreshold < 0.0 || confidenceThreshold > 1.0) {
      throw ArgumentError(
        'Confidence threshold must be between 0.0 and 1.0, got: $confidenceThreshold',
      );
    }

    if (iouThreshold < 0.0 || iouThreshold > 1.0) {
      throw ArgumentError('IoU threshold must be between 0.0 and 1.0, got: $iouThreshold');
    }

    if (maxDetections <= 0) {
      throw ArgumentError('Max detections must be positive, got: $maxDetections');
    }
  }
}
