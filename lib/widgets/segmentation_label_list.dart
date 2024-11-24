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
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: labelsIndex!
                .map(
                  (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SegmentationLabel(
                  labelIndex: index,
                  imageSegmentationHelper: imageSegmentationHelper,
                ),
              ),
            )
                .toList(),
          ),
        ),
      ),
    );
  }
}
