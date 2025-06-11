# Preload YOLO Models Setup Guide

This guide shows how to preload YOLO models into your iOS app to avoid the extraction step and provide instant model loading.

## 📋 Overview

Instead of extracting models from `.zip` files at runtime, this approach:
- ✅ **Bundles models directly** in the iOS app
- ✅ **Avoids CoreML auto-compilation conflicts** by using `.data` extension
- ✅ **Provides instant loading** without extraction
- ✅ **Maintains fallback compatibility** with your existing approach

## 🚀 Setup Steps

### 1. Prepare the Model Files

The models are already prepared in the correct format:
```
example/ios/Runner/Resources/models/
└── yolo11n.mlpackage.data  # Renamed to avoid CoreML compilation
```

### 2. Add Models to Xcode Project

**Option A: Using Xcode (Recommended)**
1. Open `example/ios/Runner.xcworkspace` in Xcode
2. Right-click on the `Runner` group in the project navigator
3. Select "Add Files to Runner..."
4. Navigate to `ios/Runner/Resources` folder
5. Select the `Resources` folder and click "Add"
6. Make sure "Add to target: Runner" is checked
7. Choose "Create folder references" (not groups)

**Option B: Manual Info.plist Method**
Add this to your `ios/Runner/Info.plist` in the `<dict>` section:
```xml
<key>LSApplicationCategoryType</key>
<string>public.app-category.productivity</string>
<!-- Add your app's bundle resources -->
<key>CFBundleResourceSpecification</key>
<string>Resources</string>
```

### 3. Verify Setup

Build and run your app. You should see in the console:
```
✅ Found preloaded model in main app bundle: yolo11n.mlpackage (converted from .data)
```

## 🔧 How It Works

### Model Discovery Process
1. **Plugin bundle search** (empty now to avoid conflicts)
2. **Main app bundle preloaded models** (our new approach)
3. **Legacy extraction fallback** (your existing system)

### File Handling
```swift
// Models stored as .data files in main bundle
yolo11n.mlpackage.data → temp_models/yolo11n.mlpackage

// When loading:
1. Find: Resources/models/yolo11n.mlpackage.data
2. Copy to: Documents/temp_models/yolo11n.mlpackage  
3. Load: temp_models/yolo11n.mlpackage
```

## 📱 Expected Results

### Before (Legacy Extraction)
```
[INFO: YoloService] 🔄 [_loadModelLegacy] Using legacy model loading approach
[INFO: YoloService] 📦 [_copyMlPackageFromAssets] Loading asset: packages/detection/assets/models/yolo11n.mlpackage.zip
[INFO: YoloService] 📦 [_copyMlPackageFromAssets] Asset loaded, size: 2503012 bytes
```

### After (Preloaded Models)
```
[INFO: YoloService] ✅ [loadModel] Plugin bundled model loaded successfully: yolo11n
```

## 🧪 Testing

Use your existing test to verify:
```dart
// This should now return true
final result = await platform.invokeMethod('checkModelExists', {
  'modelPath': 'yolo11n'
});
// Expected: {exists: true, location: "plugin_bundle_model"}
```

## 🔄 Adding More Models

To add more models (like yolo11n-seg):
1. Copy model to `ios/Runner/Resources/models/`
2. Rename to `.data` extension: `yolo11n-seg.mlpackage.data`
3. Rebuild the app

## 🛠 Troubleshooting

### Models Still Not Found
1. Check Xcode project includes the Resources folder
2. Verify models have `.data` extension
3. Check console for "Found preloaded model" messages

### Build Conflicts
- Make sure models have `.data` extension (not `.mlpackage`)
- Don't add `.mlpackage` files directly to Xcode

### Legacy Fallback Still Working
- This is expected and good! It ensures compatibility
- Preloaded models take priority when found

## 🎯 Performance Benefits

- **Instant loading**: No extraction delay
- **Smaller app startup**: Models ready immediately  
- **Better UX**: Faster first prediction
- **Fallback safety**: Legacy system as backup 