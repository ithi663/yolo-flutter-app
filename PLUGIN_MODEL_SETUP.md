# YOLO Flutter Plugin - Model Setup Guide

This guide explains how to set up fallback models in the YOLO Flutter plugin for both iOS and Android platforms.

## Overview

The plugin now supports automatic fallback to pre-bundled models when:
- No custom model URL is provided
- Custom model loading fails
- Offline inference is required

## Directory Structure

```
yolo-flutter-app/
├── ios/
│   └── Assets/
│       └── models/
│           ├── README.md
│           ├── yolov8n.mlmodelc      (place iOS models here)
│           └── yolov8s.mlmodelc
├── android/
│   └── src/main/assets/
│       └── models/
│           ├── README.md
│           ├── yolov8n.tflite        (place Android models here)
│           └── yolov8s.tflite
└── example/
    └── assets/
        └── models/                    (example app models)
```

## iOS Setup

### 1. Add Models to iOS Plugin

```bash
# Create models directory (already done)
mkdir -p ios/Assets/models

# Add your CoreML models
cp your_models/*.mlmodelc ios/Assets/models/
```

### 2. Update Xcode Project

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on the plugin target → "Add Files"
3. Select the `ios/Assets/models` directory
4. Choose "Create folder references" (not groups)
5. Ensure models are added to the plugin target, not the app target

### 3. Verify Bundle Resources

1. Select your plugin target in Xcode
2. Go to "Build Phases" tab
3. Expand "Copy Bundle Resources"
4. Ensure your model files are listed there

## Android Setup

### 1. Add Models to Android Plugin

```bash
# Create models directory (already done)
mkdir -p android/src/main/assets/models

# Add your TensorFlow Lite models
cp your_models/*.tflite android/src/main/assets/models/
```

### 2. No Additional Configuration Needed

Android automatically includes files in `src/main/assets` in the APK.

## Model Format Guidelines

### iOS Models
- **Preferred**: `.mlmodelc` (compiled CoreML models)
- **Alternative**: `.mlmodel` (source CoreML models)
- **Tools**: Use Xcode's CoreML compiler or Python `coremltools`

### Android Models
- **Preferred**: `.tflite` (TensorFlow Lite models)
- **Alternative**: `.onnx` (ONNX models)
- **Tools**: Use TensorFlow Lite converter or ONNX runtime

### Model Naming Convention

Use these names in order of preference:
1. `yolov8n`, `yolov8s`, `yolov8m`, `yolov8l`, `yolov8x`
2. `yolov5n`, `yolov5s`, `yolov5m`, `yolov5l`, `yolov5x`
3. `yolo`, `model`, `default`

## Converting Models

### For iOS (CoreML)

```python
# Convert PyTorch to CoreML
import torch
import coremltools as ct

# Load your PyTorch model
model = torch.hub.load('ultralytics/yolov8', 'yolov8n')

# Export to CoreML
model.export(format='coreml')
```

### For Android (TensorFlow Lite)

```bash
# Convert PyTorch to TensorFlow Lite
yolo export model=yolov8n.pt format=tflite

# Or convert ONNX to TensorFlow Lite
python -m tf2onnx.convert --onnx model.onnx --output model.tflite
```

## Usage in Flutter Code

### Basic Usage (Auto-fallback)

```dart
// Will automatically use bundled models if no URL provided
final predictor = await YOLOPredictor.create();
```

### With Custom Model and Fallback

```dart
// Will try custom model first, then fall back to bundled models
final predictor = await YOLOPredictor.create(
  modelPath: 'path/to/custom/model.mlmodelc', // iOS
  // modelPath: 'path/to/custom/model.tflite', // Android
);
```

### Check Available Models

```dart
// Get list of available bundled models
final availableModels = YOLOPredictor.getAvailableModels();
print('Available models: $availableModels');

// Print detailed model information
YOLOPredictor.printModelInfo();
```

## Testing the Setup

### 1. Build and Run

```bash
cd example
flutter clean
flutter pub get
flutter run
```

### 2. Check Console Output

Look for messages like:
```
Found default model in Plugin bundle (models): yolov8n.mlmodelc
Successfully loaded model: yolov8n.mlmodelc
```

### 3. Test Fallback Behavior

```dart
// Test with invalid custom model (should fallback)
final predictor = await YOLOPredictor.create(
  modelPath: 'invalid/path/model.mlmodelc',
);
// Should succeed using bundled model
```

## Best Practices

### Model Selection
- **Mobile devices**: Use `yolov8n` or `yolov8s` for best performance
- **Tablets**: Can handle `yolov8m` for better accuracy
- **High-end devices**: Consider `yolov8l` or `yolov8x`

### Bundle Size Optimization
- Only include essential models to minimize app size
- Consider on-demand model downloading for larger models
- Use model quantization for smaller file sizes

### Error Handling
```dart
try {
  final predictor = await YOLOPredictor.create();
  // Use predictor
} catch (e) {
  if (e is YOLOModelError) {
    print('Model error: ${e.message}');
    // Handle specific model errors
  } else {
    print('Unknown error: $e');
  }
}
```

## Troubleshooting

### iOS Issues
- **Models not found**: Check if models are in "Copy Bundle Resources"
- **Loading fails**: Verify model format is `.mlmodelc` or `.mlmodel`
- **Bundle issues**: Clean and rebuild the project

### Android Issues
- **Models not found**: Ensure models are in `src/main/assets/models/`
- **Format errors**: Check if models are in `.tflite` format
- **Size issues**: Consider model compression or quantization

### Common Issues
- **No models available**: Run `YOLOPredictor.printModelInfo()` to debug
- **Loading timeout**: Check model file integrity
- **Memory issues**: Use smaller models or implement model management

## Plugin Development

When developing the plugin:

1. **Update podspec**: Ensure `s.resource_bundles` includes Assets
2. **Test on devices**: Verify models load on physical devices
3. **Check bundle sizes**: Monitor impact on app size
4. **Document models**: Keep README files updated

## Security Considerations

- Models in bundles are publicly accessible
- Consider encrypting sensitive models
- Implement model integrity checks
- Monitor for model tampering 