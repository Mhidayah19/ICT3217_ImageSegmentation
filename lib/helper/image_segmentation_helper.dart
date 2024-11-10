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

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:ict3217_image_segmentation/helper/isolate_inference.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:isolate';
import '../models/segmentation_model.dart';

class ImageSegmentationHelper {
  Interpreter? _interpreter;
  late List<String> _labels;
  IsolateInference? _isolateInference;  // Make nullable to control its initialization
  late List<int> _inputShape;
  late List<int> _outputShape;

  bool _isDisposed = false;
  bool _isProcessing = false; // Flag to prevent concurrent inferences

  final SegmentationModel model;

  ImageSegmentationHelper({required this.model});

  bool isInterpreterInitialized() {
    return _interpreter != null && !_isDisposed;
  }

  void close() {
    if (_isProcessing) return; // Ensure no inference is running
    if (_interpreter != null && !_isDisposed) {
      _interpreter!.close();
      _interpreter = null;
      _isDisposed = true;
    }
    _isolateInference?.stop(); // Ensure isolate is stopped
    _isolateInference = null;
  }

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
    await _loadModel();
    await _loadLabel();

    if (_interpreter != null && !_isDisposed) {
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
    }

    _isolateInference = IsolateInference();
    await _isolateInference!.start();
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
      return results;
    } catch (e) {
      print("Error during inference: $e");
      return null;
    } finally {
      _isProcessing = false; // Reset processing flag
    }
  }

  String getLabelsName(int index) {
    return _labels[index];
  }
}
