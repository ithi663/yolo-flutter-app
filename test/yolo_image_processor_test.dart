// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultralytics_yolo/yolo_image_processor.dart';
import 'package:ultralytics_yolo/yolo_result.dart';
import 'package:ultralytics_yolo/yolo_task.dart';
import 'package:ultralytics_yolo/yolo_platform_interface.dart';
import 'package:ultralytics_yolo/yolo_method_channel.dart';

// Mock implementation of YOLOPlatform for testing
class MockYOLOPlatform extends YOLOPlatform {
  final List<YOLOResult> mockResults;

  MockYOLOPlatform({this.mockResults = const []});

  @override
  Future<String?> getPlatformVersion() async {
    return 'Mock Platform 1.0';
  }

  @override
  Future<void> setModel(int viewId, String modelPath, String task) async {
    // Mock implementation
  }

  @override
  Future<List<YOLOResult>> detectInImage(
    Uint8List imageBytes, {
    required String modelPath,
    required String task,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int maxDetections = 100,
  }) async {
    if (imageBytes.isEmpty) {
      throw PlatformException(code: 'image_error', message: 'Empty image');
    }
    return mockResults.take(maxDetections).toList();
  }

  @override
  Future<List<YOLOResult>> detectInImageFile(
    String imagePath, {
    required String modelPath,
    required String task,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int maxDetections = 100,
  }) async {
    if (imagePath.isEmpty) {
      throw PlatformException(code: 'image_error', message: 'Empty path');
    }
    return mockResults.take(maxDetections).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YOLOImageProcessor', () {
    late YOLOImageProcessor processor;
    late MockYOLOPlatform mockPlatform;

    setUp(() {
      processor = YOLOImageProcessor();

      // Create mock results
      mockPlatform = MockYOLOPlatform(
        mockResults: [
          YOLOResult(
            classIndex: 0,
            className: 'person',
            confidence: 0.95,
            boundingBox: const Rect.fromLTWH(100, 100, 200, 300),
            normalizedBox: const Rect.fromLTWH(0.1, 0.1, 0.2, 0.3),
          ),
          YOLOResult(
            classIndex: 1,
            className: 'car',
            confidence: 0.88,
            boundingBox: const Rect.fromLTWH(200, 200, 150, 100),
            normalizedBox: const Rect.fromLTWH(0.2, 0.2, 0.15, 0.1),
          ),
        ],
      );

      // Set the mock platform as the instance
      YOLOPlatform.instance = mockPlatform;
    });

    tearDown(() {
      // Reset to default platform
      YOLOPlatform.instance = YOLOMethodChannel();
    });

    group('detectInImage', () {
      test('should detect objects in image bytes', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3, 4]); // Mock image data
        const modelPath = 'assets/models/yolo11n.tflite';
        const task = YOLOTask.detect;

        // Act
        final results = await processor.detectInImage(imageBytes, modelPath: modelPath, task: task);

        // Assert
        expect(results, hasLength(2));
        expect(results[0].className, equals('person'));
        expect(results[0].confidence, equals(0.95));
        expect(results[1].className, equals('car'));
        expect(results[1].confidence, equals(0.88));
      });

      test('should throw ArgumentError for empty image bytes', () async {
        // Arrange
        final imageBytes = Uint8List(0);
        const modelPath = 'assets/models/yolo11n.tflite';
        const task = YOLOTask.detect;

        // Act & Assert
        expect(
          () => processor.detectInImage(imageBytes, modelPath: modelPath, task: task),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate confidence threshold', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
        const modelPath = 'assets/models/yolo11n.tflite';
        const task = YOLOTask.detect;

        // Act & Assert
        expect(
          () => processor.detectInImage(
            imageBytes,
            modelPath: modelPath,
            task: task,
            confidenceThreshold: -0.1,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => processor.detectInImage(
            imageBytes,
            modelPath: modelPath,
            task: task,
            confidenceThreshold: 1.1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate IoU threshold', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
        const modelPath = 'assets/models/yolo11n.tflite';
        const task = YOLOTask.detect;

        // Act & Assert
        expect(
          () => processor.detectInImage(
            imageBytes,
            modelPath: modelPath,
            task: task,
            iouThreshold: -0.1,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => processor.detectInImage(
            imageBytes,
            modelPath: modelPath,
            task: task,
            iouThreshold: 1.1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate max detections', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
        const modelPath = 'assets/models/yolo11n.tflite';
        const task = YOLOTask.detect;

        // Act & Assert
        expect(
          () => processor.detectInImage(
            imageBytes,
            modelPath: modelPath,
            task: task,
            maxDetections: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => processor.detectInImage(
            imageBytes,
            modelPath: modelPath,
            task: task,
            maxDetections: -1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should limit results to maxDetections', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
        const modelPath = 'assets/models/yolo11n.tflite';
        const task = YOLOTask.detect;

        // Act
        final results = await processor.detectInImage(
          imageBytes,
          modelPath: modelPath,
          task: task,
          maxDetections: 1,
        );

        // Assert
        expect(results, hasLength(1));
        expect(results[0].className, equals('person'));
      });
    });

    group('detectInImageFile', () {
      test('should detect objects in image file', () async {
        // Arrange
        const imagePath = 'path/to/image.jpg';
        const modelPath = 'assets/models/yolo11n.tflite';
        const task = YOLOTask.detect;

        // Act
        final results = await processor.detectInImageFile(
          imagePath,
          modelPath: modelPath,
          task: task,
        );

        // Assert
        expect(results, hasLength(2));
        expect(results[0].className, equals('person'));
        expect(results[1].className, equals('car'));
      });

      test('should throw ArgumentError for empty image path', () async {
        // Arrange
        const imagePath = '';
        const modelPath = 'assets/models/yolo11n.tflite';
        const task = YOLOTask.detect;

        // Act & Assert
        expect(
          () => processor.detectInImageFile(imagePath, modelPath: modelPath, task: task),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should apply custom thresholds', () async {
        // Arrange
        const imagePath = 'path/to/image.jpg';
        const modelPath = 'assets/models/yolo11n.tflite';
        const task = YOLOTask.detect;

        // Act
        final results = await processor.detectInImageFile(
          imagePath,
          modelPath: modelPath,
          task: task,
          confidenceThreshold: 0.5,
          iouThreshold: 0.6,
          maxDetections: 50,
        );

        // Assert
        expect(results, isNotNull);
      });
    });

    group('task support', () {
      test('should work with different YOLO tasks', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
        const modelPath = 'assets/models/yolo11n.tflite';

        // Act & Assert - should not throw for any task
        for (final task in YOLOTask.values) {
          expect(
            () => processor.detectInImage(imageBytes, modelPath: modelPath, task: task),
            returnsNormally,
          );
        }
      });
    });
  });
}
