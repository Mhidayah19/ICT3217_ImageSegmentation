import 'package:flutter/material.dart';

class CaptureButton extends StatelessWidget {
  final VoidCallback onCapture;
  final bool isProcessing;

  const CaptureButton({
    super.key,
    required this.onCapture,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onCapture,
      child: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: isProcessing ? Colors.grey : Colors.white.withOpacity(0.5),
        ),
        child: isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
      ),
    );
  }
}
