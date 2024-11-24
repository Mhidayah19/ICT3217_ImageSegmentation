import 'package:flutter/material.dart';

class UIConstants {
  // Spacing constants
  static const EdgeInsets kSpacing = EdgeInsets.all(10);
  static const EdgeInsets kHorizontalSpacing = EdgeInsets.symmetric(horizontal: 20);
  static const double kButtonSpacing = 5.0;
  static const double kTopSpacing = 165.0;
  static const double kVerticalSpacing = 20.0;
  
  // Button sizes
  static const double kModelButtonWidth = 265.0;
  static const double kUploadButtonWidth = 150.0;
  static const double kCameraButtonWidth = 114.0;
  
  // Text styles
  static const TextStyle kTitleStyle = TextStyle(
    fontFamily: 'Jura',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 12,
    color: Colors.white,
  );
  
  // Button styles
  static const double kDefaultFontSize = 16.0;
  static const double kSmallFontSize = 12.5;
  static const double kDefaultIconSize = 22.0;
  static const double kSmallIconSize = 16.0;
  
  // Border radius
  static const double kContainerBorderRadius = 10.0;
  static const double kButtonBorderRadius = 5.0;
  
  // Colors
  static const Color kOverlayColor = Colors.black;
  static final Color kContainerColor = Colors.white.withOpacity(0.35);
  static const Color kButtonTextColor = Colors.white;
} 