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
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as image_lib;
import 'package:ict3217_image_segmentation/helper/image_segmentation_helper.dart';
import '../models/segmentation_model.dart';
import '../interfaces/segmentation_screen_interface.dart';
class ImageUploadSegmentation extends StatefulWidget {
  final SegmentationModel selectedModel;
  const ImageUploadSegmentation({Key? key, required this.selectedModel}) : super(key: key);

  @override
  _ImageUploadSegmentationState createState() => _ImageUploadSegmentationState();
}

class _ImageUploadSegmentationState extends State<ImageUploadSegmentation> 
    implements SegmentationScreenInterface {
  File? _selectedImage;
  Uint8List? _segmentedImageBytes;
  late ImageSegmentationHelper _imageSegmentationHelper;
  List<int>? _labelsIndex;
  bool _isProcessing = false;

  // Interface implementations
  @override
  ImageSegmentationHelper get imageSegmentationHelper => _imageSegmentationHelper;

  @override
  bool get isProcessing => _isProcessing;

  @override
  List<int>? get labelsIndex => _labelsIndex;

  @override
  void initHelper() {
    print("Initializing segmentation helper...");
    _imageSegmentationHelper = ImageSegmentationHelper(model: widget.selectedModel);
    _imageSegmentationHelper.initHelper();
    print("Segmentation helper initialized.");
  }

  @override
  Future<void> convertToImage(
    List<List<List<double>>> masks,
    int maskWidth,
    int maskHeight,
    int originalWidth,
    int originalHeight,
  ) async {
    print("Converting segmentation mask to displayable image...");
    try {
      List<int> imageMatrix = [];
      final labelsIndexSet = <int>{};

      for (int i = 0; i < masks.length; i++) {
        for (int j = 0; j < masks[i].length; j++) {
          final maxScoreIndex = masks[i][j].indexWhere(
              (v) => v == masks[i][j].reduce((a, b) => a > b ? a : b));
          labelsIndexSet.add(maxScoreIndex);
          imageMatrix.addAll(getColorForLabel(maxScoreIndex));
        }
      }

      print("Image matrix created with ${imageMatrix.length} elements.");

      final maskImage = image_lib.Image.fromBytes(
        width: maskWidth,
        height: maskHeight,
        bytes: Uint8List.fromList(imageMatrix).buffer,
        numChannels: 4,
      );

      print("Resizing mask image to original dimensions...");
      final resizedImage = image_lib.copyResize(
        maskImage, 
        width: originalWidth, 
        height: originalHeight
      );

      final Uint8List? pngBytes = image_lib.encodePng(resizedImage);

      setState(() {
        _segmentedImageBytes = pngBytes;
        _labelsIndex = labelsIndexSet.toList();
        print("Segmented image and labels set for display as bytes.");
      });
    } catch (e) {
      print("Error in convertToImage: $e");
    }
  }

  @override
  List<int> getColorForLabel(int labelIndex) {
    if (labelIndex == 0) return [0, 0, 0, 0];
    
    final color = ImageSegmentationHelper.labelColors[labelIndex];
    final r = (color & 0x00ff0000) >> 16;
    final g = (color & 0x0000ff00) >> 8;
    final b = (color & 0x000000ff);
    
    return [r, g, b, 127];
  }

  @override
  void initState() {
    super.initState();
    initHelper();
  }

  @override
  void dispose() {
    print("Disposing segmentation helper...");
    _imageSegmentationHelper.close();
    print("Segmentation helper disposed.");
    super.dispose();
  }

  Future<void> _pickImage() async {
    print("Picking image from gallery...");
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      print("Image selected: ${pickedFile.path}");
      setState(() {
        _selectedImage = File(pickedFile.path);
        _segmentedImageBytes = null;
        _labelsIndex = null;
      });
      await _performSegmentation(_selectedImage!);
    } else {
      print("No image selected.");
    }
  }

  Future<void> _performSegmentation(File imageFile) async {
    print("Starting segmentation...");
    setState(() => _isProcessing = true);

    try {
      print("Reading image bytes...");
      final imageBytes = await imageFile.readAsBytes();
      final image = image_lib.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("Image decoding failed.");
      }
      print("Image decoded successfully.");

      print("Resizing image for model...");
      final resizedImage = image_lib.copyResize(image, width: 257, height: 257);
      print("Image resized to 257x257.");

      print("Running segmentation inference...");
      final mask = await _imageSegmentationHelper.inferenceImage(resizedImage);

      if (mask != null) {
        print("Segmentation mask generated successfully.");
        await convertToImage(
          mask, 
          resizedImage.width, 
          resizedImage.height, 
          image.width, 
          image.height
        );
      } else {
        throw Exception("Segmentation mask is null.");
      }
    } catch (e) {
      print("Error during segmentation: $e");
    } finally {
      setState(() => _isProcessing = false);
      print("Segmentation process completed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building UI...");
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Upload Segmentation"),
        backgroundColor: Colors.black,
        elevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Conditionally render the button based on _isProcessing
                if (!_isProcessing)
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload Image'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                SizedBox(height: 30),
                if (_isProcessing)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10), // Space between the loading indicator and text
                      Text("Loading...", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                if (_selectedImage != null && _segmentedImageBytes != null && !_isProcessing)
                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.file(
                            _selectedImage!,
                            width: 300,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                          Opacity(
                            opacity: 0.5,
                            child: Image.memory(
                              _segmentedImageBytes!,
                              width: 300,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text("Segmented Image", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                SizedBox(height: 20),
                if (_labelsIndex != null && !_isProcessing)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      spacing: 8.0, // Space between the labels
                      runSpacing: 4.0, // Space between lines of labels
                      children: _labelsIndex!.map((label) {
                        return Chip(
                          label: Text(
                            _imageSegmentationHelper.getLabelsName(label),
                            style: TextStyle(fontSize: 14),
                          ),
                          backgroundColor: Color(ImageSegmentationHelper.labelColors[label]).withOpacity(0.5),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}