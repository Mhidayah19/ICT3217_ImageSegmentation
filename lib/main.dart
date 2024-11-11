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
  void _convertToImage(List<List<List<double>>>? masks, int originImageWidth,
      int originImageHeight) async {
    if (masks == null) return null;// Returns if there is no mask data

    final width = masks.length; // Width of the output mask
    final height = masks.first.length; // Height of the output mask

    List<int> imageMatrix = []; // Stores RGBA values for each pixel in the mask
    final labelsIndex = <int>{}; // Stores unique label indices for displaying label info

    for (int i = 0; i < width; i++) { // Iterates over mask rows
      final List<List<double>> row = masks[i];
      for (int j = 0; j < height; j++) { // Iterates over mask columns
        final List<double> score = row[j];
        int maxIndex = 0; // Index of the maximum score (representing the label)
        double maxScore = score[0]; // Initial max score is set to the first value
        for (int k = 1; k < score.length; k++) { // Finds the label with the maximum score
          if (score[k] > maxScore) {
            maxScore = score[k];
            maxIndex = k;
          }
        }
        labelsIndex.add(maxIndex); // Adds the label index to the set of labels

        if (maxIndex == 0) { // If label is background, add transparent pixel
          imageMatrix.addAll([0, 0, 0, 0]);
          continue;
        }

        // // Extract color for label and add to imageMatrix as RGBA values
        final color = ImageSegmentationHelper.labelColors[maxIndex];
        // convert color to r,g,b
        final r = (color & 0x00ff0000) >> 16;
        final g = (color & 0x0000ff00) >> 8;
        final b = (color & 0x000000ff);
        // alpha 50%
        imageMatrix.addAll([r, g, b, 127]);
      }
    }

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

  // Widget to display the camera preview and segmentation overlay
  Widget cameraWidget(BuildContext context) {
    // Check if the camera controller is available and initialized
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container();
    }

    // Calculate scale to fit output image to screen dimensions
    var scale = MediaQuery.of(context).size.aspectRatio *
        _cameraController!.value.aspectRatio;

    // Flip the scale if the aspect ratio is off (e.g., landscape preview on portrait device)
    if (scale < 1) scale = 1 / scale;

    return Stack(
      children: [
        // Fullscreen Camera Preview with applied scaling
        Transform.scale(
          scale: scale, // Scale the preview to fit screen dimensions
          child: Center(
            child: CameraPreview(_cameraController!), // Display the camera preview
          ),
        ),

        // Overlay the segmented image if it exists
        if (_displayImage != null)
          Transform.scale(
            scale: scale, // Apply the same scale to keep overlays aligned
            child: CustomPaint(
              painter: OverlayPainter()..updateImage(_displayImage!), // Pass segmented image to painter
              child: Container(), // Empty container as a placeholder
            ),
          ),

        // Display label descriptions at the bottom of the screen if there are any labels
        if (_labelsIndex != null)
          Align(
            alignment: Alignment.bottomCenter, // Align labels at the bottom
            child: ListView.builder(
              shrinkWrap: true, // Constrain the list to minimum size
              itemCount: _labelsIndex!.length, // Number of labels to display
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(8), // Margin around each label
                  padding: const EdgeInsets.all(8), // Padding inside each label
                  decoration: BoxDecoration(
                    color: Color(
                        ImageSegmentationHelper.labelColors[_labelsIndex![index]])
                        .withOpacity(0.5), // Set color based on label with transparency
                    borderRadius: BorderRadius.circular(8), // Rounded corners for each label
                  ),
                  child: Text(
                    _imageSegmentationHelper
                        .getLabelsName(_labelsIndex![index]),// Display label name
                    style: const TextStyle(
                      fontSize: 12, // Font size for label text
                    ),
                  ),
                );
              },
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
