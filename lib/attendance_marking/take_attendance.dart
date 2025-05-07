import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../main.dart';
import '../db/supabase_db_helper.dart';
import '../model/recognition.dart';
import '../model/account.dart';
import '../attendance_dashboard/recognizer.dart';
import '../model/setting.dart';
import 'attendance_logic.dart';
import 'camera_logic.dart';

class TakeAttendance extends StatefulWidget {
  final Account account;
  final List<Setting> systemSettings;
  const TakeAttendance(
      {super.key, required this.systemSettings, required this.account});

  @override
  State<TakeAttendance> createState() => _TakeAttendanceState();
}

class _TakeAttendanceState extends State<TakeAttendance> {
  late CameraController controller;
  bool _isCameraInitialized = false;
  bool isBusy = false;
  bool hasRecognizedFace = false;
  bool _isWidgetDisposed = false;
  bool _isRecognizerClosed = false;

  late Size size;
  late CameraDescription description = cameras[1];
  CameraLensDirection camDirec = CameraLensDirection.front;
  late List<Recognition> recognitions = [];
  late List<Face> faces = [];
  final dbHelper = SupabaseDbHelper();
  CameraLogic cameraLogic = CameraLogic();

  late FaceDetector detector;

  late Recognizer recognizer;

  @override
  void initState() {
    super.initState();

    detector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
    recognizer = Recognizer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeCamera();
    });
  }

  initializeCamera() async {
    try {
      controller = CameraController(description, ResolutionPreset.max,
          enableAudio: false);

      await controller.initialize();

      if (!mounted || _isWidgetDisposed) return;
      setState(() {
        _isCameraInitialized = true;
      });

      controller.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          frame = image;
          doFaceDetectionOnFrame();
        }

        setState(() {});
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to initialize camera. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _isWidgetDisposed = true;
    if (_isCameraInitialized && controller.value.isInitialized) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }
    recognizer.close();
    _isRecognizerClosed = true;
    super.dispose();
  }

  CameraImage? frame;
  doFaceDetectionOnFrame() async {
    try {
      InputImage? inputImage = cameraLogic.getInputImage(
          frame: frame,
          controller: controller,
          cameras: cameras,
          camDirec: camDirec);

      if (inputImage != null) {
        faces = await detector.processImage(inputImage);
      }

      for (Face face in faces) {
        debugPrint("Face location: ${face.boundingBox}");

        debugPrint("Detected ${faces.length} face(s)");
      }
    } catch (e) {
      debugPrint("Something went wrong in doFaceDetectionOnFrame: $e");
    }

    await performFaceRecognition(faces);
  }

  img.Image? image;
  performFaceRecognition(List<Face> faces) async {
    if (hasRecognizedFace) return;
    recognitions.clear();

    if (frame == null) {
      debugPrint("Frame is null, skipping face recognition.");
      return;
    }
    image = cameraLogic.convertYUV420ToImage(frame!);
    image = img.copyRotate(image!,
        angle: camDirec == CameraLensDirection.front ? 270 : 90);

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      img.Image croppedFace = img.copyCrop(image!,
          x: faceRect.left.toInt(),
          y: faceRect.top.toInt(),
          width: faceRect.width.toInt(),
          height: faceRect.height.toInt());

      if (_isRecognizerClosed || _isWidgetDisposed) return;
      Recognition recognition =
          recognizer.recognize(croppedFace, face.boundingBox);
      if (recognition.distance > 1) {
        recognition.name = "Unknown";
      }
      recognitions.add(recognition);
      for (recognition in recognitions) {
        debugPrint("This is recognitions: ${recognition.name}");
      }
      if (recognition.name != "Unknown" &&
          recognition.name == widget.account.name) {
        debugPrint(
            "Recognition Name: ${recognition.name} and account name: ${widget.account.name}");
        hasRecognizedFace = true;
        await controller.stopImageStream();
        await Future.delayed(Duration(milliseconds: 500));
        if (!mounted || _isWidgetDisposed) return;
        final response = await markAttendance(
            context: context,
            dbHelper: dbHelper,
            recognizedName: recognition.name);
        if (!mounted || _isWidgetDisposed) return;
        handleAttendanceResult(
            context, response.result, response, widget.systemSettings);

        break;
      } else {
        continue;
      }
    }

    setState(() {
      isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;

    if (_isCameraInitialized && controller.value.isInitialized) {
      stackChildren.add(
        Positioned.fill(
            child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        )),
      );

      // Adding IconButton inside Container at the bottom
      stackChildren.add(
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                    alpha: 0.5), // Semi-transparent black background
                borderRadius: BorderRadius.circular(50), // Round corners
              ),
              child: IconButton(
                onPressed: () async {
                  if (_isCameraInitialized &&
                      controller.value.isStreamingImages) {
                    await controller.stopImageStream();
                  }
                  if (!_isRecognizerClosed) recognizer.close();

                  if (context.mounted) {
                    Navigator.pop(context); // This will pop the camera screen
                  }
                },
                icon: Icon(Icons.close,
                    color: Colors.white, size: 30), // Close icon
                padding: EdgeInsets.all(16),
                splashColor: Colors.red
                    .withValues(alpha: 0.3), // Splash color when tapped
                iconSize: 30, // Icon size
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: stackChildren,
        ),
      ),
    );
  }
}
