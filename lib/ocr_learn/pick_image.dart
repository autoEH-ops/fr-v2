import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'recognizer_screen.dart';

class PickImage extends StatefulWidget {
  const PickImage({super.key});

  @override
  State<PickImage> createState() => _PickImageState();
}

class _PickImageState extends State<PickImage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      File image = File(xFile.path);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecognizerScreen(image: image),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Image")),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload),
          label: const Text("Pick Image"),
        ),
      ),
    );
  }
}
