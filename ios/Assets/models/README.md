# YOLO Models Directory

This directory contains pre-bundled YOLO models for the iOS plugin.

## Adding Models

1. **Place your YOLO models here:**
   - Preferred: `.mlmodelc` files (compiled CoreML models)
   - Alternative: `.mlmodel` files (source CoreML models)

2. **Supported model names (in order of preference):**
   - `yolov8n.mlmodelc`, `yolov8s.mlmodelc`, `yolov8m.mlmodelc`, `yolov8l.mlmodelc`, `yolov8x.mlmodelc`
   - `yolov5n.mlmodelc`, `yolov5s.mlmodelc`, `yolov5m.mlmodelc`, `yolov5l.mlmodelc`, `yolov5x.mlmodelc`
   - `yolo.mlmodelc`, `model.mlmodelc`, `default.mlmodelc`

3. **Xcode Project Setup:**
   - Add model files to your iOS project in Xcode
   - Make sure they're included in the plugin target
   - Verify they appear in "Copy Bundle Resources" build phase

## Example Structure
```
ios/Assets/models/
├── yolov8n.mlmodelc       (recommended for mobile)
├── yolov8s.mlmodelc       (better accuracy)
└── custom_model.mlmodelc  (your custom model)
```

## Usage

The plugin will automatically discover and use these models as fallbacks when:
- No custom model URL is provided
- A custom model URL fails to load
- App requires offline inference capability

## Model Priority

The plugin searches for models in this order:
1. Custom model URL (if provided)
2. Plugin bundle models (this directory)
3. Main app bundle models (fallback)

## Notes

- Models in this directory are bundled with the plugin
- They increase the plugin size but provide offline capability
- Users can still override with custom models at runtime
- For Android, place equivalent models in `android/src/main/assets/models/` 