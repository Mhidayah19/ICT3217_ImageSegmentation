import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../helper/image_segmentation_helper.dart';
import 'package:image/image.dart' as image_lib;
import 'dart:ui' as ui;
import '../widgets/overlay_painter.dart';
import '../models/segmentation_model.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../widgets/capture_button.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/segmentation_label_list.dart';
import '../interfaces/segmentation_screen_interface.dart';
class CameraScreen extends StatefulWidget {
  final String title;
  final List<CameraDescription> cameras;
  final SegmentationModel selectedModel;

  const CameraScreen({
    super.key,
    required this.title,
    required this.cameras,
    required this.selectedModel,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver implements SegmentationScreenInterface {
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isCapturing = false;
  late CameraDescription _cameraDescription;
  late ImageSegmentationHelper _imageSegmentationHelper;
  ui.Image? _displayImage;
  List<int>? _labelsIndex;

  Future<void> _initCamera() async {
    _cameraDescription = widget.cameras.firstWhere(
        (element) => element.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(
      _cameraDescription,
      ResolutionPreset.medium,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420,
      enableAudio: false,
    );

    await _cameraController!.initialize().then((value) {
      _cameraController!.startImageStream(_imageAnalysis);
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _imageAnalysis(CameraImage cameraImage) async {
    if (_isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final masks = await _imageSegmentationHelper.inferenceCameraFrame(cameraImage);
      if (mounted && masks != null) {
        await convertToImage(
          masks,
          masks.length,
          masks.first.length,
          Platform.isIOS ? cameraImage.width : cameraImage.height,
          Platform.isIOS ? cameraImage.height : cameraImage.width,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  ImageSegmentationHelper get imageSegmentationHelper => _imageSegmentationHelper;

  @override
  bool get isProcessing => _isProcessing;

  @override
  List<int>? get labelsIndex => _labelsIndex;

  @override
  void initHelper() {
    _imageSegmentationHelper = ImageSegmentationHelper(model: widget.selectedModel);
    _imageSegmentationHelper.initHelper();
    _initCamera();
  }

  @override
  Future<void> convertToImage(
      List<List<List<double>>> masks,
      int maskWidth,
      int maskHeight,
      int originalWidth,
      int originalHeight,
      ) async {
    if (masks.isEmpty) return;

    final imageMatrix = <int>[];
    final pixelCounts = <int, int>{};
    final totalPixels = maskWidth * maskHeight;

    for (int i = 0; i < maskWidth; i++) {
      for (int j = 0; j < maskHeight; j++) {
        final score = masks[i][j];
        final maxIndex = _findMaxScoreIndex(score);

        // Increment the pixel count for the label
        pixelCounts[maxIndex] = (pixelCounts[maxIndex] ?? 0) + 1;
        imageMatrix.addAll(getColorForLabel(maxIndex));
      }
    }

    // Apply the pixel prominence threshold
    final threshold = (totalPixels * 0.050).ceil();
    final prominentLabels = pixelCounts.entries
        .where((entry) => entry.value >= threshold)
        .map((entry) => entry.key)
        .toList();

    final convertedImage = await _createImage(
      maskWidth,
      maskHeight,
      imageMatrix,
      originalWidth,
      originalHeight,
    );

    setState(() {
      _displayImage = convertedImage;
      _labelsIndex = prominentLabels;
    });
  }

  @override
  List<int> getColorForLabel(int labelIndex) {
    if (labelIndex == 0) return [0, 0, 0, 0];

    final color = ImageSegmentationHelper.labelColors[labelIndex];
    final r = (color & 0x00ff0000) >> 16;
    final g = (color & 0x0000ff00) >> 8;
    final b = (color & 0x000000ff);

    return [r, g, b, 127];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initHelper();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _imageSegmentationHelper.close();
    super.dispose();
  }

  Future<void> _convertToImage(
    List<List<List<double>>>? masks,
    int originImageWidth,
    int originImageHeight
  ) async {
    if (masks == null) return;

    final width = masks.length;
    final height = masks.first.length;
    final imageMatrix = <int>[];
    final labelsIndex = <int>{};

    for (int i = 0; i < width; i++) {
      for (int j = 0; j < height; j++) {
        final score = masks[i][j];
        final maxIndex = _findMaxScoreIndex(score);

        labelsIndex.add(maxIndex);
        imageMatrix.addAll(_getColorForLabel(maxIndex));
      }
    }

    final convertedImage = await _createImage(
      width, height, imageMatrix,
      originImageWidth, originImageHeight,
    );

    setState(() {
      _displayImage = convertedImage;
      _labelsIndex = labelsIndex.toList();
    });
  }

  int _findMaxScoreIndex(List<double> scores) {
    int maxIndex = 0;
    double maxScore = scores[0];

    for (int k = 1; k < scores.length; k++) {
      if (scores[k] > maxScore) {
        maxScore = scores[k];
        maxIndex = k;
      }
    }

    return maxIndex;
  }

  List<int> _getColorForLabel(int labelIndex) {
    if (labelIndex == 0) return [0, 0, 0, 0];

    final color = ImageSegmentationHelper.labelColors[labelIndex];
    final r = (color & 0x00ff0000) >> 16;
    final g = (color & 0x0000ff00) >> 8;
    final b = (color & 0x000000ff);

    return [r, g, b, 127];
  }

  Future<ui.Image> _createImage(
    int width, int height, List<int> imageMatrix,
    int originImageWidth, int originImageHeight,
  ) async {
    final image = image_lib.Image.fromBytes(
      width: width,
      height: height,
      bytes: Uint8List.fromList(imageMatrix).buffer,
      numChannels: 4,
    );

    final resizedImage = image_lib.copyResize(
      image,
      width: originImageWidth,
      height: originImageHeight,
    );

    final bytes = image_lib.encodePng(resizedImage);
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();

    return frameInfo.image;
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null) return const SizedBox.shrink();

    final scale = _calculateScale();

    return Stack(
      children: [
        // Camera Preview (background)
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: MediaQuery.of(context).size.height, // Full height of the screen
            width: MediaQuery.of(context).size.width,   // Full width of the screen
            child: CameraPreview(_cameraController!),
          ),
        ),
        // Segmentation mask (CustomPaint overlay)
        if (_displayImage != null)
          Transform.scale(
            scale: 0.9,
            child: CustomPaint(
              painter: OverlayPainter()..updateImage(_displayImage!),
            ),
          ),
        // Overlay: White space with labels on top of the segmentation mask
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.grey.withOpacity(0.8), // White background with opacity
            height: 60.0, // Height of the white space (adjust as needed)
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segmentation labels
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: SegmentationLabelList(
                    labelsIndex: _labelsIndex,
                    imageSegmentationHelper: _imageSegmentationHelper,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Capture button on top of all elements
        Positioned(
          bottom: 70, // Adjust to position above the white space
          left: 0,
          right: 0,
          child: Center(
            child: CaptureButton(
              onCapture: _captureAndSaveImage,
              isProcessing: _isCapturing,
            ),
          ),
        ),
      ],
    );
  }


  double _calculateScale() {
    if (_displayImage == null) return 1.0;

    final minOutputSize = _displayImage!.width > _displayImage!.height
        ? _displayImage!.height
        : _displayImage!.width;
    final minScreenSize =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height
            ? MediaQuery.of(context).size.height
            : MediaQuery.of(context).size.width;

    return minScreenSize / minOutputSize;
  }

  Future<void> _captureAndSaveImage() async {
    if (!_canCapture()) return;

    try {
      setState(() => _isCapturing = true);

      if (!await _checkStoragePermission()) return;
      await _cameraController?.setFlashMode(FlashMode.off);

      await _pauseCameraStream();
      final capturedImage = await _captureImage();
      if (capturedImage == null) return;

      final processedImage = await _processImage(capturedImage);
      if (processedImage == null) return;

      await _saveImageToGallery(processedImage);
    } catch (e) {
      _showErrorMessage('Error capturing image: $e');
    } finally {
      await _resumeCameraStream();
    }
  }

  bool _canCapture() {
    if (_cameraController == null || _displayImage == null) {
      _showErrorMessage('Camera or segmentation not ready');
      return false;
    }
    if (_isCapturing) return false;
    return true;
  }

  Future<bool> _checkStoragePermission() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      _showErrorMessage('Storage permission is required to save images');
      return false;
    }
    return true;
  }

  Future<void> _pauseCameraStream() async {
    await _cameraController!.stopImageStream();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<XFile?> _captureImage() async {
    try {
      return await _cameraController!.takePicture();
    } catch (e) {
      _showErrorMessage('Failed to capture image');
      return null;
    }
  }

  Future<Uint8List?> _processImage(XFile originalImage) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final imageData = await _prepareOriginalImage(originalImage);
      if (imageData == null) return null;

      final imageSize = Size(
        imageData.width.toDouble(),
        imageData.height.toDouble()
      );

      _drawImages(canvas, imageData, imageSize);

      return await _convertToBytes(recorder, imageSize);
    } catch (e) {
      _showErrorMessage('Failed to process image');
      return null;
    }
  }

  Future<ui.Image?> _prepareOriginalImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _drawImages(Canvas canvas, ui.Image originalImage, Size imageSize) {
    // Draw original image
    canvas.drawImage(originalImage, Offset.zero, Paint());

    // Calculate scaling factors
    final double scaleX = imageSize.width / _displayImage!.width;
    final double scaleY = imageSize.height / _displayImage!.height;

    // Draw overlay with correct scaling and positioning
    canvas.save();
    canvas.scale(scaleX, scaleY);  // Scale proportionally
    canvas.drawImage(
      _displayImage!,
      Offset.zero,
      Paint()..color = Colors.white.withOpacity(0.5)
    );
    canvas.restore();
  }

  Future<Uint8List?> _convertToBytes(ui.PictureRecorder recorder, Size imageSize) async {
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      imageSize.width.toInt(),
      imageSize.height.toInt()
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveImageToGallery(Uint8List imageBytes) async {
    final result = await ImageGallerySaver.saveImage(
      imageBytes,
      quality: 100,
      name: "segmentation_${DateTime.now().millisecondsSinceEpoch}.png"
    );

    if (result['isSuccess']) {
      _showSuccessMessage();
    } else {
      _showErrorMessage('Failed to save image');
    }
  }

  Future<void> _resumeCameraStream() async {
    _startImageStream();
    if (mounted) {
      setState(() => _isCapturing = false);
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image saved to gallery'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Add this helper method to restart the image stream
  void _startImageStream() {
    _cameraController?.startImageStream(_imageAnalysis);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Camera"),
        backgroundColor: Colors.black.withOpacity(0.5),
      ),
      body: _buildCameraPreview(),
    );
  }

}