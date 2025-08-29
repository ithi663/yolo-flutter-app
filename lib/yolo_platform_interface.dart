// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'yolo_method_channel.dart';
import 'yolo_result.dart';

/// The interface that implementations of the Ultralytics YOLO plugin must implement.
///
/// This class uses the [PlatformInterface] pattern to ensure that platform-specific
/// implementations properly extend this class rather than implementing it.
///
/// Platform implementations should extend this class rather than implement it as `yolo`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [YOLOPlatform] methods.
///
/// The plugin uses method channels for communication between Flutter and native code.
/// Each platform (iOS, Android) provides its own implementation of the YOLO inference engine.
abstract class YOLOPlatform extends PlatformInterface {
  /// Constructs a YOLOPlatform.
  YOLOPlatform() : super(token: _token);

  static final Object _token = Object();

  static YOLOPlatform _instance = YOLOMethodChannel();

  /// The default instance of [YOLOPlatform] to use.
  ///
  /// Defaults to [YOLOMethodChannel].
  static YOLOPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [YOLOPlatform] when
  /// they register themselves.
  static set instance(YOLOPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the current platform version.
  ///
  /// This method is primarily used for testing and debugging to verify that
  /// the method channel communication is working correctly between Flutter
  /// and the native platform.
  ///
  /// Each platform implementation should override this method to return
  /// meaningful platform information.
  ///
  /// Returns a string containing the platform name and version
  /// (e.g., "Android 12" or "iOS 15.0"), or null if unavailable.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Sets the model for an existing YOLO view.
  ///
  /// This method allows switching the model on an existing YOLO view instance
  /// without recreating the entire view.
  ///
  /// Parameters:
  /// - [viewId]: The unique identifier of the YOLO view
  /// - [modelPath]: The path to the new model file
  /// - [task]: The YOLO task type for the new model
  ///
  /// Throws:
  /// - [UnimplementedError] if not implemented by the platform
  /// - Platform-specific exceptions if the model switch fails
  Future<void> setModel(int viewId, String modelPath, String task) {
    throw UnimplementedError('setModel() has not been implemented.');
  }

  /// Performs object detection on image bytes.
  ///
  /// This method takes image data as bytes and performs YOLO inference,
  /// returning a list of detection results.
  ///
  /// Parameters:
  /// - [imageBytes]: The image data as Uint8List
  /// - [modelPath]: The path to the YOLO model file
  /// - [task]: The YOLO task type (detect, segment, classify, pose, obb)
  /// - [useBundledModel]: Whether to prefer bundled models (iOS: .mlpackage, Android: .tflite)
  /// - [confidenceThreshold]: Minimum confidence score for detections (0.0-1.0)
  /// - [iouThreshold]: IoU threshold for Non-Maximum Suppression (0.0-1.0)
  /// - [maxDetections]: Maximum number of detections to return
  /// - [generateAnnotatedImage]: Whether to generate annotated image (disabled by default for performance)
  ///
  /// Returns a list of [YOLOResult] objects containing detection information.
  ///
  /// Throws:
  /// - [UnimplementedError] if not implemented by the platform
  /// - Platform-specific exceptions if inference fails
  Future<List<YOLOResult>> detectInImage(
    Uint8List imageBytes, {
    required String modelPath,
    required String task,
    bool useBundledModel = false,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int maxDetections = 100,
    bool generateAnnotatedImage = false,
  }) {
    throw UnimplementedError('detectInImage() has not been implemented.');
  }

  /// Performs object detection on an image file.
  ///
  /// This method loads an image from a file path and performs YOLO inference,
  /// returning a list of detection results.
  ///
  /// Parameters:
  /// - [imagePath]: The path to the image file
  /// - [modelPath]: The path to the YOLO model file
  /// - [task]: The YOLO task type (detect, segment, classify, pose, obb)
  /// - [useBundledModel]: Whether to prefer bundled models (iOS: .mlpackage, Android: .tflite)
  /// - [confidenceThreshold]: Minimum confidence score for detections (0.0-1.0)
  /// - [iouThreshold]: IoU threshold for Non-Maximum Suppression (0.0-1.0)
  /// - [maxDetections]: Maximum number of detections to return
  /// - [generateAnnotatedImage]: Whether to generate annotated image (disabled by default for performance)
  ///
  /// Returns a list of [YOLOResult] objects containing detection information.
  ///
  /// Throws:
  /// - [UnimplementedError] if not implemented by the platform
  /// - Platform-specific exceptions if inference fails
  Future<List<YOLOResult>> detectInImageFile(
    String imagePath, {
    required String modelPath,
    required String task,
    bool useBundledModel = false,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int maxDetections = 100,
    bool generateAnnotatedImage = false,
  }) {
    throw UnimplementedError('detectInImageFile() has not been implemented.');
  }
}
