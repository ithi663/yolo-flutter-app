// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo/yolo_platform_interface.dart';
import 'package:ultralytics_yolo/yolo_result.dart';
import 'package:ultralytics_yolo_example/services/model_manager.dart';
import 'package:ultralytics_yolo_example/models/model_type.dart';

/// A screen that demonstrates static YOLO detection methods.
///
/// This screen allows users to:
/// - Test detectInImage method with image data
/// - Test detectInImageFile method with file paths
/// - Adjust detection parameters (confidence, IoU, max detections)
/// - Compare results with different thresholds
class StaticDetectionScreen extends StatefulWidget {
  const StaticDetectionScreen({super.key});

  @override
  State<StaticDetectionScreen> createState() => _StaticDetectionScreenState();
}

class _StaticDetectionScreenState extends State<StaticDetectionScreen> {
  final _picker = ImagePicker();
  File? _selectedImage;
  Uint8List? _imageBytes;
  List<YOLOResult> _detections = [];
  bool _isProcessing = false;
  String _statusMessage = 'Select an image to start detection';
  
  // Detection parameters
  double _confidenceThreshold = 0.25;
  double _iouThreshold = 0.45;
  int _maxDetections = 300;
  String _selectedTask = 'detect';
  String _selectedModel = 'yolo11n';
  
  // Available models and tasks
  final List<String> _availableModels = [
    'yolo11n',
    'yolo11s', 
    'yolo11m',
    'yolo11l',
    'yolo11x'
  ];
  
  final List<String> _availableTasks = [
    'detect',
    'segment', 
    'classify',
    'pose',
    'obb'
  ];

  /// Resolve model path for Android ensuring .tflite filename with proper task suffix.
  /// For iOS and other platforms, we keep the previous behavior.
  Future<String> _resolveModelPath() async {
    if (!Platform.isAndroid) {
      // iOS/macOS: existing code relies on platform side to resolve names
      return _selectedModel;
    }

    String suffix = '';
    switch (_selectedTask) {
      case 'segment':
        suffix = '-seg';
        break;
      case 'classify':
        suffix = '-cls';
        break;
      case 'pose':
        suffix = '-pose';
        break;
      case 'obb':
        suffix = '-obb';
        break;
      case 'detect':
      default:
        suffix = '';
    }

    // If user kept yolo11n, try ModelManager for robust lookup/download
    if (_selectedModel == 'yolo11n') {
      final manager = ModelManager();
      ModelType modelType;
      switch (_selectedTask) {
        case 'segment':
          modelType = ModelType.segment;
          break;
        case 'classify':
          modelType = ModelType.classify;
          break;
        case 'pose':
          modelType = ModelType.pose;
          break;
        case 'obb':
          modelType = ModelType.obb;
          break;
        case 'detect':
        default:
          modelType = ModelType.detect;
      }

      try {
        final resolved = await manager.getModelPath(modelType);
        if (resolved != null) {
          return resolved; // May be asset filename or absolute path
        }
      } catch (_) {
        // fall through to filename fallback
      }
    }

    // Fallback: construct filename with extension for Android assets
    final base = _selectedModel + suffix;
    return '$base.tflite';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Static Detection Demo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildParametersSection(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildStatusSection(),
            const SizedBox(height: 20),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_selectedImage != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: const Center(
                  child: Text(
                    'No image selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersSection() {
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
            const SizedBox(height: 15),
            
            // Model selection
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Model:', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 3,
                  child: DropdownButton<String>(
                    value: _selectedModel,
                    isExpanded: true,
                    items: _availableModels.map((String model) {
                      return DropdownMenuItem<String>(
                        value: model,
                        child: Text(model),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedModel = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Task selection
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Task:', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 3,
                  child: DropdownButton<String>(
                    value: _selectedTask,
                    isExpanded: true,
                    items: _availableTasks.map((String task) {
                      return DropdownMenuItem<String>(
                        value: task,
                        child: Text(task),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTask = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Confidence threshold
            Text('Confidence: ${_confidenceThreshold.toStringAsFixed(2)}'),
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
            
            // IoU threshold
            Text('IoU: ${_iouThreshold.toStringAsFixed(2)}'),
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
            
            // Max detections
            Text('Max Detections: $_maxDetections'),
            Slider(
              value: _maxDetections.toDouble(),
              min: 1,
              max: 1000,
              divisions: 100,
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

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detection Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedImage != null && !_isProcessing
                        ? _detectInImage
                        : null,
                    icon: const Icon(Icons.memory),
                    label: const Text('Detect in Image\n(Memory)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedImage != null && !_isProcessing
                        ? _detectInImageFile
                        : null,
                    icon: const Icon(Icons.folder),
                    label: const Text('Detect in File\n(Path)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_isProcessing)
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Processing...'),
                ],
              )
            else
              Text(_statusMessage),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detection Results (${_detections.length} objects)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_detections.isEmpty)
              const Text(
                'No detections yet. Run detection to see results.',
                style: TextStyle(color: Colors.grey),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _detections.length,
                  itemBuilder: (context, index) {
                    final detection = _detections[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(detection.className),
                       subtitle: Text(
                         'Confidence: ${detection.confidence.toStringAsFixed(3)}\n'
                         'Box: [${detection.boundingBox.left.toStringAsFixed(1)}, ${detection.boundingBox.top.toStringAsFixed(1)}, ${detection.boundingBox.width.toStringAsFixed(1)}, ${detection.boundingBox.height.toStringAsFixed(1)}]',
                       ),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedImage = File(image.path);
          _imageBytes = imageBytes;
          _detections.clear();
          _statusMessage = 'Image selected. Ready for detection.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error selecting image: $e';
      });
    }
  }

  Future<void> _detectInImage() async {
    if (_imageBytes == null) return;

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Running detectInImage...';
      _detections.clear();
    });

    try {
      final modelPathArg = await _resolveModelPath();
      final result = await YOLOPlatform.instance.detectInImage(
        _imageBytes!,
        modelPath: modelPathArg,
        task: _selectedTask,
        confidenceThreshold: _confidenceThreshold,
        iouThreshold: _iouThreshold,
        maxDetections: _maxDetections,
      );

      if (!mounted) return;
      setState(() {
        _detections = result;
        _statusMessage = 'detectInImage completed. Found ${result.length} objects.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error in detectInImage: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _detectInImageFile() async {
    if (_selectedImage == null) return;

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Running detectInImageFile...';
      _detections.clear();
    });

    try {
      final modelPathArg = await _resolveModelPath();
      final result = await YOLOPlatform.instance.detectInImageFile(
        _selectedImage!.path,
        modelPath: modelPathArg,
        task: _selectedTask,
        confidenceThreshold: _confidenceThreshold,
        iouThreshold: _iouThreshold,
        maxDetections: _maxDetections,
      );

      if (!mounted) return;
      setState(() {
        _detections = result;
        _statusMessage = 'detectInImageFile completed. Found ${result.length} objects.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error in detectInImageFile: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }
}