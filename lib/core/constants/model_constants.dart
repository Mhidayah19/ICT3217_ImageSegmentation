import '../../models/segmentation_model.dart';

class ModelConstants {
  static const List<SegmentationModel> availableModels = [
    SegmentationModel(
      name: 'MobileNet_BiSeNet',
      folderPath: 'assets/models/MobileNet_BiSeNet',
      modelPath: 'assets/models/MobileNet_BiSeNet/MobileNet_BiSeNet.tflite',
      labelPath: 'assets/models/MobileNet_BiSeNet/labels.txt',
    ),
    SegmentationModel(
      name: 'MobileNet_UNet',
      folderPath: 'assets/models/MobileNet_UNet',
      modelPath: 'assets/models/MobileNet_UNet/MobileNet_UNet.tflite',
      labelPath: 'assets/models/MobileNet_UNet/labels.txt',
    ),
  ];
} 