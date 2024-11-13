import 'package:flutter/material.dart';
import '../../models/segmentation_model.dart';
import '../../core/constants/model_constants.dart';

class HomeViewModel extends ChangeNotifier {
  SegmentationModel _selectedModel = ModelConstants.availableModels[0];
  
  SegmentationModel get selectedModel => _selectedModel;
  List<SegmentationModel> get availableModels => ModelConstants.availableModels;

  void updateSelectedModel(SegmentationModel model) {
    _selectedModel = model;
    notifyListeners();
  }
} 