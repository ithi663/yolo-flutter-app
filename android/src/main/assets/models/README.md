# YOLO Models Directory (Android)

This directory contains pre-bundled YOLO models for the Android plugin.

## Adding Models

1. **Place your YOLO models here:**
   - Preferred: `.tflite` files (TensorFlow Lite models)
   - Alternative: `.onnx` files (ONNX models)
   - For CoreML compatibility: `.mlmodel` files (if cross-platform needed)

2. **Supported model names (in order of preference):**
   - `yolov8n.tflite`, `yolov8s.tflite`, `yolov8m.tflite`, `yolov8l.tflite`, `yolov8x.tflite`
   - `yolov5n.tflite`, `yolov5s.tflite`, `yolov5m.tflite`, `yolov5l.tflite`, `yolov5x.tflite`
   - `yolo.tflite`, `model.tflite`, `default.tflite`

3. **Android Project Setup:**
   - Models placed here are automatically included in the APK
   - Accessible via `AssetManager` at runtime
   - No additional configuration needed

## Example Structure
```
android/src/main/assets/models/
├── yolov8n.tflite         (recommended for mobile)
├── yolov8s.tflite         (better accuracy)
└── custom_model.tflite    (your custom model)
```

## Usage

The Android plugin will automatically discover and use these models as fallbacks when:
- No custom model path is provided
- A custom model file fails to load
- App requires offline inference capability

## Model Priority

The Android plugin searches for models in this order:
1. Custom model path (if provided)
2. Plugin assets models (this directory)
3. App assets models (fallback)

## Converting Models for Android

To convert YOLO models for Android:

```bash
# Convert PyTorch to TensorFlow Lite
yolo export model=yolov8n.pt format=tflite

# Convert ONNX to TensorFlow Lite
python -m tf2onnx.convert --onnx model.onnx --output model.tflite
```

## Notes

- Models in this directory are bundled with the plugin
- They increase the APK size but provide offline capability
- Android typically uses TensorFlow Lite instead of CoreML
- For iOS, place equivalent CoreML models in `ios/Assets/models/`
- Ensure model formats are optimized for mobile devices 