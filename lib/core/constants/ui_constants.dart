import 'package:flutter/material.dart';

class UIConstants {
  // Spacing constants
  static const EdgeInsets kSpacing = EdgeInsets.all(15);
  static const EdgeInsets kHorizontalSpacing = EdgeInsets.symmetric(horizontal: 15);
  static const double kButtonSpacing = 10.0;
  static const double kTopSpacing = 165.0;
  static const double kVerticalSpacing = 40.0;
  
  // Button sizes
  static const double kModelButtonWidth = 290.0;
  static const double kUploadButtonWidth = 160.0;
  static const double kCameraButtonWidth = 120.0;
  
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
  static const double kSmallFontSize = 13.0;
  static const double kDefaultIconSize = 24.0;
  static const double kSmallIconSize = 20.0;
  
  // Border radius
  static const double kContainerBorderRadius = 12.0;
  static const double kButtonBorderRadius = 5.0;
  
  // Colors
  static const Color kOverlayColor = Colors.black;
  static final Color kContainerColor = Colors.white.withOpacity(0.35);
  static const Color kButtonTextColor = Colors.white;
} 