// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// A screen that demonstrates the new YOLOImageProcessor API for static image processing.
///
/// This screen showcases the simplified API for running YOLO inference on static images
/// without needing to manage YOLO instances or model loading explicitly.
class StaticImageProcessorScreen extends StatefulWidget {
  const StaticImageProcessorScreen({super.key});

  @override
  State<StaticImageProcessorScreen> createState() => _StaticImageProcessorScreenState();
}

class _StaticImageProcessorScreenState extends State<StaticImageProcessorScreen> {
  final _picker = ImagePicker();
  final _processor = YOLOImageProcessor();

  List<YOLOResult> _results = [];
  File? _selectedImage;
  bool _isProcessing = false;
  String _selectedModel = 'yolo11n';
  YOLOTask _selectedTask = YOLOTask.detect;
  double _confidenceThreshold = 0.25;
  double _iouThreshold = 0.45;
  int _maxDetections = 100;

  // Available models for demonstration
  final List<String> _availableModels = [
    'yolo11n',
    'yolo11n-seg',
    'yolo11n-pose',
    'yolo11n-cls',
    'yolo11n-obb',
  ];

  /// Picks an image from the gallery
  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _selectedImage = File(file.path);
      _results = []; // Clear previous results
    });
  }

  /// Processes the selected image using YOLOImageProcessor
  Future<void> _processImage() async {
    if (_selectedImage == null) {
      _showSnackBar('Please select an image first');
      return;
    }

    setState(() {
      _isProcessing = true;
      _results = [];
    });

    try {
      // Read image bytes
      final imageBytes = await _selectedImage!.readAsBytes();

      // Process image using the new YOLOImageProcessor API
      final results = await _processor.detectInImage(
        imageBytes,
        modelPath: _selectedModel,
        task: _selectedTask,
        confidenceThreshold: _confidenceThreshold,
        iouThreshold: _iouThreshold,
        maxDetections: _maxDetections,
      );

      setState(() {
        _results = results;
      });

      _showSnackBar('Found ${results.length} detections');
    } catch (e) {
      _showSnackBar('Error processing image: $e');
      debugPrint('Error processing image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Processes an image file using the file path method
  Future<void> _processImageFile() async {
    if (_selectedImage == null) {
      _showSnackBar('Please select an image first');
      return;
    }

    setState(() {
      _isProcessing = true;
      _results = [];
    });

    try {
      // Process image using file path
      final results = await _processor.detectInImageFile(
        _selectedImage!.path,
        modelPath: _selectedModel,
        task: _selectedTask,
        confidenceThreshold: _confidenceThreshold,
        iouThreshold: _iouThreshold,
        maxDetections: _maxDetections,
      );

      setState(() {
        _results = results;
      });

      _showSnackBar('Found ${results.length} detections');
    } catch (e) {
      _showSnackBar('Error processing image file: $e');
      debugPrint('Error processing image file: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _buildModelSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
              items: _availableModels.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedModel = value;
                    // Auto-select appropriate task based on model name
                    if (value.contains('-seg')) {
                      _selectedTask = YOLOTask.segment;
                    } else if (value.contains('-pose')) {
                      _selectedTask = YOLOTask.pose;
                    } else if (value.contains('-cls')) {
                      _selectedTask = YOLOTask.classify;
                    } else if (value.contains('-obb')) {
                      _selectedTask = YOLOTask.obb;
                    } else {
                      _selectedTask = YOLOTask.detect;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<YOLOTask>(
              value: _selectedTask,
              decoration: const InputDecoration(
                labelText: 'Task',
                border: OutlineInputBorder(),
              ),
              items: YOLOTask.values.map((task) {
                return DropdownMenuItem(
                  value: task,
                  child: Text(task.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTask = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detection Parameters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Confidence Threshold: ${_confidenceThreshold.toStringAsFixed(2)}'),
            Slider(
              value: _confidenceThreshold,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  _confidenceThreshold = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text('IoU Threshold: ${_iouThreshold.toStringAsFixed(2)}'),
            Slider(
              value: _iouThreshold,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  _iouThreshold = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Max Detections: $_maxDetections'),
            Slider(
              value: _maxDetections.toDouble(),
              min: 1,
              max: 300,
              divisions: 299,
              onChanged: (value) {
                setState(() {
                  _maxDetections = value.round();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_selectedImage == null) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No image selected',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Image.file(
              _selectedImage!,
              fit: BoxFit.contain,
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 12),
                  Text('Processing image...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detection Results (${_results.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        '${result.className} (${(result.confidence * 100).toStringAsFixed(1)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class Index: ${result.classIndex}'),
                          Text(
                            'Bounding Box: (${result.boundingBox.left.toStringAsFixed(1)}, '
                            '${result.boundingBox.top.toStringAsFixed(1)}, '
                            '${result.boundingBox.width.toStringAsFixed(1)}, '
                            '${result.boundingBox.height.toStringAsFixed(1)})',
                          ),
                          if (result.keypoints != null)
                            Text('Keypoints: ${result.keypoints!.length}'),
                          if (result.mask != null) const Text('Segmentation mask available'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Static Image Processor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection and processing buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Image'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processImage,
                    icon: const Icon(Icons.memory),
                    label: const Text('Process (Bytes)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processImageFile,
                    icon: const Icon(Icons.file_open),
                    label: const Text('Process (File)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Model configuration
            _buildModelSelector(),
            const SizedBox(height: 16),

            // Parameter controls
            _buildParameterControls(),
            const SizedBox(height: 16),

            // Image display
            _buildImageDisplay(),
            const SizedBox(height: 16),

            // Results
            _buildResults(),
          ],
        ),
      ),
    );
  }
}
