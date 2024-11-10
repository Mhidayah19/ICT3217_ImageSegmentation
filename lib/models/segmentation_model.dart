class SegmentationModel {
  final String name;
  final String folderPath;
  final String modelPath;
  final String labelPath;

  const SegmentationModel({
    required this.name,
    required this.folderPath,
    required this.modelPath,
    required this.labelPath,
  });
} 