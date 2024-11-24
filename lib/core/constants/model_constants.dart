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
      name: 'PSPNET',
      folderPath: 'assets/models/PSPNET',
      modelPath: 'assets/models/PSPNET/pspnet_50_10epoch_320steps_augmentation.tflite',
      labelPath: 'assets/models/PSPNET/pspnet_50_10epoch_320steps_augmentation.txt',
    ),
    SegmentationModel(
      name: 'VGG_UNet',
      folderPath: 'assets/models/VGG_UNet',
      modelPath: 'assets/models/VGG_UNet/vggunet_20epoch_256steps_augmentation.tflite',
      labelPath: 'assets/models/VGG_UNet/vggunet_20epoch_256steps_augmentation.txt',
    ),
  ];
} 