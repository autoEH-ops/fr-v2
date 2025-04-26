import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../attendance_dashboard/recognizer.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/recognition.dart';
import 'update_embeddings.dart';

class EmbeddingLogic {
  Future<void> pickImageFromGallery(
      {required BuildContext context,
      required FaceDetector faceDetector,
      required Recognizer recognizer,
      required SupabaseDbHelper dbHelper,
      required String name}) async {
    late Uint8List imageBytes;
    late List<Face> faces;

    try {
      XFile? pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      imageBytes = await pickedFile.readAsBytes();
      final inputImage = InputImage.fromFilePath(pickedFile.path);

      faces = await faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No face found in the selected image"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }

      await faceDetector.close();
    } catch (e) {
      debugPrint("Failed to upload and detected faces: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to process image."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );

      Navigator.pop(context);
    }

    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return;

    final Face face = faces.first;

    _performFaceRegistration(
      context: context,
      face: face,
      originalImage: originalImage,
      imageBytes: imageBytes,
      recognizer: recognizer,
      dbHelper: dbHelper,
      name: name,
    );
  }

  _performFaceRegistration(
      {required BuildContext context,
      required Face face,
      required img.Image originalImage,
      required Uint8List imageBytes,
      required Recognizer recognizer,
      required SupabaseDbHelper dbHelper,
      required String name}) async {
    final faceRect = face.boundingBox;
    final croppedFace = img.copyCrop(originalImage,
        x: faceRect.left.toInt(),
        y: faceRect.top.toInt(),
        width: faceRect.width.toInt(),
        height: faceRect.height.toInt());

    Recognition recognition =
        recognizer.recognize(croppedFace, face.boundingBox);

    Navigator.pop(context);

    _showFaceRegistrationDialogUploadedImage(
        context: context,
        croppedFace: croppedFace,
        recognition: recognition,
        dbHelper: dbHelper,
        imageBytes: imageBytes,
        name: name);
  }

  void _showFaceRegistrationDialogUploadedImage(
      {required BuildContext context,
      required img.Image croppedFace,
      required Recognition recognition,
      required SupabaseDbHelper dbHelper,
      required Uint8List imageBytes,
      required String name}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "Update Face Embedding",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
          ),
        ),
        content: SizedBox(
          height: 360,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    Uint8List.fromList(img.encodeBmp(croppedFace)),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Is this face correctly captured?",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _handleEmbeddingChange(
                        context: ctx,
                        recognition: recognition,
                        name: name,
                        dbHelper: dbHelper),
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      "Update",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                    width: 10.0,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _handleEmbeddingChange(
      {required BuildContext context,
      required Recognition recognition,
      required String name,
      required SupabaseDbHelper dbHelper}) async {
    try {
      final updatingAccount = await dbHelper.getRowByField<Account>(
        'accounts',
        'name',
        name,
        (data) => Account.fromMap(data),
      );

      String embeddingJson = jsonEncode(recognition.embeddings);
      debugPrint("This is the embedding json: $embeddingJson");
      Map<String, dynamic> row = {
        'embedding': embeddingJson,
      };
      if (updatingAccount != null) {
        try {
          await dbHelper.updateWhere(
              "embeddings", 'account_id', updatingAccount.id!, row);
        } catch (e) {
          debugPrint("Failed to update");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Embedding update succesfully"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration failed. Try again later."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showFaceRegistrationDialog(
      {required BuildContext context, required String name}) {
    final instructions = [
      "Hold the phone at a comfortable distance from your face.",
      "Ensure good lighting and remove any face coverings.",
      "Make sure all the information entered is correct.",
      "Click below when you are ready.",
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Before Face Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: instructions
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key + 1}. '),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close dialog
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => UpdateEmbeddings(name: name)));
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }
}
