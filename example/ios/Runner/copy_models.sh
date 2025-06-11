#!/bin/bash

# Script to copy preloaded YOLO models to the app bundle
# This avoids CoreML auto-compilation conflicts while providing default models

echo "📦 Copying preloaded YOLO models to app bundle..."

# Source and destination paths
SOURCE_DIR="${SRCROOT}/Runner/Resources/models"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Resources/models"

# Create destination directory
mkdir -p "${DEST_DIR}"

# Copy model files if they exist
if [ -d "${SOURCE_DIR}" ]; then
    echo "✅ Copying models from ${SOURCE_DIR} to ${DEST_DIR}"
    cp -R "${SOURCE_DIR}/"* "${DEST_DIR}/" 2>/dev/null || true
    
    # List what was copied
    if [ -d "${DEST_DIR}" ]; then
        echo "📋 Models copied to app bundle:"
        ls -la "${DEST_DIR}"
    fi
else
    echo "ℹ️  No preloaded models found at ${SOURCE_DIR}"
fi

echo "✅ Model copy script completed" 