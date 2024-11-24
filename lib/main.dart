/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ict3217_image_segmentation/helper/image_segmentation_helper.dart';
// import 'package:image_segmentation/helper/image_segmentation_helper.dart';
import 'package:image/image.dart' as image_lib;
import 'dart:ui' as ui;
import 'home_screen.dart';
import 'package:image_picker/image_picker.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // get available cameras
  _cameras = await availableCameras();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Segmentation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(), // Start with HomeScreen
    );
  }
}

// Stateful widget that handles camera setup and segmentation
class CameraSegmentation extends StatefulWidget {
  const CameraSegmentation({super.key, required this.title});

  final String title;

  @override
  State<CameraSegmentation> createState() => _CameraSegmentationState();
}

// State class for MyHomePage that manages the camera and segmentation processes
class _CameraSegmentationState extends State<CameraSegmentation> with WidgetsBindingObserver {
  CameraController? _cameraController; // Controller for managing camera operations
  bool _isProcessing = false; // Flag to indicate if segmentation is in progress
  late CameraDescription _cameraDescription; // Stores camera description details
  late ImageSegmentationHelper _imageSegmentationHelper; // Helper instance for handling segmentation logic
  ui.Image? _displayImage; // Stores the segmented image for display
  List<int>? _labelsIndex; // List of labels for segmented regions

// Initializes the camera by setting up the controller and starting image streaming
  Future<void> _initCamera() async {
    _cameraDescription = _cameras.firstWhere(
            (element) => element.lensDirection == CameraLensDirection.back); // Selects the back camera from the list
    _cameraController = CameraController(
        _cameraDescription, ResolutionPreset.medium, // Sets resolution preset for camera preview
        imageFormatGroup: Platform.isIOS // Sets image format based on platform
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
        enableAudio: false); // Disables audio capture
    await _cameraController!.initialize().then((value) { // Initializes the camera controller
      _cameraController!.startImageStream(_imageAnalysis); // Starts streaming images to the analysis function
      if (mounted) { // Checks if the widget is still in the widget tree
        setState(() {}); // Updates UI to reflect the initialized camera state
      }
    });
  }
// Function that performs image segmentation on each frame captured by the camera
  Future<void> _imageAnalysis(CameraImage cameraImage) async {
    if (!_imageSegmentationHelper.isInterpreterInitialized()) return; // Checks if interpreter is ready

    if (_isProcessing) return; // Skips processing if another segmentation is ongoing
    _isProcessing = true; // Sets flag to indicate processing is happening

    try {
      // Check again in case interpreter was disposed during setup
      if (!_imageSegmentationHelper.isInterpreterInitialized()) return;

      // Runs the segmentation inference and retrieves the result as a mask
      final masks = await _imageSegmentationHelper.inferenceCameraFrame(cameraImage);

      if (masks != null && mounted) { // If mask data is received and widget is still active
        _convertToImage(
          masks,
          Platform.isIOS ? cameraImage.width : cameraImage.height, // Ensures width and height are in the correct order
          Platform.isIOS ? cameraImage.height : cameraImage.width,
        );
      }
    } catch (e) {
      print("Error during image analysis: $e"); // Prints error if segmentation fails
    } finally {
      _isProcessing = false; // Resets processing flag
    }
  }

  // Helper function to initialize segmentation helper and start camera
  _initHelper() {
    _imageSegmentationHelper = ImageSegmentationHelper(); // Creates segmentation helper instance
    _imageSegmentationHelper.initHelper(); // Initializes the helper, loading model and labels
    _initCamera(); // Calls the function to initialize the camera
  }

  // Lifecycle method called when widget is first created
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { // Runs code after the first frame
      _initHelper(); // Initializes helper and camera
    });
  }

  // Lifecycle method called when widget is dispose
  @override
  void dispose() {
    _cameraController?.stopImageStream(); // Stop the camera stream explicitly
    _cameraController?.dispose(); // Releases camera controller resources
    _imageSegmentationHelper.close(); // Disposes of the segmentation helper
    super.dispose();
  }


  // Converts output mask from segmentation model into an image for display
  void _convertToImage(List<List<List<double>>>? masks, int originImageWidth, int originImageHeight) async {
    if (masks == null) return;

    final width = masks.length; // Width of the output mask
    final height = masks.first.length; // Height of the output mask

    List<int> imageMatrix = []; // Stores RGBA values for each pixel in the mask
    final labelsCount = <int, int>{}; // Map to count the number of pixels for each label

    for (int i = 0; i < width; i++) {
      final List<List<double>> row = masks[i];
      for (int j = 0; j < height; j++) {
        final List<double> score = row[j];
        int maxIndex = 0;
        double maxScore = score[0];

        for (int k = 1; k < score.length; k++) {
          if (score[k] > maxScore) {
            maxScore = score[k];
            maxIndex = k;
          }
        }

        labelsCount[maxIndex] = (labelsCount[maxIndex] ?? 0) + 1; // Increment the count for the label

        if (maxIndex == 0) {
          imageMatrix.addAll([0, 0, 0, 0]); // Transparent pixel for background
          continue;
        }

        // Extract color for label and add to imageMatrix
        final color = ImageSegmentationHelper.labelColors[maxIndex];
        final r = (color & 0x00ff0000) >> 16;
        final g = (color & 0x0000ff00) >> 8;
        final b = (color & 0x000000ff);
        imageMatrix.addAll([r, g, b, 127]); // Alpha 50%
      }
    }

    // Calculate prominence for each label
    final totalPixels = width * height;
    const double prominenceThreshold = 0.05; // Labels must occupy at least 5% of the image
    final prominentLabels = labelsCount.entries
        .where((entry) => entry.value / totalPixels >= prominenceThreshold)
        .map((entry) => entry.key)
        .toSet();

    // Filter labels for display
    final labelsIndex = prominentLabels;

    // Convert processed image data to a displayable format
    image_lib.Image convertedImage = image_lib.Image.fromBytes(
        width: width,
        height: height,
        bytes: Uint8List.fromList(imageMatrix).buffer,
        numChannels: 4);

    // Resize output image to match original camera frame dimensions
    final resizeImage = image_lib.copyResize(convertedImage,
        width: originImageWidth, height: originImageHeight);

    // Convert resized image to `ui.Image` for display
    final bytes = image_lib.encodePng(resizeImage);
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      _displayImage = frameInfo.image;
      _labelsIndex = labelsIndex.toList();
    });
  }

  Widget cameraWidget(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container();
    }

    var scale = MediaQuery.of(context).size.aspectRatio * _cameraController!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      children: [
        Transform.scale(
          scale: scale,
          child: Center(child: CameraPreview(_cameraController!)),
        ),
        if (_displayImage != null)
          Transform.scale(
            scale: scale,
            child: CustomPaint(
              painter: OverlayPainter()..updateImage(_displayImage!),
              child: Container(),
            ),
          ),
        if (_labelsIndex != null)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _labelsIndex!.map((index) {
                  final labelName = _imageSegmentationHelper.getLabelsName(index);
                  final labelColor = Color(ImageSegmentationHelper.labelColors[index]).withOpacity(0.7);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: labelColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labelName,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Intercept the back button press to stop the camera and release resources
      onWillPop: () async {
        _cameraController?.stopImageStream(); // Stop camera streaming when leaving the page
        _imageSegmentationHelper.close();  // Close the segmentation helper and release resources
        return true; // Allow the back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Center(), // Empty center widget for app bar (can add a title if needed)
          backgroundColor: Colors.black, // Set app bar background color
        ),
        body: cameraWidget(context), // Display the camera widget as the main content
      ),
    );
  }
}

// Custom painter class for overlaying segmented mask on camera preview
class OverlayPainter extends CustomPainter {
  late final ui.Image image; // Store the segmented image to overlay

  updateImage(ui.Image image) { // Update the image used for the overlay
    this.image = image; // Assign new image
  }

  // Draw the image on the canvas at the specified position
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint()); // Draw the overlay at the top-left corner
  }

  // Specify when to repaint the overlay (always repaint for real-time updates)
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint whenever the segmented image changes
  }
}
