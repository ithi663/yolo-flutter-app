// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/presentation/screens/camera_inference_screen.dart';
import 'package:ultralytics_yolo_example/presentation/screens/single_image_screen.dart';
import 'package:ultralytics_yolo_example/presentation/screens/static_image_processor_screen.dart';

void main() {
  runApp(const YOLOExampleApp());
}

class YOLOExampleApp extends StatelessWidget {
  const YOLOExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'YOLO Plugin Example',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLO Plugin Examples'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Choose an example to explore YOLO capabilities:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Camera Inference Card
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraInferenceScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 48,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Real-time Camera Inference',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Live object detection using camera feed with YOLOView widget',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Single Image Inference Card (Original API)
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SingleImageScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.green,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Single Image Inference (Original API)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Process individual images using the original YOLO class API',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Static Image Processor Card (New API)
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaticImageProcessorScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_fix_high,
                        size: 48,
                        color: Colors.purple,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Static Image Processor (New API)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Simplified API for static image processing with YOLOImageProcessor',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            const Text(
              'Ultralytics YOLO Flutter Plugin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
