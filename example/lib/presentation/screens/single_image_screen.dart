// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// A screen that demonstrates YOLO inference on a single image.
///
/// This screen allows users to:
/// - Pick an image from the gallery
/// - Run YOLO inference on the selected image using bundled models
/// - View detection results and annotated image
class SingleImageScreen extends StatefulWidget {
  const SingleImageScreen({super.key});

  @override
  State<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends State<SingleImageScreen> {
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _detections = [];
  Uint8List? _imageBytes;
  Uint8List? _annotatedImage;

  YOLO? _yolo;
  bool _isModelReady = false;
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeYOLO();
  }

  /// Initializes the YOLO model for inference using bundled models
  ///
  /// This method first tries to use bundled models for better performance
  /// and offline capability. If bundled models are not available, it falls
  /// back to the regular model loading mechanism.
  Future<void> _initializeYOLO() async {
    setState(() {
      _loadingMessage = 'Checking bundled models...';
    });

    try {
      // First, check if bundled model is available
      final isBundledAvailable = await YOLOBundledModels.isModelAvailable('yolo11n');

      if (isBundledAvailable) {
        setState(() {
          _loadingMessage = 'Loading bundled model: yolo11n';
        });

        // Use bundled model for better performance
        _yolo = YOLO(
          modelPath: 'yolo11n', // Just the model name
          task: YOLOTask.detect,
          useBundledModel: true, // Enable bundled model usage
        );

        debugPrint('Using bundled yolo11n model for detection');
      } else {
        setState(() {
          _loadingMessage = 'Bundled model not available, using fallback...';
        });

        // Fallback to regular model loading
        _yolo = YOLO(
          modelPath: 'yolo11n', // This will trigger automatic download
          task: YOLOTask.detect,
          useBundledModel: false,
        );

        debugPrint('Using fallback model loading for yolo11n');
      }

      // Load the model
      setState(() {
        _loadingMessage = 'Loading YOLO model...';
      });

      final success = await _yolo!.loadModel();

      if (success && mounted) {
        setState(() {
          _isModelReady = true;
          _loadingMessage = 'Model ready for inference';
        });
        debugPrint('YOLO model loaded successfully');
      } else {
        setState(() {
          _loadingMessage = 'Failed to load model';
        });
        debugPrint('Failed to load YOLO model');
      }
    } catch (e) {
      debugPrint('Error loading YOLO model: $e');
      if (mounted) {
        setState(() {
          _loadingMessage = 'Error: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading model: $e')),
        );
      }
    }
  }

  /// Picks an image from the gallery and runs inference
  ///
  /// This method:
  /// - Opens the image picker
  /// - Runs YOLO detection inference on the selected image
  /// - Updates the UI with detection results and annotated image
  Future<void> _pickAndPredict() async {
    if (!_isModelReady || _yolo == null) {
      debugPrint('Model not ready yet for inference.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model is loading, please wait...')),
        );
      }
      return;
    }

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    try {
      setState(() {
        _loadingMessage = 'Running inference...';
      });

      final bytes = await file.readAsBytes();

      // Run YOLO detection with annotated image generation
      final result = await _yolo!.predict(
        bytes,
        confidenceThreshold: 0.25,
        iouThreshold: 0.45,
        generateAnnotatedImage: true, // Generate annotated image
      );

      if (mounted) {
        setState(() {
          // Extract detection results
          if (result.containsKey('boxes') && result['boxes'] is List) {
            _detections = List<Map<String, dynamic>>.from(result['boxes']);
          } else {
            _detections = [];
          }

          // Extract annotated image if available
          if (result.containsKey('annotatedImage') && result['annotatedImage'] is Uint8List) {
            _annotatedImage = result['annotatedImage'] as Uint8List;
          } else {
            _annotatedImage = null;
          }

          _imageBytes = bytes;
          _loadingMessage = 'Found ${_detections.length} detections';
        });

        debugPrint('Inference completed: ${_detections.length} detections found');
      }
    } catch (e) {
      debugPrint('Error during inference: $e');
      if (mounted) {
        setState(() {
          _loadingMessage = 'Inference error: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inference error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Single Image Detection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Model status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isModelReady ? Icons.check_circle : Icons.hourglass_empty,
                          color: _isModelReady ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Model Status',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_loadingMessage),
                    if (_isModelReady) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Model: yolo11n (Detection)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pick image button
            ElevatedButton.icon(
              onPressed: _isModelReady ? _pickAndPredict : null,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image & Run Detection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 16),

            // Results section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image display
                    if (_annotatedImage != null)
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Detection Results',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              child: Image.memory(
                                _annotatedImage!,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_imageBytes != null)
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Original Image',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              child: Image.memory(
                                _imageBytes!,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Detection details
                    if (_detections.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detections (${_detections.length})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(_detections.length, (index) {
                                final detection = _detections[index];
                                final className = detection['class'] ?? 'Unknown';
                                final confidence = (detection['confidence'] ?? 0.0) as double;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${index + 1}. $className',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '${(confidence * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: confidence > 0.7
                                              ? Colors.green
                                              : confidence > 0.5
                                                  ? Colors.orange
                                                  : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      )
                    else if (_imageBytes != null)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No objects detected in this image.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ),
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
