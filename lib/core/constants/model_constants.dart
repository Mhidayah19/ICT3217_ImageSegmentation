import '../../models/segmentation_model.dart';

class ModelConstants {
  static const List<SegmentationModel> availableModels = [
    SegmentationModel(
      name: 'DeepLabV3',
      folderPath: 'assets/models/DeepLabV3',
      modelPath: 'assets/models/DeepLabV3/deeplabv3_257_mv_gpu.tflite',
      labelPath: 'assets/models/DeepLabV3/deeplabv3_257_mv_gpu.txt',
    ),
    SegmentationModel(
      name: 'AloyBisnet',
      folderPath: 'assets/models/AloyBisnet',
      modelPath: 'assets/models/AloyBisnet/aloy_bisenet_model.tflite',
      labelPath: 'assets/models/AloyBisnet/labels.txt',
    ),
    SegmentationModel(
      name: 'Semantic',
      folderPath: 'assets/models/Semantic',
      modelPath: 'assets/models/Semantic/semantic_model.tflite',
      labelPath: 'assets/models/Semantic/semantic_model.txt',
    ),
  ];
} 