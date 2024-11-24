import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';
import '../core/constants/ui_constants.dart';
import '../core/constants/model_constants.dart';
import '../models/segmentation_model.dart';
import '../presentation/image_upload_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const HomeScreen({super.key, required this.cameras});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SegmentationModel _selectedModel = ModelConstants.availableModels[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackground(),
          _buildOverlay(),
          _buildContent(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 0,
      backgroundColor: UIConstants.kOverlayColor,
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/background_image.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: UIConstants.kOverlayColor.withOpacity(0.3),
    );
  }

  Widget _buildContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: UIConstants.kTopSpacing),
          _buildTitle(),
          const SizedBox(height: UIConstants.kVerticalSpacing),
          const SizedBox(height: UIConstants.kVerticalSpacing),
          _buildButtonContainer(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'SEGMENT',
      style: UIConstants.kTitleStyle,
    );
  }

  Widget _buildButtonContainer() {
    return Container(
      padding: UIConstants.kSpacing,
      margin: UIConstants.kHorizontalSpacing,
      decoration: _buildContainerDecoration(),
      child: Column(
        children: [
          _buildModelSelectionButton(),
          const SizedBox(height: 10),
          _buildActionButtons(),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: UIConstants.kContainerColor,
      borderRadius: BorderRadius.circular(UIConstants.kContainerBorderRadius),
    );
  }

  Widget _buildModelSelectionButton() {
    return SizedBox(
      width: UIConstants.kModelButtonWidth,
      child: _CustomButton(
        onPressed: () => _showModelPicker(context),
        label: _selectedModel.name,
        icon: Icons.model_training,
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showModelPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              _buildPickerHeader(context),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: ModelConstants.availableModels
                        .indexOf(_selectedModel),
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedModel = ModelConstants.availableModels[index];
                    });
                  },
                  children: ModelConstants.availableModels.map((model) {
                    return Center(
                      child: Text(
                        model.name,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerHeader(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const Text(
            'Select Model',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildUploadButton(),
        const SizedBox(width: UIConstants.kButtonSpacing),
        _buildCameraButton(),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: UIConstants.kUploadButtonWidth,
      child: _CustomButton(
        onPressed: () => _navigateToImageUploadScreen(context),
        label: 'Image Upload',
        icon: Icons.image,
        backgroundColor: Colors.green,
        fontSize: UIConstants.kSmallFontSize,
        iconSize: UIConstants.kSmallIconSize,
      ),
    );
  }

  void _navigateToImageUploadScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageUploadSegmentation(
          selectedModel: _selectedModel,
        ),
      ),
    );
  }

  Widget _buildCameraButton() {
    return Builder(
      builder: (context) => SizedBox(
        width: UIConstants.kCameraButtonWidth,
        child: _CustomButton(
          onPressed: () => _navigateToCameraScreen(context),
          label: 'Camera',
          icon: Icons.camera_alt,
          backgroundColor: Colors.red[400] ?? Colors.red,
          fontSize: UIConstants.kSmallFontSize,
          iconSize: UIConstants.kSmallIconSize,
        ),
      ),
    );
  }

  void _navigateToCameraScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          title: 'Image Segmentation',
          cameras: widget.cameras,
          selectedModel: _selectedModel,
        ),
      ),
    );
  }
}

class _CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final double fontSize;
  final double iconSize;

  const _CustomButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.fontSize = UIConstants.kDefaultFontSize,
    this.iconSize = UIConstants.kDefaultIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: UIConstants.kButtonTextColor,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.kButtonBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: fontSize),
          ),
          const SizedBox(width: 5),
          Icon(icon, size: iconSize),
        ],
      ),
    );
  }
}
