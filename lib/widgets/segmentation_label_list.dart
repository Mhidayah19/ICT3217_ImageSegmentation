import 'package:flutter/material.dart';
import '../helper/image_segmentation_helper.dart';
import './segmentation_label.dart';

class SegmentationLabelList extends StatelessWidget {
  final List<int>? labelsIndex;
  final ImageSegmentationHelper imageSegmentationHelper;

  const SegmentationLabelList({
    super.key,
    required this.labelsIndex,
    required this.imageSegmentationHelper,
  });

  @override
  Widget build(BuildContext context) {
    if (labelsIndex == null) return const SizedBox.shrink();
    
    return Align(
      alignment: Alignment.bottomCenter,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: labelsIndex!.length,
        itemBuilder: (context, index) {
          return SegmentationLabel(
            labelIndex: labelsIndex![index],
            imageSegmentationHelper: imageSegmentationHelper,
          );
        },
      ),
    );
  }
} 