import 'package:flutter/material.dart';

class UIConstants {
  // Spacing constants
  static const EdgeInsets kSpacing = EdgeInsets.all(16);
  static const EdgeInsets kHorizontalSpacing = EdgeInsets.symmetric(horizontal: 24);
  static const double kButtonSpacing = 10.0;
  static const double kTopSpacing = 120.0;
  static const double kVerticalSpacing = 24.0;
  
  // Button sizes
  // static const double kModelButtonWidth = 265.0;
  // static const double kUploadButtonWidth = 150.0;
  // static const double kCameraButtonWidth = 114.0;
  
  // Text styles
  static const TextStyle kTitleStyle = TextStyle(
    fontFamily: 'Jura',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 8,
    color: Colors.white,
  );
  
  // Button styles
  static const double kDefaultFontSize = 14.0;
  static const double kSmallFontSize = 12.0;
  static const double kDefaultIconSize = 20.0;
  static const double kSmallIconSize = 16.0;
  
  // Button text styles
  static const TextStyle kButtonTextStyle = TextStyle(
    fontSize: kDefaultFontSize,
    fontWeight: FontWeight.w500,
    color: kButtonTextColor,
  );
  
  // Border radius
  static const double kContainerBorderRadius = 8.0;
  static const double kButtonBorderRadius = 8.0;
  
  // Colors
  static const Color kOverlayColor = Colors.black;
  static final Color kContainerColor = Colors.white.withOpacity(0.35);
  static const Color kButtonTextColor = Colors.white;
  
  // Button padding
  static const EdgeInsets kButtonPadding = EdgeInsets.symmetric(
    vertical: 16,
    horizontal: 12,
  );
} 