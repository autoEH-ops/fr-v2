import 'dart:io';
import 'package:camera/camera.dart';
import 'package:created_by_618_abdo/attendance_dashboard/attendance_dashboard.dart';
import 'package:created_by_618_abdo/attendance_marking/attendance_logic.dart';
import 'package:created_by_618_abdo/model/attendance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../main.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/recognition.dart';
import '../attendance_dashboard/recognizer.dart';

class TakeAttendance extends StatefulWidget {
  const TakeAttendance({super.key});

  @override
  State<TakeAttendance> createState() => _TakeAttendanceState();
}

class _TakeAttendanceState extends State<TakeAttendance> {
  late CameraController controller;
  bool isBusy = false;
  bool hasRecognizedFace = false;

  late Size size;
  late CameraDescription description = cameras[1];
  CameraLensDirection camDirec = CameraLensDirection.front;
  late List<Recognition> recognitions = [];
  late List<Face> faces = [];
  final dbHelper = SupabaseDbHelper();

  //TODO declare face detector
  late FaceDetector detector;

  //TODO declare face recognizer
  late Recognizer recognizer;

  @override
  void initState() {
    super.initState();

    //TODO initialize face detector
    detector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
    //TODO initialize face recognizer
    recognizer = Recognizer();

    //TODO initialize camera footage
    initializeCamera();
  }

  //TODO code to initialize the camera feed
  initializeCamera() async {
    controller = CameraController(description, ResolutionPreset.max);
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
            if (!isBusy)
              {isBusy = true, frame = image, doFaceDetectionOnFrame()}
          });
    });
  }

  //TODO close all resources
  @override
  void dispose() {
    if (controller.value.isInitialized) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }
    recognizer.close();
    super.dispose();
  }

  //TODO face detection on a frame
  CameraImage? frame;
  doFaceDetectionOnFrame() async {
    try {
      //TODO convert frame into InputImage format
      InputImage? inputImage = getInputImage();

      debugPrint("Input image params: "
          "Rotation: ${inputImage?.metadata?.rotation}, "
          "Format: ${inputImage?.metadata?.format}, "
          "Size: ${inputImage?.metadata?.size}");
      //TODO pass InputImage to face detection model and detect faces

      if (inputImage != null) {
        faces = await detector.processImage(inputImage);
      }

      for (Face face in faces) {
        debugPrint("Face location: ${face.boundingBox}");

        print("Detected ${faces.length} face(s)");
      }
      //TODO perform face recognition on detected faces
    } catch (e) {
      debugPrint("Something went wrong in doFaceDetectionOnFrame: $e");
    }

    await performFaceRecognition(faces);
  }

  img.Image? image;
  // TODO perform Face Recognition
  performFaceRecognition(List<Face> faces) async {
    if (hasRecognizedFace) return;
    recognitions.clear();

    //TODO convert CameraImage to Image and rotate it so that our frame will be in a portrait
    if (frame == null) {
      debugPrint("Frame is null, skipping face recognition.");
      return;
    }
    image = convertYUV420ToImage(frame!);
    image = img.copyRotate(image!,
        angle: camDirec == CameraLensDirection.front ? 270 : 90);

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      //TODO crop face
      img.Image croppedFace = img.copyCrop(image!,
          x: faceRect.left.toInt(),
          y: faceRect.top.toInt(),
          width: faceRect.width.toInt(),
          height: faceRect.height.toInt());

      //TODO pass cropped face to face recognition model
      Recognition recognition =
          recognizer.recognize(croppedFace, face.boundingBox);
      if (recognition.distance > 1) {
        recognition.name = "Unknown";
      }
      recognitions.add(recognition);
      if (recognition.name != "Unknown") {
        hasRecognizedFace = true;
        await controller.stopImageStream();
        await Future.delayed(Duration(milliseconds: 500));
        //TODO show face registration dialogue
        final response = await markAttendance(
            context: context,
            dbHelper: dbHelper,
            recognizedName: recognition.name);
        switch (response.result) {
          case MarkAttendanceResult.successCheckIn:
            Navigator.of(context).pop();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AttendanceDashboard(account: response.account!)));
          case MarkAttendanceResult.updatedActivity:
            Navigator.of(context).pop();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AttendanceDashboard(account: response.account!)));
          case MarkAttendanceResult.cancelled:
            Navigator.of(context).pop();
            break;
          case MarkAttendanceResult.successCheckOut:
            Navigator.of(context).pop();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AttendanceDashboard(account: response.account!)));
            break;
          case MarkAttendanceResult.error:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Cannot mark in current time. Try again later."),
                backgroundColor: Colors.orange,
              ),
            );
            break;
        }
        break;
      } else {
        continue;
      }
    }

    setState(() {
      isBusy = false;
    });
  }

  String attendanceTitleReadable(Attendance? attendance) {
    if (attendance?.attendanceStatus == "check_in" || attendance == null) {
      return "Check Out";
    } else {
      return "Check In";
    }
  }

  String attendanceContentReadable(Attendance? attendance, Account account) {
    if (attendance?.attendanceStatus == "check_in" || attendance == null) {
      return "Check Out for: ${account.name}?";
    } else {
      return "Check In for: ${account.name}?";
    }
  }

  // TODO method to convert CameraImage to Image
  img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = img.Image(width: width, height: height);

    for (var w = 0; w < width; w++) {
      for (var h = 0; h < height; h++) {
        final uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final index = h * width + w;
        final yIndex = h * yRowStride + w;

        final y = cameraImage.planes[0].bytes[yIndex];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.data!.setPixelR(w, h, yuv2rgb(y, u, v)); //= yuv2rgb(y, u, v);
      }
    }
    return image;
  }

  int yuv2rgb(int y, int u, int v) {
    // Convert yuv pixel to rgb
    var r = (y + v * 1436 / 1024 - 179).round();
    var g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    var b = (y + u * 1814 / 1024 - 227).round();

    // Clipping RGB values to be inside boundaries [ 0 , 255 ]
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    return 0xff000000 |
        ((b << 16) & 0xff0000) |
        ((g << 8) & 0xff00) |
        (r & 0xff);
  }

  // //TODO convert CameraImage to InputImage

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? getInputImage() {
    if (frame == null || !controller.value.isInitialized) return null;

    try {
      final camera =
          camDirec == CameraLensDirection.front ? cameras[1] : cameras[0];
      final sensorOrientation = camera.sensorOrientation;

      // Rotation calculation remains the same
      InputImageRotation rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
            InputImageRotation.rotation0deg;
      } else {
        final deviceOrientation = controller.value.deviceOrientation;
        var rotationCompensation = _orientations[deviceOrientation] ?? 0;
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationCompensation =
              (sensorOrientation + rotationCompensation) % 360;
        } else {
          rotationCompensation =
              (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ??
            InputImageRotation.rotation0deg;
      }

      if (Platform.isAndroid) {
        // Convert YUV_420_888 to NV21 format
        final yuvBytes = _yuv420ToNv21(frame!);

        return InputImage.fromBytes(
          bytes: yuvBytes,
          metadata: InputImageMetadata(
            size: Size(frame!.width.toDouble(), frame!.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: frame!.planes[0].bytesPerRow,
          ),
        );
      } else {
        // iOS
        if (frame!.planes.length != 1) return null;
        final plane = frame!.planes.first;

        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(frame!.width.toDouble(), frame!.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error in getInputImage: $e");
      return null;
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final nv21Size = (image.width * image.height * 1.5).toInt();
    final nv21 = Uint8List(nv21Size);

    // Fill Y plane
    nv21.setRange(0, image.width * image.height, yBuffer);

    // Interleave V/U planes
    final uvSize = image.width * image.height ~/ 2;
    int uvIndex = 0;
    for (int i = 0; i < uvSize; i += 2) {
      try {
        nv21[image.width * image.height + i] = vBuffer[uvIndex];
        nv21[image.width * image.height + i + 1] = uBuffer[uvIndex];
        uvIndex += uPlane.bytesPerRow;
      } catch (e) {
        break;
      }
    }

    return nv21;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;

    if (controller != null) {
      //TODO View for displaying the live camera footage
      stackChildren.add(
        Positioned.fill(
          child: Container(
            child: (controller.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  )
                : Container(),
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
