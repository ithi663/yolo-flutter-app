# YOLO Model Loading Guide

A quick guide on how to load YOLO models for object detection in Flutter.

## 🎯 Three Ways to Load Models

### 1. **YOLO Class** (Explicit Loading)
```dart
// Create YOLO instance
final yolo = YOLO(
  modelPath: 'yolo11n',
  task: YOLOTask.detect,
);

// Load model explicitly
await yolo.loadModel();

// Run inference
final results = await yolo.predict(imageBytes);
```

### 2. **YOLOImageProcessor** (Automatic Loading)
```dart
// Create processor
final processor = YOLOImageProcessor();

// Model loads automatically on first use
final results = await processor.detectInImage(
  imageBytes,
  modelPath: 'yolo11n',
  task: YOLOTask.detect,
);
```

### 3. **YOLOView** (Real-time Camera)
```dart
YOLOView(
  modelPath: 'yolo11n',  // Loads when view is created
  task: YOLOTask.detect,
  onResult: (results) {
    print('Found ${results.length} objects');
  },
)
```

## 📁 Model Path Formats

| Format | Example | Use Case |
|--------|---------|----------|
| **Simple name** | `'yolo11n'` | Platform resolves automatically |
| **Asset path** | `'assets/models/yolo11n.tflite'` | Bundled with app |
| **Absolute path** | `'/data/user/0/.../yolo11n.tflite'` | Downloaded models |
| **Internal storage** | `'internal://models/yolo11n.tflite'` | App's internal directory |

## 🔧 Getting Models

### Option 1: Automatic Download (Recommended)
```dart
// Simple automatic model loading - no manual setup needed!
final processor = YOLOImageProcessor();
final results = await processor.detectInImage(
  imageBytes,
  modelPath: 'yolo11n',  // Downloads automatically if not found
  task: YOLOTask.detect,
);
```

### Option 2: Manual Bundling (Example App Approach)
The example app demonstrates manual model bundling for offline use:

**Step 1: Add Models to Assets**
Place models in `assets/models/` directory:

**iOS Models (Core ML format):**
- `yolo11n.mlpackage.zip` (Object Detection - 2.5MB)
- `yolo11n-seg.mlpackage.zip` (Segmentation - 2.7MB)

**Android Models (TensorFlow Lite format):**
- `yolo11n.tflite` (Object Detection - 5.4MB)
- `yolo11n-seg.tflite` (Segmentation - 5.9MB)
- `yolo11n_int8.tflite` (Object Detection Quantized - 2.8MB)

**Step 2: Update pubspec.yaml**
```yaml
flutter:
  assets:
    - assets/models/
    # iOS Models (Core ML format)
    - assets/models/yolo11n.mlpackage.zip
    - assets/models/yolo11n-seg.mlpackage.zip
    # Android Models (TensorFlow Lite format)
    - assets/models/yolo11n.tflite
    - assets/models/yolo11n-seg.tflite
    - assets/models/yolo11n_int8.tflite
```

**Step 3: Add Required Dependencies**
```yaml
dependencies:
  path_provider: ^2.0.0  # For iOS local storage
  archive: ^3.0.0        # For unzipping .mlpackage files
```

**Step 4: Platform-Specific Handling**
```dart
// iOS: Extract .mlpackage.zip to local storage
if (Platform.isIOS) {
  final localPath = await _copyMlPackageFromAssets();
  modelPath = localPath ?? 'yolo11n-seg';  // fallback
} else {
  // Android: Use .tflite directly from assets
  modelPath = 'yolo11n-seg';
}

final yolo = YOLO(modelPath: modelPath, task: YOLOTask.segment);
```

**Platform-Specific Notes:**
- **iOS**: Requires extracting `.mlpackage.zip` to Documents directory (see example app)
- **Android**: Directly uses `.tflite` files from assets
- **Cross-platform**: Need both formats for universal compatibility

### Option 3: Direct Platform Bundling
Alternative to assets approach:
- **Android**: Place `.tflite` files in `android/app/src/main/assets/`
- **iOS**: Drag `.mlpackage` files into Xcode project

### Option 4: Download Programmatically
```dart
// Use ModelManager from example app (downloads if not found locally)
final modelManager = ModelManager();
final modelPath = await modelManager.getModelPath(ModelType.detect);
```

### Option 5: Manual Download More Models
Download from [GitHub Releases](https://github.com/ultralytics/assets/releases/download/v8.3.0/):
- **Detection**: `yolo11n.pt`, `yolo11s.pt`, `yolo11m.pt`, `yolo11l.pt`, `yolo11x.pt`
- **Segmentation**: `yolo11n-seg.pt`, `yolo11s-seg.pt`, `yolo11m-seg.pt`
- **Pose**: `yolo11n-pose.pt`, `yolo11s-pose.pt`, `yolo11m-pose.pt`

## 🎨 Available Models

| Model | Task | Description |
|-------|------|-------------|
| `yolo11n` | Detection | Object detection with bounding boxes |
| `yolo11n-seg` | Segmentation | Instance segmentation with masks |
| `yolo11n-pose` | Pose | Human pose estimation |
| `yolo11n-cls` | Classification | Image classification |
| `yolo11n-obb` | OBB | Oriented bounding boxes |

## ⚡ Quick Start

```dart
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

// Simplest approach - automatic loading
final processor = YOLOImageProcessor();
final results = await processor.detectInImage(
  imageBytes,
  modelPath: 'yolo11n',
  task: YOLOTask.detect,
);

// Process results
for (final result in results) {
  print('${result.className}: ${result.confidence}');
}
```

## 🚨 Error Handling

```dart
try {
  await yolo.loadModel();
} on ModelLoadingException catch (e) {
  if (e.message.contains('MODEL_NOT_FOUND')) {
    print('Model file not found - check path or download model');
  }
}
```

## 💡 Best Practices

- ✅ Use **YOLOImageProcessor** for simple static image processing
- ✅ Use **YOLO class** when you need to reuse the same model multiple times
- ✅ Use **YOLOView** for real-time camera detection
- ✅ Bundle small models with your app for offline use
- ✅ Download larger models on-demand to reduce app size
