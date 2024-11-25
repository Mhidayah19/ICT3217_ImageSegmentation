import '../../models/segmentation_model.dart';

class ModelConstants {
  static const List<SegmentationModel> availableModels = [
    SegmentationModel(
      name: 'MobileNet_BiSeNet',
      folderPath: 'assets/models/MobileNet_BiSeNet',
      modelPath: 'assets/models/MobileNet_BiSeNet/MobileNet_BiSenet.tflite',
      labelPath: 'assets/models/MobileNet_UNet/vggunet_20epoch_256steps_augmentation.txt',
    ),
    SegmentationModel(
      name: 'MobileNet_UNet',
      folderPath: 'assets/models/MobileNet_UNet',
      modelPath: 'assets/models/MobileNet_UNet/MobileNet_UNet.tflite',
      labelPath: 'assets/models/MobileNet_UNet/vggunet_20epoch_256steps_augmentation.txt',
    ),
    // SegmentationModel(
    //   name: 'DeepLabV3',
    //   folderPath: 'assets/models/DeepLabV3',
    //   modelPath: 'assets/models/DeepLabV3/deeplabv3_257_mv_gpu.tflite',
    //   labelPath: 'assets/models/DeepLabV3/deeplabv3_257_mv_gpu.txt',
    // ),
  ];
} 