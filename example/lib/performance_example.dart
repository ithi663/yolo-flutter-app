// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// Example demonstrating performance optimizations for static image processing
class PerformanceExample extends StatefulWidget {
  const PerformanceExample({super.key});

  @override
  State<PerformanceExample> createState() => _PerformanceExampleState();
}

class _PerformanceExampleState extends State<PerformanceExample> {
  final YOLOImageProcessor _processor = YOLOImageProcessor();
  final ImagePicker _picker = ImagePicker();

  List<YOLOResult> _results = [];
  bool _isProcessing = false;
  String _statusMessage = '';
  int _processingTimeMs = 0;
  Uint8List? _imageBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLO Performance Example'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Performance Info Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ Performance Optimizations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Background thread processing\n'
                      '• Model caching for reuse\n'
                      '• Disabled annotated image generation\n'
                      '• Optimized memory usage',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Image Selection
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 16),

            // Processing Buttons
            if (_imageBytes != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _processImage(false),
                      icon: const Icon(Icons.speed),
                      label: const Text('Fast Processing\n(No Annotation)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _processImage(true),
                      icon: const Icon(Icons.image),
                      label: const Text('With Annotation\n(Slower)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Batch Processing Example
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _batchProcess,
                icon: const Icon(Icons.batch_prediction),
                label: const Text('Batch Process (5x)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Status and Results
            if (_isProcessing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Processing...'),
                    ],
                  ),
                ),
              ),

            if (_statusMessage.isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Time: ${_processingTimeMs}ms',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                    ],
                  ),
                ),
              ),

            // Results
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected ${_results.length} objects:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._results.take(10).map((result) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• ${result.className}: ${(result.confidence * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 14),
                            ),
                          )),
                      if (_results.length > 10)
                        Text(
                          '... and ${_results.length - 10} more',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Performance Tips
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Performance Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Use generateAnnotatedImage: false for faster processing\n'
                      '• Models are cached automatically for reuse\n'
                      '• Processing happens on background threads\n'
                      '• Smaller models (yolo11n) are faster than larger ones\n'
                      '• Lower confidence thresholds find more objects but are slower',
                      style: TextStyle(fontSize: 14),
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _results = [];
          _statusMessage = 'Image selected. Ready to process.';
          _processingTimeMs = 0;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _processImage(bool generateAnnotatedImage) async {
    if (_imageBytes == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = generateAnnotatedImage
          ? 'Processing with annotation generation...'
          : 'Processing optimized (no annotation)...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final results = await _processor.detectInImage(
        _imageBytes!,
        modelPath: 'yolo11n',
        task: YOLOTask.detect,
        confidenceThreshold: 0.25,
        iouThreshold: 0.45,
        maxDetections: 100,
        generateAnnotatedImage: generateAnnotatedImage,
      );

      stopwatch.stop();

      setState(() {
        _results = results;
        _processingTimeMs = stopwatch.elapsedMilliseconds;
        _statusMessage = generateAnnotatedImage
            ? 'Processed with annotation in ${_processingTimeMs}ms'
            : 'Optimized processing completed in ${_processingTimeMs}ms';
        _isProcessing = false;
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: $e';
        _processingTimeMs = stopwatch.elapsedMilliseconds;
      });
    }
  }

  Future<void> _batchProcess() async {
    if (_imageBytes == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Batch processing 5 images...';
    });

    final stopwatch = Stopwatch()..start();
    int totalDetections = 0;

    try {
      // Process the same image 5 times to demonstrate caching benefits
      for (int i = 0; i < 5; i++) {
        final results = await _processor.detectInImage(
          _imageBytes!,
          modelPath: 'yolo11n',
          task: YOLOTask.detect,
          confidenceThreshold: 0.25,
          iouThreshold: 0.45,
          maxDetections: 100,
          generateAnnotatedImage: false, // Optimized processing
        );
        totalDetections += results.length;

        setState(() {
          _statusMessage = 'Processed ${i + 1}/5 images...';
        });
      }

      stopwatch.stop();

      setState(() {
        _processingTimeMs = stopwatch.elapsedMilliseconds;
        _statusMessage = 'Batch processing completed!\n'
            'Total time: ${_processingTimeMs}ms\n'
            'Average per image: ${(_processingTimeMs / 5).round()}ms\n'
            'Total detections: $totalDetections';
        _isProcessing = false;
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Batch processing error: $e';
        _processingTimeMs = stopwatch.elapsedMilliseconds;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
