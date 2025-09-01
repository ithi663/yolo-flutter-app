// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

package com.ultralytics.yolo

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.net.Uri
import org.tensorflow.lite.support.common.FileUtil

val ultralyticsColors: List<Int> = listOf(
    Color.argb(153, 4, 42, 255),
    Color.argb(153, 11, 219, 235),
    Color.argb(153, 243, 243, 243),
    Color.argb(153, 0, 223, 183),
    Color.argb(153, 17, 31, 104),
    Color.argb(153, 255, 111, 221),
    Color.argb(153, 255, 68, 79),
    Color.argb(153, 204, 237, 0),
    Color.argb(153, 0, 243, 68),
    Color.argb(153, 189, 0, 255),
    Color.argb(153, 0, 180, 255),
    Color.argb(153, 221, 0, 186),
    Color.argb(153, 0, 255, 255),
    Color.argb(153, 38, 192, 0),
    Color.argb(153, 1, 255, 179),
    Color.argb(153, 125, 36, 255),
    Color.argb(153, 123, 0, 104),
    Color.argb(153, 255, 27, 108),
    Color.argb(153, 252, 109, 47),
    Color.argb(153, 162, 255, 11)
)

/**
 * Utility functions for YOLO operations
 */
object YOLOUtils {
    private const val TAG = "YOLOUtils"
    
    /**
     * Checks if the provided path is an absolute file path
     */
    fun isAbsolutePath(path: String): Boolean {
        // Treat file:// URIs as absolute paths as well
        return path.startsWith("/") || path.startsWith("file://")
    }

    /**
     * Normalize filesystem path by handling file:// URIs
     */
    private fun normalizeFilesystemPath(path: String): String {
        return if (path.startsWith("file://")) {
            try {
                Uri.parse(path).path ?: path
            } catch (_: Exception) {
                path
            }
        } else path
    }

    /**
     * Checks if a file exists at the specified absolute path
     */
    fun fileExistsAtPath(path: String): Boolean {
        val file = java.io.File(path)
        return file.exists() && file.isFile
    }
    
    /**
     * Loads a model file from either assets or the file system.
     * Supports both asset paths and absolute file system paths.
     * If the provided model path doesn't include an extension, ".tflite" will be appended.
     * 
     * @param context The application context
     * @param modelPath The model path (can be an asset path or absolute filesystem path)
     * @return ByteBuffer containing the model data
     */
    fun loadModelFile(context: Context, modelPath: String): java.nio.MappedByteBuffer {
        val withExt = ensureTFLiteExtension(modelPath)
        Log.d(TAG, "Loading model. Requested: $modelPath, withExt: $withExt")

        // 1) Absolute path fast-path
        val normalizedWithExt = normalizeFilesystemPath(withExt)
        if (isAbsolutePath(normalizedWithExt) && fileExistsAtPath(normalizedWithExt)) {
            Log.d(TAG, "Loading model from absolute path: $normalizedWithExt")
            return loadModelFromFilesystem(normalizedWithExt)
        }
        val normalizedOriginal = normalizeFilesystemPath(modelPath)
        if (isAbsolutePath(normalizedOriginal) && fileExistsAtPath(normalizedOriginal)) {
            Log.d(TAG, "Loading model from absolute path (no-ext given): $normalizedOriginal")
            return loadModelFromFilesystem(normalizedOriginal)
        }

        // 2) Try common Flutter asset variants via AssetManager.
        // Flutter packs assets under 'flutter_assets/'. Typical keys are like 'assets/models/foo.tflite'.
        // We'll try multiple variants to be robust to what Flutter passes from Dart.
        val candidates = mutableListOf(
            withExt,
            modelPath,
        )
        // If not already prefixed, add likely variants
        if (!withExt.startsWith("assets/")) candidates.add("assets/$withExt")
        if (!withExt.startsWith("flutter_assets/")) candidates.add("flutter_assets/$withExt")
        if (!withExt.startsWith("flutter_assets/assets/")) candidates.add("flutter_assets/assets/$withExt")

        if (!modelPath.startsWith("assets/")) candidates.add("assets/$modelPath")
        if (!modelPath.startsWith("flutter_assets/")) candidates.add("flutter_assets/$modelPath")
        if (!modelPath.startsWith("flutter_assets/assets/")) candidates.add("flutter_assets/assets/$modelPath")

        val tried = mutableSetOf<String>()
        var lastError: Exception? = null
        for (candidate in candidates) {
            if (!tried.add(candidate)) continue
            try {
                Log.d(TAG, "Trying to load model from asset candidate: $candidate")
                return FileUtil.loadMappedFile(context, candidate)
            } catch (e: Exception) {
                lastError = e
                Log.d(TAG, "Asset candidate failed: $candidate -> ${e.message}")
            }
        }

        Log.e(TAG, "Failed to load model from all candidates. Throwing last error: ${lastError?.message}")
        throw (lastError ?: java.io.FileNotFoundException("Model not found: $withExt"))
    }
    
    /**
     * Loads a model file from the filesystem
     * @param filePath Absolute path to the model file
     * @return ByteBuffer containing the model data
     */
    private fun loadModelFromFilesystem(filePath: String): java.nio.MappedByteBuffer {
        val file = java.io.File(filePath)
        val raf = java.io.RandomAccessFile(file, "r")
        val channel = raf.channel
        val size = channel.size()
        val mapped = channel.map(java.nio.channels.FileChannel.MapMode.READ_ONLY, 0L, size)
        try {
            channel.close()
        } catch (_: Exception) { }
        try {
            raf.close()
        } catch (_: Exception) { }
        return mapped
    }
    
    /**
     * Ensure the model path has a .tflite extension
     */
    fun ensureTFLiteExtension(modelPath: String): String {
        return if (!modelPath.lowercase().endsWith(".tflite")) {
            "$modelPath.tflite"
        } else {
            modelPath
        }
    }
    
    /**
     * Checks all possible paths where a model could be found
     * @param context Application context
     * @param modelPath Path to check (could be asset or absolute path)
     * @return Map containing status and resolved path
     */
    fun checkModelExistence(context: Context, modelPath: String): Map<String, Any> {
        // Try with .tflite extension
        val withExtension = ensureTFLiteExtension(modelPath)

        // Check absolute paths first
        val normalizedWithExt = normalizeFilesystemPath(withExtension)
        if (isAbsolutePath(normalizedWithExt) && fileExistsAtPath(normalizedWithExt)) {
            return mapOf("exists" to true, "path" to normalizedWithExt, "location" to "filesystem")
        }
        val normalizedOriginal = normalizeFilesystemPath(modelPath)
        if (isAbsolutePath(normalizedOriginal) && fileExistsAtPath(normalizedOriginal)) {
            return mapOf("exists" to true, "path" to normalizedOriginal, "location" to "filesystem")
        }

        // Then check assets (consider Flutter's packaging under flutter_assets/)
        val assetCandidates = listOf(
            withExtension,
            modelPath,
            if (!withExtension.startsWith("assets/")) "assets/$withExtension" else withExtension,
            if (!withExtension.startsWith("flutter_assets/")) "flutter_assets/$withExtension" else withExtension,
            if (!withExtension.startsWith("flutter_assets/assets/")) "flutter_assets/assets/$withExtension" else withExtension,
            if (!modelPath.startsWith("assets/")) "assets/$modelPath" else modelPath,
            if (!modelPath.startsWith("flutter_assets/")) "flutter_assets/$modelPath" else modelPath,
            if (!modelPath.startsWith("flutter_assets/assets/")) "flutter_assets/assets/$modelPath" else modelPath,
        ).distinct()

        for (candidate in assetCandidates) {
            try {
                // Use open() instead of openFd() to avoid failures on compressed assets
                context.assets.open(candidate).close()
                return mapOf("exists" to true, "path" to candidate, "location" to "assets")
            } catch (_: Exception) {
                // continue trying other candidates
            }
        }

        return mapOf("exists" to false, "path" to modelPath, "location" to "unknown")
    }
}
