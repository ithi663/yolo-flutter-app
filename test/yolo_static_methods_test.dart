// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_platform_interface.dart';
import 'package:ultralytics_yolo/yolo_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YOLO Static Methods', () {
    const MethodChannel channel = MethodChannel('yolo_single_image_channel');
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);

            switch (methodCall.method) {
              case 'checkModelExists':
                return {
                  'exists': true,
                  'path': methodCall.arguments['modelPath'],
                  'location': 'assets',
                };
              case 'getStoragePaths':
                return {
                  'internal': '/data/internal',
                  'cache': '/data/cache',
                  'external': '/storage/external',
                };
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });



    test('checkModelExists returns model information', () async {
      final result = await YOLO.checkModelExists('test_model.tflite');

      expect(result['exists'], true);
      expect(result['path'], 'test_model.tflite');
      expect(result['location'], 'assets');
      expect(log.last.method, 'checkModelExists');
      expect(log.last.arguments['modelPath'], 'test_model.tflite');
    });

    test('getStoragePaths returns storage locations', () async {
      final paths = await YOLO.getStoragePaths();

      expect(paths['internal'], '/data/internal');
      expect(paths['cache'], '/data/cache');
      expect(paths['external'], '/storage/external');
      expect(log.last.method, 'getStoragePaths');
    });

    test('checkModelExists handles platform exceptions gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Test error');
          });

      final result = await YOLO.checkModelExists('test_model.tflite');

      expect(result['exists'], false);
      expect(result['error'], 'Test error');
    });

    test('getStoragePaths handles platform exceptions gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Storage error');
          });

      final paths = await YOLO.getStoragePaths();

      expect(paths, isEmpty);
    });
  });

  group('YOLO Error Handling', () {
    const MethodChannel channel = MethodChannel('yolo_single_image_channel');
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'loadModel throws ModelLoadingException for MODEL_NOT_FOUND',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              throw PlatformException(
                code: 'MODEL_NOT_FOUND',
                message: 'Model file not found',
              );
            });

        final yolo = YOLO(
          modelPath: 'missing_model.tflite',
          task: YOLOTask.detect,
        );

        expect(() => yolo.loadModel(), throwsA(isA<ModelLoadingException>()));
      },
    );

    test('loadModel throws ModelLoadingException for INVALID_MODEL', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(
              code: 'INVALID_MODEL',
              message: 'Invalid model format',
            );
          });

      final yolo = YOLO(
        modelPath: 'invalid_model.tflite',
        task: YOLOTask.detect,
      );

      expect(() => yolo.loadModel(), throwsA(isA<ModelLoadingException>()));
    });

    test('predict throws InvalidInputException for empty image data', () async {
      final yolo = YOLO(modelPath: 'test_model.tflite', task: YOLOTask.detect);
      final emptyImage = Uint8List(0);

      expect(
        () => yolo.predict(emptyImage),
        throwsA(isA<InvalidInputException>()),
      );
    });

    test(
      'predict throws ModelNotLoadedException for MODEL_NOT_LOADED',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              throw PlatformException(
                code: 'MODEL_NOT_LOADED',
                message: 'Model not loaded',
              );
            });

        final yolo = YOLO(
          modelPath: 'test_model.tflite',
          task: YOLOTask.detect,
        );
        final image = Uint8List.fromList([1, 2, 3, 4]);

        expect(
          () => yolo.predict(image),
          throwsA(isA<ModelNotLoadedException>()),
        );
      },
    );

    test('predict throws InvalidInputException for INVALID_IMAGE', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(
              code: 'INVALID_IMAGE',
              message: 'Invalid image format',
            );
          });

      final yolo = YOLO(modelPath: 'test_model.tflite', task: YOLOTask.detect);
      final image = Uint8List.fromList([1, 2, 3, 4]);

      expect(() => yolo.predict(image), throwsA(isA<InvalidInputException>()));
    });

    test('predict throws InferenceException for INFERENCE_ERROR', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(
              code: 'INFERENCE_ERROR',
              message: 'Inference failed',
            );
          });

      final yolo = YOLO(modelPath: 'test_model.tflite', task: YOLOTask.detect);
      final image = Uint8List.fromList([1, 2, 3, 4]);

      expect(() => yolo.predict(image), throwsA(isA<InferenceException>()));
    });

    test('predict handles invalid result format', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            return 'invalid_result_format';
          });

      final yolo = YOLO(modelPath: 'test_model.tflite', task: YOLOTask.detect);
      final image = Uint8List.fromList([1, 2, 3, 4]);

      expect(() => yolo.predict(image), throwsA(isA<InferenceException>()));
    });
  });

  group('YOLO additional static methods', () {
    test('checkModelExists handles PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('yolo_single_image_channel'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'checkModelExists') {
                throw PlatformException(
                  code: 'ERROR',
                  message: 'Platform error',
                );
              }
              return null;
            },
          );

      final result = await YOLO.checkModelExists('model.tflite');
      expect(result['exists'], false);
      expect(result['path'], 'model.tflite');
      expect(result['error'], contains('Platform error'));
    });
  });

  group('YOLO Static Detection Methods', () {
    const MethodChannel channel = MethodChannel('yolo_single_image_channel');
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);

            switch (methodCall.method) {
              case 'detectInImage':
                return [
                  {
                    'classIndex': 0,
                    'className': 'person',
                    'confidence': 0.95,
                    'boundingBox': {'left': 100.0, 'top': 100.0, 'right': 200.0, 'bottom': 300.0},
                    'normalizedBox': {'left': 0.1, 'top': 0.1, 'right': 0.2, 'bottom': 0.3},
                  },
                ];
              case 'detectInImageFile':
                return [
                  {
                    'classIndex': 1,
                    'className': 'car',
                    'confidence': 0.87,
                    'boundingBox': {'left': 50.0, 'top': 50.0, 'right': 150.0, 'bottom': 100.0},
                    'normalizedBox': {'left': 0.05, 'top': 0.05, 'right': 0.15, 'bottom': 0.1},
                  },
                ];
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('detectInImage performs detection with image bytes', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final results = await YOLOPlatform.instance.detectInImage(
        imageBytes,
        modelPath: 'test_model.tflite',
        task: 'detect',
        confidenceThreshold: 0.5,
        iouThreshold: 0.4,
        maxDetections: 10,
      );

      expect(results, isA<List<YOLOResult>>());
      expect(results.length, 1);
      expect(results[0].className, 'person');
      expect(results[0].confidence, 0.95);
      expect(log.last.method, 'detectInImage');
      expect(log.last.arguments['modelPath'], 'test_model.tflite');
      expect(log.last.arguments['task'], 'detect');
      expect(log.last.arguments['confidenceThreshold'], 0.5);
      expect(log.last.arguments['iouThreshold'], 0.4);
      expect(log.last.arguments['maxDetections'], 10);
    });

    test('detectInImageFile performs detection with file path', () async {
      final results = await YOLOPlatform.instance.detectInImageFile(
        '/path/to/image.jpg',
        modelPath: 'test_model.tflite',
        task: 'detect',
        confidenceThreshold: 0.6,
        iouThreshold: 0.5,
        maxDetections: 5,
      );

      expect(results, isA<List<YOLOResult>>());
      expect(results.length, 1);
      expect(results[0].className, 'car');
      expect(results[0].confidence, 0.87);
      expect(log.last.method, 'detectInImageFile');
      expect(log.last.arguments['imagePath'], '/path/to/image.jpg');
      expect(log.last.arguments['modelPath'], 'test_model.tflite');
      expect(log.last.arguments['task'], 'detect');
      expect(log.last.arguments['confidenceThreshold'], 0.6);
      expect(log.last.arguments['iouThreshold'], 0.5);
      expect(log.last.arguments['maxDetections'], 5);
    });

    test('detectInImage handles platform exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'detectInImage') {
              throw PlatformException(
                code: 'DETECTION_ERROR',
                message: 'Detection failed',
              );
            }
            return null;
          });

      final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      expect(
        () => YOLOPlatform.instance.detectInImage(
          imageBytes,
          modelPath: 'test_model.tflite',
          task: 'detect',
        ),
        throwsA(isA<PlatformException>()),
      );
    });

    test('detectInImageFile handles platform exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'detectInImageFile') {
              throw PlatformException(
                code: 'FILE_NOT_FOUND',
                message: 'Image file not found',
              );
            }
            return null;
          });

      expect(
        () => YOLOPlatform.instance.detectInImageFile(
          '/invalid/path.jpg',
          modelPath: 'test_model.tflite',
          task: 'detect',
        ),
        throwsA(isA<PlatformException>()),
      );
    });

    test('detectInImage with default parameters', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      await YOLOPlatform.instance.detectInImage(
        imageBytes,
        modelPath: 'test_model.tflite',
        task: 'detect',
      );

      expect(log.isNotEmpty, true);
      expect(log.last.method, 'detectInImage');
      expect(log.last.arguments['confidenceThreshold'], 0.25);
      expect(log.last.arguments['iouThreshold'], 0.45);
      expect(log.last.arguments['maxDetections'], 100);
    });

    test('detectInImageFile with custom parameters', () async {
      await YOLOPlatform.instance.detectInImageFile(
        '/path/to/image.jpg',
        modelPath: 'custom_model.tflite',
        task: 'segment',
        confidenceThreshold: 0.8,
        iouThreshold: 0.3,
        maxDetections: 50,
      );

      expect(log.isNotEmpty, true);
      expect(log.last.method, 'detectInImageFile');
      expect(log.last.arguments['task'], 'segment');
      expect(log.last.arguments['confidenceThreshold'], 0.8);
      expect(log.last.arguments['iouThreshold'], 0.3);
      expect(log.last.arguments['maxDetections'], 50);
    });
  });
}
