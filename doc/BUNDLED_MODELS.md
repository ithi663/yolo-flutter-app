# Bundled Models Guide

The Ultralytics YOLO Flutter plugin supports bundled models that are shipped directly with the plugin for better performance and offline capability. This guide explains how to use bundled models in your Flutter applications.

## Overview

Bundled models are pre-packaged YOLO models that are included in the plugin's native assets:

- **iOS**: Models stored in `/ios/Assets/models/` as `.mlpackage` directories
- **Android**: Models stored in `/android/src/main/assets/models/` as `.tflite` files

### Benefits of Bundled Models

1. **Instant Availability**: No download required - models are ready immediately
2. **Offline Capability**: Works without internet connection
3. **Better Performance**: Faster loading compared to downloaded models
4. **Reduced App Size**: No need to bundle models in your app's assets
5. **Automatic Platform Optimization**: iOS gets `.mlpackage`, Android gets `.tflite`

## Available Bundled Models

The plugin currently ships with these bundled models:

| Model Name | Task | iOS (.mlpackage) | Android (.tflite) | Description |
|------------|------|------------------|-------------------|-------------|
| `yolo11n` | Detection | ✅ | ✅ | Nano model (fastest, smallest) |
| `yolo11n_int8` | Detection | ❌ | ✅ | Nano model with int8 quantization |
| `yolo11n-seg` | Segmentation | ✅ | ✅ | Nano segmentation model |

## Basic Usage

### 1. Using YOLO Class with Bundled Models

```dart
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

// Create YOLO instance with bundled model
final yolo = YOLO(
  modelPath: 'yolo11n', // Just the model name, no path or extension
  task: YOLOTask.detect,
  useBundledModel: true, // Enable bundled model usage
);

// Load the model
await yolo.loadModel();

// Use for inference
final results = await yolo.predict(imageBytes);
```

### 2. Using YOLOImageProcessor with Bundled Models

```dart
final processor = YOLOImageProcessor();

final results = await processor.detectInImageFile(
  'path/to/image.jpg',
  modelPath: 'yolo11n', // Just the model name
  task: YOLOTask.detect,
  useBundledModel: true, // Enable bundled model usage
  confidenceThreshold: 0.4,
);
```

## Advanced Usage

### Checking Available Models

```dart
// Get all available bundled models
final availableModels = await YOLOBundledModels.getAvailableModels();
print('Available bundled models: $availableModels');

// Check if a specific model is available
final isAvailable = await YOLOBundledModels.isModelAvailable('yolo11n');
if (isAvailable) {
  print('yolo11n model is bundled and ready to use');
}
```

### Getting Recommended Models

```dart
// Get recommended model for a specific task
final detectModel = await YOLOBundledModels.getRecommendedModel(YOLOTask.detect);
final segmentModel = await YOLOBundledModels.getRecommendedModel(YOLOTask.segment);

print('Recommended detection model: $detectModel');
print('Recommended segmentation model: $segmentModel');
```

### Fallback Strategy

```dart
Future<YOLO?> createYOLOWithFallback(YOLOTask task) async {
  // First, try to use bundled model
  final bundledModel = await YOLOBundledModels.getRecommendedModel(task);
  
  if (bundledModel != null) {
    try {
      final yolo = YOLO(
        modelPath: bundledModel,
        task: task,
        useBundledModel: true,
      );
      
      final success = await yolo.loadModel();
      if (success) {
        return yolo; // Successfully loaded bundled model
      }
    } catch (e) {
      print('Failed to load bundled model: $e');
    }
  }
  
  // Fallback to regular model loading
  final yolo = YOLO(
    modelPath: 'assets/models/yolo11n.tflite',
    task: task,
    useBundledModel: false,
  );
  
  await yolo.loadModel();
  return yolo;
}
```

## Utility Methods

### YOLOBundledModels Class

The `YOLOBundledModels` class provides several utility methods:

```dart
// Check if a model is available
bool isAvailable = await YOLOBundledModels.isModelAvailable('yolo11n');

// Get all available models
List<String> models = await YOLOBundledModels.getAvailableModels();

// Get recommended model for a task
String? model = await YOLOBundledModels.getRecommendedModel(YOLOTask.detect);

// Validate model name format
bool isValid = YOLOBundledModels.isValidBundledModelName('yolo11n'); // true
bool isInvalid = YOLOBundledModels.isValidBundledModelName('assets/models/yolo11n.tflite'); // false

// Get platform-specific information
String extension = YOLOBundledModels.getPlatformModelExtension(); // .mlpackage or .tflite
String directory = YOLOBundledModels.getBundledModelsDirectory();
```

## Model Name Validation

When using bundled models, the model path should be just the model name without:
- Path separators (`/` or `\`)
- File extensions (`.tflite`, `.mlpackage`)
- Directory paths

✅ **Valid bundled model names:**
- `yolo11n`
- `yolo11n-seg`
- `my_custom_model`

❌ **Invalid bundled model names:**
- `assets/models/yolo11n.tflite` (contains path)
- `yolo11n.tflite` (contains extension)
- `` (empty string)

## Platform-Specific Behavior

### iOS
- Bundled models are stored as `.mlpackage` directories in `/ios/Assets/models/`
- The plugin automatically resolves `yolo11n` to `yolo11n.mlpackage`
- Uses Core ML for optimized inference

### Android
- Bundled models are stored as `.tflite` files in `/android/src/main/assets/models/`
- The plugin automatically resolves `yolo11n` to `yolo11n.tflite`
- Uses TensorFlow Lite for inference

## Error Handling

```dart
try {
  final yolo = YOLO(
    modelPath: 'yolo11n',
    task: YOLOTask.detect,
    useBundledModel: true,
  );
  
  final success = await yolo.loadModel();
  if (!success) {
    print('Failed to load bundled model');
  }
} on ModelLoadingException catch (e) {
  print('Model loading error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Best Practices

1. **Check Availability First**: Always check if a bundled model is available before using it
2. **Use Fallback Strategy**: Implement fallback to regular models if bundled models fail
3. **Validate Model Names**: Use `YOLOBundledModels.isValidBundledModelName()` to validate names
4. **Task-Specific Models**: Use appropriate models for your task (e.g., `yolo11n-seg` for segmentation)
5. **Platform Awareness**: Consider platform differences when designing your app

## Migration from Regular Models

If you're currently using regular model loading, you can easily migrate to bundled models:

### Before (Regular Models)
```dart
final yolo = YOLO(
  modelPath: 'assets/models/yolo11n.tflite',
  task: YOLOTask.detect,
);
```

### After (Bundled Models)
```dart
final yolo = YOLO(
  modelPath: 'yolo11n', // Just the model name
  task: YOLOTask.detect,
  useBundledModel: true, // Enable bundled models
);
```

## Troubleshooting

### Model Not Found
If you get a "Model not found" error:
1. Check if the model is actually bundled using `YOLOBundledModels.isModelAvailable()`
2. Verify the model name format (no paths or extensions)
3. Ensure `useBundledModel: true` is set

### Platform-Specific Issues
- **iOS**: Make sure the `.mlpackage` directory exists in `/ios/Assets/models/`
- **Android**: Make sure the `.tflite` file exists in `/android/src/main/assets/models/`

### Performance Issues
- Bundled models should load faster than downloaded models
- If performance is poor, check if the correct platform-optimized model is being used

## Example App

See `example/test_files/test_bundled_models.dart` for a complete example demonstrating all bundled model features. 