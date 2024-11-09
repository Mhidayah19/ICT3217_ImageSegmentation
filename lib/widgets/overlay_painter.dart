import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class OverlayPainter extends CustomPainter {
  late final ui.Image image;

  void updateImage(ui.Image image) {
    this.image = image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
} 