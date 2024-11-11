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
import 'package:ict3217_image_segmentation/helper/isolate_inference.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:isolate';
import 'package:image/image.dart' as image_lib;

class ImageSegmentationHelper {
  Interpreter? _interpreter;
  late List<String> _labels;
  IsolateInference? _isolateInference;
  late List<int> _inputShape;
  late List<int> _outputShape;

  bool _isDisposed = false;
  bool _isProcessing = false;

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

  static final labelColors = [
    -16777216, -8388608, -16744448, -8355840, -16777088, -8388480,
    -16744320, -8355712, -12582912, -4194304, -12550144, -4161536,
    -12582784, -4194176, -12550016, -4161408, -16760832, -8372224,
    -16728064, -8339456, -16760704
  ];

  Future<void> _loadModel() async {
    if (_isDisposed) return;
    print("Loading model...");
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/deeplabv3_257_mv_gpu.tflite',
        options: options,
      );
      print("Model loaded successfully.");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _loadLabel() async {
    if (_isDisposed) return;
    print("Loading labels...");
    try {
      final labelString = await rootBundle.loadString('assets/deeplabv3_257_mv_gpu.txt');
      _labels = labelString.split('\n');
      print("Labels loaded: ${_labels.length} labels found.");
    } catch (e) {
      print("Error loading labels: $e");
    }
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
      final image = image_lib.decodeImage(imageBytes);
      if (image == null) {
        print("Error decoding image.");
        return null;
      }

      final resizedImage = image_lib.copyResize(image, width: _inputShape[1], height: _inputShape[2]);
      final inputImage = _imageToByteListUint8(resizedImage, _inputShape[1], _inputShape[2]);

      var output = List.generate(_outputShape[1], (_) => List.generate(_outputShape[2], (_) => List.filled(_outputShape[3], 0.0)));
      _interpreter!.run(inputImage, output);

      print("Image segmentation completed.");
      final segmentedBytes = _convertToImage(output, resizedImage.width, resizedImage.height);
      final segmentedFile = await _saveImage(segmentedBytes, image.width, image.height);
      return segmentedFile;
    } catch (e) {
      print("Error during image segmentation: $e");
      return null;
    }
  }

  Uint8List _imageToByteListUint8(image_lib.Image image, int width, int height) {
    print("Converting image to byte buffer...");
    var convertedBytes = Uint8List(1 * width * height * 3);
    var buffer = ByteData.view(convertedBytes.buffer);
    int index = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        buffer.setUint8(index++, pixel.getChannel(image_lib.Channel.red).toInt());
        buffer.setUint8(index++, pixel.getChannel(image_lib.Channel.green).toInt());
        buffer.setUint8(index++, pixel.getChannel(image_lib.Channel.blue).toInt());
      }
    }
    print("Image converted to byte buffer.");
    return convertedBytes;
  }

  Uint8List _convertToImage(List<List<List<double>>> masks, int width, int height) {
    print("Converting mask to image bytes...");
    List<int> imageMatrix = [];
    for (int i = 0; i < masks.length; i++) {
      for (int j = 0; j < masks[i].length; j++) {
        final maxScoreIndex = masks[i][j].indexWhere((v) => v == masks[i][j].reduce((a, b) => a > b ? a : b));
        final color = labelColors[maxScoreIndex];
        imageMatrix.addAll([
          (color >> 16) & 0xFF,
          (color >> 8) & 0xFF,
          color & 0xFF,
          128 // Alpha
        ]);
      }
    }
    print("Mask converted to image bytes.");
    return Uint8List.fromList(imageMatrix);
  }

  Future<File> _saveImage(Uint8List bytes, int width, int height) async {
    print("Saving segmented image...");
    final result = image_lib.Image.fromBytes(
      width: width,
      height: height,
      bytes: bytes.buffer,
    );

    final filePath = 'path_to_save_segmented_image/segmented_image.png';
    final file = File(filePath);

    await file.writeAsBytes(image_lib.encodePng(result));
    print("Segmented image saved at: $filePath");
    return file;
  }

  Future<List<List<List<double>>>?> inferenceImage(image_lib.Image image) async {
    if (_isDisposed || _interpreter == null) {
      print("Error: Interpreter not initialized or disposed.");
      return null;
    }

    try {
      // Check the input and output shapes
      print("Model input shape: $_inputShape");
      print("Model output shape: $_outputShape");

      // Resize the image to match the model's input dimensions
      final resizedImage = image_lib.copyResize(image, width: _inputShape[1], height: _inputShape[2]);
      print("Resized image dimensions: ${resizedImage.width}x${resizedImage.height}");

      // Convert the image to the appropriate input format (e.g., float or int)
      final inputImage = _inputShape[0] == 1
          ? _imageToByteListFloat32(resizedImage, _inputShape[1], _inputShape[2])
          : _imageToByteListUint8(resizedImage, _inputShape[1], _inputShape[2]);
      print("Converted image to byte buffer, input format ready.");

      // Prepare the output buffer with shape [1, 257, 257, 21]
      var output = List.generate(1, (_) => List.generate(_outputShape[1], (_) => List.generate(_outputShape[2], (_) => List.filled(_outputShape[3], 0.0))));

      // Run the interpreter with the processed input and output buffers
      print("Running inference...");
      _interpreter!.run(inputImage, output);
      print("Inference completed on static image.");

      // Remove the batch dimension to return a 3D tensor as expected
      return output[0]; // Shape: [257, 257, 21]
    } catch (e) {
      print("Error during inference on static image: $e");
      return null;
    }
  }


  String getLabelsName(int index) {
    return _labels[index];
  }

  Future<List<List<List<double>>>?> inferenceCameraFrame(CameraImage cameraImage) async {
    if (_isDisposed || _interpreter == null || _isProcessing) return null;

    _isProcessing = true; // Set processing flag to prevent re-entry
    final inferenceModel = InferenceModel(
        cameraImage, _interpreter!.address, _inputShape, _outputShape
    );

    try {
      ReceivePort responsePort = ReceivePort();
      _isolateInference?.sendPort.send(inferenceModel..responsePort = responsePort.sendPort);
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
  Uint8List _imageToByteListFloat32(image_lib.Image image, int width, int height) {
    // Create a Float32List for the image buffer
    var convertedBytes = Float32List(1 * width * height * 3);
    var buffer = Float32List.view(convertedBytes.buffer); // create a view for easy access
    int index = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);

        // Normalize each color channel to [0, 1] and assign it to the buffer
        buffer[index++] = (pixel.getChannel(image_lib.Channel.red) / 255.0);
        buffer[index++] = (pixel.getChannel(image_lib.Channel.green) / 255.0);
        buffer[index++] = (pixel.getChannel(image_lib.Channel.blue) / 255.0);
      }
    }

    return Uint8List.view(buffer.buffer); // return as Uint8List for model compatibility
  }

}
