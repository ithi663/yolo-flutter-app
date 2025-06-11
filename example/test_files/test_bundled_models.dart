// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// Example demonstrating how to use bundled YOLO models.
///
/// This example shows how to:
/// 1. Check which models are bundled and available
/// 2. Use bundled models for inference
/// 3. Fall back to regular model loading if bundled models aren't available
class BundledModelsExample {
  /// Example 1: Check available bundled models
  static Future<void> checkAvailableModels() async {
    print('=== Checking Available Bundled Models ===');

    // Get all available bundled models
    final availableModels = await YOLOBundledModels.getAvailableModels();
    print('Available bundled models: $availableModels');

    // Check specific models
    for (final model in ['yolo11n', 'yolo11n-seg', 'yolo11n_int8']) {
      final isAvailable = await YOLOBundledModels.isModelAvailable(model);
      print('$model is ${isAvailable ? 'available' : 'not available'}');
    }

    // Get recommended model for different tasks
    final detectModel = await YOLOBundledModels.getRecommendedModel(YOLOTask.detect);
    final segmentModel = await YOLOBundledModels.getRecommendedModel(YOLOTask.segment);

    print('Recommended detection model: $detectModel');
    print('Recommended segmentation model: $segmentModel');
  }

  /// Example 2: Use bundled model with YOLO class
  static Future<YOLO?> createYOLOWithBundledModel(YOLOTask task) async {
    print('=== Creating YOLO with Bundled Model ===');

    // Get recommended bundled model for the task
    final modelName = await YOLOBundledModels.getRecommendedModel(task);

    if (modelName == null) {
      print('No bundled model available for task: $task');
      return null;
    }

    print('Using bundled model: $modelName for task: $task');

    // Create YOLO instance with bundled model
    final yolo = YOLO(
      modelPath: modelName, // Just the model name, no path or extension
      task: task,
      useBundledModel: true, // Enable bundled model usage
    );

    try {
      final success = await yolo.loadModel();
      if (success) {
        print('Successfully loaded bundled model: $modelName');
        return yolo;
      } else {
        print('Failed to load bundled model: $modelName');
        return null;
      }
    } catch (e) {
      print('Error loading bundled model: $e');
      return null;
    }
  }

  /// Example 3: Use bundled model with YOLOImageProcessor
  static Future<void> processImageWithBundledModel(String imagePath) async {
    print('=== Processing Image with Bundled Model ===');

    final processor = YOLOImageProcessor();

    // Get recommended bundled model for detection
    final modelName = await YOLOBundledModels.getRecommendedModel(YOLOTask.detect);

    if (modelName == null) {
      print('No bundled detection model available');
      return;
    }

    try {
      final results = await processor.detectInImageFile(
        imagePath,
        modelPath: modelName, // Just the model name
        task: YOLOTask.detect,
        useBundledModel: true, // Enable bundled model usage
        confidenceThreshold: 0.4,
      );

      print('Detected ${results.length} objects using bundled model: $modelName');
      for (final result in results) {
        print('- ${result.className}: ${(result.confidence * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      print('Error processing image with bundled model: $e');
    }
  }

  /// Example 4: Fallback strategy - try bundled first, then regular model
  static Future<YOLO?> createYOLOWithFallback(YOLOTask task) async {
    print('=== Creating YOLO with Fallback Strategy ===');

    // First, try to use bundled model
    final bundledModel = await YOLOBundledModels.getRecommendedModel(task);

    if (bundledModel != null) {
      print('Attempting to use bundled model: $bundledModel');

      try {
        final yolo = YOLO(
          modelPath: bundledModel,
          task: task,
          useBundledModel: true,
        );

        final success = await yolo.loadModel();
        if (success) {
          print('Successfully loaded bundled model: $bundledModel');
          return yolo;
        }
      } catch (e) {
        print('Failed to load bundled model: $e');
      }
    }

    // Fallback to regular model loading
    print('Falling back to regular model loading...');

    String fallbackModelPath;
    switch (task) {
      case YOLOTask.segment:
        fallbackModelPath = 'assets/models/yolo11n-seg.tflite';
        break;
      case YOLOTask.detect:
      default:
        fallbackModelPath = 'assets/models/yolo11n.tflite';
        break;
    }

    try {
      final yolo = YOLO(
        modelPath: fallbackModelPath,
        task: task,
        useBundledModel: false, // Use regular model loading
      );

      final success = await yolo.loadModel();
      if (success) {
        print('Successfully loaded fallback model: $fallbackModelPath');
        return yolo;
      } else {
        print('Failed to load fallback model: $fallbackModelPath');
        return null;
      }
    } catch (e) {
      print('Error loading fallback model: $e');
      return null;
    }
  }

  /// Example 5: Validate model names for bundled usage
  static void validateModelNames() {
    print('=== Validating Model Names ===');

    final testCases = [
      'yolo11n', // Valid
      'yolo11n-seg', // Valid
      'assets/models/yolo11n.tflite', // Invalid (contains path)
      'yolo11n.tflite', // Invalid (contains extension)
      '', // Invalid (empty)
      'my_custom_model', // Valid (custom name)
    ];

    for (final modelName in testCases) {
      final isValid = YOLOBundledModels.isValidBundledModelName(modelName);
      print('$modelName: ${isValid ? 'Valid' : 'Invalid'}');
    }
  }

  /// Example 6: Get platform-specific information
  static void showPlatformInfo() {
    print('=== Platform Information ===');

    final extension = YOLOBundledModels.getPlatformModelExtension();
    final directory = YOLOBundledModels.getBundledModelsDirectory();

    print('Platform model extension: $extension');
    print('Bundled models directory: $directory');
    print('Available models: ${YOLOBundledModels.availableModels}');
  }
}

/// Widget demonstrating bundled models usage in a Flutter app
class BundledModelsDemo extends StatefulWidget {
  const BundledModelsDemo({super.key});

  @override
  State<BundledModelsDemo> createState() => _BundledModelsDemoState();
}

class _BundledModelsDemoState extends State<BundledModelsDemo> {
  List<String> _availableModels = [];
  String? _selectedModel;
  YOLO? _yolo;
  bool _isLoading = false;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking available models...';
    });

    try {
      final models = await YOLOBundledModels.getAvailableModels();
      setState(() {
        _availableModels = models;
        _selectedModel = models.isNotEmpty ? models.first : null;
        _status = 'Found ${models.length} bundled models';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking models: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSelectedModel() async {
    if (_selectedModel == null) return;

    setState(() {
      _isLoading = true;
      _status = 'Loading model: $_selectedModel';
    });

    try {
      final yolo = YOLO(
        modelPath: _selectedModel!,
        task: YOLOTask.detect,
        useBundledModel: true,
      );

      final success = await yolo.loadModel();
      if (success) {
        setState(() {
          _yolo = yolo;
          _status = 'Model loaded successfully: $_selectedModel';
        });
      } else {
        setState(() {
          _status = 'Failed to load model: $_selectedModel';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error loading model: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bundled Models Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Bundled Models',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_availableModels.isEmpty)
                      const Text('No bundled models found')
                    else
                      DropdownButton<String>(
                        value: _selectedModel,
                        isExpanded: true,
                        items: _availableModels.map((model) {
                          return DropdownMenuItem(
                            value: model,
                            child: Text(model),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedModel = value;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _loadSelectedModel,
              child: Text(_isLoading ? 'Loading...' : 'Load Selected Model'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_yolo != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '✅ Model ready for inference',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Platform Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Model Extension: ${YOLOBundledModels.getPlatformModelExtension()}'),
                    Text('Models Directory: ${YOLOBundledModels.getBundledModelsDirectory()}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _yolo?.dispose();
    super.dispose();
  }
}
