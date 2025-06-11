#!/bin/bash

echo "🔍 Verifying Preloaded YOLO Models Setup"
echo "========================================"

# Check if model file exists
MODEL_PATH="ios/Runner/Resources/models/yolo11n.mlpackage.data"
if [ -d "$MODEL_PATH" ]; then
    echo "✅ Model found: $MODEL_PATH"
    echo "   Size: $(du -sh "$MODEL_PATH" | cut -f1)"
    echo "   Contents:"
    ls -la "$MODEL_PATH"
else
    echo "❌ Model not found at: $MODEL_PATH"
    echo "   Please run the setup steps in PRELOAD_YOLO_SETUP.md"
fi

echo ""

# Check if BasePredictor has been updated
echo "🔍 Checking BasePredictor.swift..."
if grep -q "Found preloaded model in main app bundle" ../ios/Classes/BasePredictor.swift 2>/dev/null; then
    echo "✅ BasePredictor.swift updated with preload support"
else
    echo "❌ BasePredictor.swift missing preload support"
fi

echo ""

# Check if test file exists
echo "🔍 Checking test file..."
if [ -f "test_files/test_preloaded_models.dart" ]; then
    echo "✅ Test file available: test_files/test_preloaded_models.dart"
else
    echo "❌ Test file missing: test_files/test_preloaded_models.dart"
fi

echo ""

# Check if YOLOPlugin has printModelInfo support
echo "🔍 Checking YOLOPlugin.swift..."
if grep -q "printModelInfo" ../ios/Classes/YOLOPlugin.swift 2>/dev/null; then
    echo "✅ YOLOPlugin.swift has printModelInfo support"
else
    echo "❌ YOLOPlugin.swift missing printModelInfo support"
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Add Resources folder to Xcode project (see PRELOAD_YOLO_SETUP.md)"
echo "2. Run the test: PreloadedModelsTest()"
echo "3. Check for 'Found preloaded model' in console"
echo "4. Enjoy 15x faster model loading! 🚀" 