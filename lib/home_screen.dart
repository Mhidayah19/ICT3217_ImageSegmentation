import 'dart:io';

import 'package:flutter/material.dart';
import 'main.dart'; // Import the MyHomePage for navigation
import 'image_upload_screen.dart';
import 'package:image_picker/image_picker.dart';


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // Set AppBar height to 0
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Background Image with Opacity
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_image.png',  // Replace with your image path
              fit: BoxFit.cover,  // Ensure the image covers the entire background
            ),
          ),
          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.3), // Adjust the opacity value here
          ),
          // Foreground content (buttons, text, etc.)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,  // Align items to the top
              crossAxisAlignment: CrossAxisAlignment.center,  // Center items horizontally
              children: <Widget>[
                const SizedBox(height: 165),  // Add space from the top
                const Text(
                  'SEGMENT',
                  style: TextStyle(
                      fontFamily: 'Jura',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12,
                      color: Colors.white,
                    ),
                  ),

                const SizedBox(height: 40),
                const Text(
                  '',
                  style: TextStyle(fontSize: 18, color: Colors.white),  // Set text color to contrast with the background
                ),
                const SizedBox(height: 40),

                // Rectangle box around buttons
                Container(
                  padding: const EdgeInsets.all(20),  // Padding inside the box
                  margin: const EdgeInsets.symmetric(horizontal: 20), // Margin around the box
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35), // Background color of the box with opacity
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: 270, // Set the width for the new button
                        child: ElevatedButton(
                          onPressed: () {
                            print("Selecting model");
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue, // Background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5), // Adjust the radius as needed
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,  // Align text and icon center
                            children: [
                              const Text('Select A Model'),
                              const SizedBox(width: 3),
                              Icon(Icons.model_training, size: 24),  // Replace with your desired icon or image
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Space between the new button and the row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 150, // Set the width for the new button
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ImageUploadSegmentation(), // Navigate to ImageUploadScreen
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green, // Background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5), // Adjust the radius as needed
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,  // Align text and icon center
                                children: [
                                  const Text('Image Upload',
                                      style: TextStyle(fontSize: 12.5)),
                                  const SizedBox(width: 3),
                                  Icon(Icons.image, size: 17),  // Replace with your desired icon or image
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          SizedBox(
                            width: 120, // Set the width for the new button
                            child: ElevatedButton( // Space between the buttons
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    //builder: (context) => const MyHomePage(title: 'Image Segmentation'),
                                    builder: (context) => const CameraSegmentation(title: 'Image Segmentation'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red[400], // Background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5), // Adjust the radius as needed
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,  // Align text and icon center
                                children: [
                                  const Text('Camera', style: TextStyle(fontSize: 12.5)),
                                  const SizedBox(width: 5),
                                  Icon(Icons.camera_alt, size: 17),  // Replace with your desired icon or image
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
