// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ultralytics_yolo/yolo_platform_interface.dart';
import 'package:ultralytics_yolo/yolo_result.dart';

class MockYOLOPlatform with MockPlatformInterfaceMixin implements YOLOPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> setModel(int viewId, String modelPath, String task) =>
      Future.value();

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
  }) => Future.value([]);

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
  }) => Future.value([]);
}

class _UnimplementedYOLOPlatform extends YOLOPlatform {
  Future<String?> callPlatformVersion() => super.getPlatformVersion();
  Future<void> callSetModel() => super.setModel(1, 'model.tflite', 'detect');
}

class _FakePlatform implements YOLOPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('fake');

  @override
  Future<void> setModel(int viewId, String modelPath, String task) async {}

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
  }) async => [];

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
  }) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YOLOPlatform', () {
    test('getPlatformVersion returns expected value from mock', () async {
      YOLOPlatform.instance = MockYOLOPlatform();
      expect(await YOLOPlatform.instance.getPlatformVersion(), '42');
    });

    test('default getPlatformVersion throws UnimplementedError', () {
      final platform = _UnimplementedYOLOPlatform();
      expect(
        () => platform.callPlatformVersion(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default setModel throws UnimplementedError', () {
      final platform = _UnimplementedYOLOPlatform();
      expect(() => platform.callSetModel(), throwsA(isA<UnimplementedError>()));
    });

    test('Cannot set instance with invalid token', () {
      expect(
        () => YOLOPlatform.instance = _FakePlatform(),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
