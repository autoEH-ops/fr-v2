import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class RecognizerScreen extends StatefulWidget {
  final File image;
  const RecognizerScreen({super.key, required this.image});

  @override
  State<RecognizerScreen> createState() => _RecognizerScreenState();
}

class _RecognizerScreenState extends State<RecognizerScreen> {
  late TextRecognizer textRecognizer;
  String showText = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    textRecognizer = TextRecognizer();
    doTextRecognition();
  }

  doTextRecognition() async {
    InputImage inputImage = InputImage.fromFile(widget.image);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    String text = recognizedText.text;
    setState(() {
      showText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Recognizer'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(widget.image),
            Text(showText),
          ],
        ),
      ),
    );
  }
}
