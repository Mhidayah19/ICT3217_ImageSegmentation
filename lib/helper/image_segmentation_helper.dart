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
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:isolate';
import 'package:image/image.dart' as image_lib;
import '../models/segmentation_model.dart';
import '../helper/isolate_inference.dart';

class ImageSegmentationHelper {
  Interpreter? _interpreter;
  late List<String> _labels;
  IsolateInference? _isolateInference;
  late List<int> _inputShape;
  late List<int> _outputShape;

  bool _isDisposed = false;
  bool _isProcessing = false;

  final SegmentationModel model;

  ImageSegmentationHelper({required this.model});

  bool isInterpreterInitialized() {
    return _interpreter != null && !_isDisposed;
  }

  void close() {
    if (_isProcessing) return;
    if (_interpreter != null && !_isDisposed) {
      print("Closing interpreter...");
      _interpreter!.close();
      _interpreter = null;
      _isDisposed = true;
      print("Interpreter closed.");
    }
    _isolateInference?.stop();
    _isolateInference = null;
  }

  // Label colors for segmentation masks
  static final labelColors = [
    -16777216, -8388608, -16744448, -8355840, -16777088, -8388480,
    -16744320, -8355712, -12582912, -4194304, -12550144, -4161536,
    -12582784, -4194176, -12550016, -4161408, -16760832, -8372224,
    -16728064, -8339456, -16760704
  ];

  Future<void> _loadModel() async {
    if (_isDisposed) return; // Prevent loading if disposed
    final options = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(
      model.modelPath,
      options: options,
    );
  }

  Future<void> _loadLabel() async {
    if (_isDisposed) return; // Prevent loading if disposed
    final labelString = await rootBundle.loadString(model.labelPath);
    _labels = labelString.split('\n');
  }

  Future<void> initHelper() async {
    print("Initializing helper...");
    await _loadModel();
    await _loadLabel();

    if (_interpreter != null && !_isDisposed) {
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      print("Model input shape: $_inputShape");
      print("Model output shape: $_outputShape");
    }

    _isolateInference = IsolateInference();
    await _isolateInference!.start();
    print("Helper initialized.");
  }

  Future<File?> segmentImage(File imageFile) async {
    if (_interpreter == null || _isDisposed) {
      print("Error: Interpreter is not initialized.");
      return null;
    }

    print("Segmenting image: ${imageFile.path}");
    try {
      final imageBytes = await imageFile.readAsBytes();
      var image = image_lib.decodeImage(imageBytes);
      if (image == null) {
        print("Error decoding image.");
        return null;
      }

      // Correct image orientation if needed
      image = image_lib.bakeOrientation(image);

      // Resize image to model's input dimensions
      final resizedImage = image_lib.copyResize(
        image,
        width: _inputShape[1],
        height: _inputShape[2],
      );

      // Prepare the input tensor with mean subtraction
      final inputImage = _imageToByteListFloat32WithMeanSubtraction(
          resizedImage, _inputShape[1], _inputShape[2]);

      // Prepare the output buffer
      var output = List.generate(
        1,
            (_) => List.generate(
          _outputShape[1],
              (_) => List.generate(
            _outputShape[2],
                (_) => List.filled(_outputShape[3], 0.0),
          ),
        ),
      );

      // Run inference
      _interpreter!.run(inputImage, output);

      print("Image segmentation completed.");

      // Remove the batch dimension from the output
      final outputData = output[0];

      // Convert model output to an image
      final segmentedBytes = _convertToImage(
        outputData,
        resizedImage.width,
        resizedImage.height,
      );

      // Save the segmented image
      final segmentedFile = await _saveImage(
        segmentedBytes,
        image.width,
        image.height,
      );
      return segmentedFile;
    } catch (e) {
      print("Error during image segmentation: $e");
      return null;
    }
  }

  /// Converts the image to a Float32List with mean subtraction applied.
  Uint8List _imageToByteListFloat32WithMeanSubtraction(
      image_lib.Image image, int width, int height) {
    // Create a Float32List for the image buffer
    var convertedBytes = Float32List(1 * width * height * 3);
    int bufferIndex = 0;

    // Mean values used for mean subtraction
    const meanValues = [103.939, 116.779, 123.68];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);

        // Subtract mean values for each channel
        convertedBytes[bufferIndex++] =
            pixel.getChannel(image_lib.Channel.red).toDouble() - meanValues[0];
        convertedBytes[bufferIndex++] =
            pixel.getChannel(image_lib.Channel.green).toDouble() - meanValues[1];
        convertedBytes[bufferIndex++] =
            pixel.getChannel(image_lib.Channel.blue).toDouble() - meanValues[2];
      }
    }
    return Uint8List.view(convertedBytes.buffer); // Return as Uint8List
  }

  /// Converts the model output masks into an image.
  Uint8List _convertToImage(
      List<List<List<double>>> masks, int width, int height) {
    print("Converting mask to image bytes...");
    List<int> imageMatrix = [];
    for (int i = 0; i < masks.length; i++) {
      for (int j = 0; j < masks[i].length; j++) {
        final maxScoreIndex = masks[i][j].indexWhere(
                (v) => v == masks[i][j].reduce((a, b) => a > b ? a : b));
        final color = labelColors[maxScoreIndex];
        imageMatrix.addAll([
          (color >> 16) & 0xFF,
          (color >> 8) & 0xFF,
          color & 0xFF,
          128 // Alpha value
        ]);
      }
    }
    print("Mask converted to image bytes.");
    return Uint8List.fromList(imageMatrix);
  }

  /// Saves the segmented image to a file.
  Future<File> _saveImage(Uint8List bytes, int width, int height) async {
    print("Saving segmented image...");
    final result = image_lib.Image.fromBytes(
      width: width,
      height: height,
      bytes: bytes.buffer,
      numChannels: 4,
    );

    // Provide a valid path to save the segmented image
    final filePath = 'path_to_save_segmented_image/segmented_image.png';
    final file = File(filePath);

    await file.writeAsBytes(image_lib.encodePng(result));
    print("Segmented image saved at: $filePath");
    return file;
  }

  /// Performs inference on a static image and returns the segmentation masks.
  Future<List<List<List<double>>>?> inferenceImage(
      image_lib.Image image) async {
    if (_isDisposed || _interpreter == null) {
      print("Error: Interpreter not initialized or disposed.");
      return null;
    }

    try {
      // Resize the image to match the model's input dimensions
      final resizedImage = image_lib.copyResize(
        image,
        width: _inputShape[1],
        height: _inputShape[2],
      );
      print(
          "Resized image dimensions: ${resizedImage.width}x${resizedImage.height}");

      // Prepare the input tensor with mean subtraction
      final inputImage = _imageToByteListFloat32WithMeanSubtraction(
          resizedImage, _inputShape[1], _inputShape[2]);
      print("Converted image to byte buffer, input format ready.");

      // Prepare the output buffer
      var output = List.generate(
        1,
            (_) => List.generate(
          _outputShape[1],
              (_) => List.generate(
            _outputShape[2],
                (_) => List.filled(_outputShape[3], 0.0),
          ),
        ),
      );

      // Run inference
      print("Running inference...");
      _interpreter!.run(inputImage, output);
      print("Inference completed on static image.");

      // Remove the batch dimension to return a 3D tensor as expected
      return output[0]; // Shape: [height, width, numClasses]
    } catch (e) {
      print("Error during inference on static image: $e");
      return null;
    }
  }

  /// Retrieves the label name for a given index.
  String getLabelsName(int index) {
    return _labels[index];
  }

  /// Performs inference on a camera frame using an isolate.
  Future<List<List<List<double>>>?> inferenceCameraFrame(
      CameraImage cameraImage) async {
    if (_isDisposed || _interpreter == null || _isProcessing) return null;

    _isProcessing = true; // Set processing flag to prevent re-entry
    final inferenceModel = InferenceModel(
      cameraImage,
      _interpreter!.address,
      _inputShape,
      _outputShape,
    );

    try {
      ReceivePort responsePort = ReceivePort();
      _isolateInference?.sendPort.send(
          inferenceModel..responsePort = responsePort.sendPort);
      final results = await responsePort.first;
      print("Camera frame inference completed.");
      return results;
    } catch (e) {
      print("Error during inference: $e");
      return null;
    } finally {
      _isProcessing = false; // Reset processing flag
    }
  }

  // Existing method kept for reference, ensure it's not used without mean subtraction
  Uint8List _imageToByteListFloat32(
      image_lib.Image image, int width, int height) {
    // Create a Float32List for the image buffer
    var convertedBytes = Float32List(1 * width * height * 3);
    int bufferIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);

        // Normalize each color channel to [0, 1]
        convertedBytes[bufferIndex++] =
        (pixel.getChannel(image_lib.Channel.red) / 255.0);
        convertedBytes[bufferIndex++] =
        (pixel.getChannel(image_lib.Channel.green) / 255.0);
        convertedBytes[bufferIndex++] =
        (pixel.getChannel(image_lib.Channel.blue) / 255.0);
      }
    }

    return Uint8List.view(convertedBytes.buffer); // Return as Uint8List
  }
}
