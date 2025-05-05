import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../login/login_page.dart';
import '../attendance_dashboard/attendance_dashboard.dart';
import '../main.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/recognition.dart';
import '../attendance_dashboard/recognizer.dart';
import '../model/setting.dart';

class FaceRegistration extends StatefulWidget {
  final Account account;
  final List<Setting>? systemSettings;
  const FaceRegistration(
      {super.key, required this.account, this.systemSettings});

  @override
  State<FaceRegistration> createState() => _FaceRegistrationState();
}

class _FaceRegistrationState extends State<FaceRegistration> {
  late CameraController controller;
  bool isBusy = false;
  bool hasRecognizedFace = false;

  late Size size;
  late CameraDescription description = cameras[1];
  CameraLensDirection camDirec = CameraLensDirection.front;
  late List<Recognition> recognitions = [];
  late List<Face> faces = [];
  final dbHelper = SupabaseDbHelper();

  late FaceDetector detector;

  late Recognizer recognizer;

  @override
  void initState() {
    super.initState();

    detector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
    recognizer = Recognizer();

    initializeCamera();
  }

  initializeCamera() async {
    controller = CameraController(description, ResolutionPreset.max);
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          frame = image;
          doFaceDetectionOnFrame();
        }

        setState(() {});
      });
    });
  }

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

  CameraImage? frame;
  doFaceDetectionOnFrame() async {
    try {
      InputImage? inputImage = getInputImage();

      debugPrint("Input image params: "
          "Rotation: ${inputImage?.metadata?.rotation}, "
          "Format: ${inputImage?.metadata?.format}, "
          "Size: ${inputImage?.metadata?.size}");

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

    performFaceRecognition(faces);
  }

  img.Image? image;
  performFaceRecognition(List<Face> faces) async {
    if (hasRecognizedFace) return;
    recognitions.clear();

    image = convertYUV420ToImage(frame!);
    image = img.copyRotate(image!,
        angle: camDirec == CameraLensDirection.front ? 270 : 90);

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      img.Image croppedFace = img.copyCrop(image!,
          x: faceRect.left.toInt(),
          y: faceRect.top.toInt(),
          width: faceRect.width.toInt(),
          height: faceRect.height.toInt());

      Recognition recognition =
          recognizer.recognize(croppedFace, face.boundingBox);
      if (recognition.distance > 1) {
        recognition.name = "Unknown";
      }
      recognitions.add(recognition);
      hasRecognizedFace = true;

      await controller.stopImageStream();
      await Future.delayed(Duration(milliseconds: 500));
      showFaceRegistrationDialog(croppedFace, recognition);
      break;
    }

    setState(() {
      isBusy = false;
    });
  }

  void showFaceRegistrationDialog(
      img.Image croppedFace, Recognition recognition) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "Confirm Face Registration",
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
                    onPressed: () async {
                      Map<String, dynamic> row = {
                        'name': widget.account.name,
                        'phone': widget.account.phone,
                        'email': widget.account.email,
                        'role': widget.account.role,
                        'start_date':
                            widget.account.startDate.toUtc().toIso8601String(),
                        'end_date':
                            widget.account.endDate!.toUtc().toIso8601String(),
                      };
                      try {
                        await dbHelper.insert('accounts', row);
                        final newAccount =
                            await dbHelper.getRowByField<Account>(
                          'accounts',
                          'email',
                          widget.account.email,
                          (data) => Account.fromMap(data),
                        );
                        if (!mounted) return;
                        if (newAccount != null) {
                          await recognizer.registerFaceInDb(
                            recognition.embeddings,
                            newAccount,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Face Registered")),
                          );
                        }
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Go back
                        Navigator.of(context).push(widget.systemSettings != null
                            ? MaterialPageRoute(
                                builder: (context) => AttendanceDashboard(
                                      account: newAccount!,
                                      systemSettings: widget.systemSettings!,
                                    ))
                            : MaterialPageRoute(builder: (_) => LoginPage()));
                      } catch (e) {
                        debugPrint("Registration error: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Registration failed. Try again later."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
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
                      "Register",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                    width: 10.0,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.stopImageStream();
                      Navigator.of(context).pop();
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
