import 'package:flutter/material.dart';
import '../helper/image_segmentation_helper.dart';

abstract class SegmentationScreenInterface {
  // Core initialization and cleanup
  void initHelper();
  void dispose();

  // Image conversion and processing
  Future<void> convertToImage(
    List<List<List<double>>> masks,
    int maskWidth,
    int maskHeight,
    int originalWidth,
    int originalHeight,
  );

  // Helper methods for image processing
  List<int> getColorForLabel(int labelIndex) {
    if (labelIndex == 0) return [0, 0, 0, 0];
    
    final color = ImageSegmentationHelper.labelColors[labelIndex];
    final r = (color & 0x00ff0000) >> 16;
    final g = (color & 0x0000ff00) >> 8;
    final b = (color & 0x000000ff);
    
    return [r, g, b, 127];
  }

  // State management
  void setState(VoidCallback fn);

  // Required properties
  ImageSegmentationHelper get imageSegmentationHelper;
  bool get isProcessing;
  List<int>? get labelsIndex;
} 