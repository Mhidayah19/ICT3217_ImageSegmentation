import 'package:flutter/material.dart';
import '../helper/image_segmentation_helper.dart';

class SegmentationLabel extends StatelessWidget {
  final int labelIndex;
  final ImageSegmentationHelper imageSegmentationHelper;

  const SegmentationLabel({
    super.key,
    required this.labelIndex,
    required this.imageSegmentationHelper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(ImageSegmentationHelper.labelColors[labelIndex])
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        imageSegmentationHelper.getLabelsName(labelIndex),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
} 