import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class CameraLogic {
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

  int _yuv2rgb(int y, int u, int v) {
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

        image.data!.setPixelR(w, h, _yuv2rgb(y, u, v)); //= yuv2rgb(y, u, v);
      }
    }
    return image;
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? getInputImage(
      {required CameraImage? frame,
      required CameraController controller,
      required List<CameraDescription> cameras,
      required CameraLensDirection camDirec}) {
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
        final yuvBytes = _yuv420ToNv21(frame);

        return InputImage.fromBytes(
          bytes: yuvBytes,
          metadata: InputImageMetadata(
            size: Size(frame.width.toDouble(), frame.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: frame.planes[0].bytesPerRow,
          ),
        );
      } else {
        // iOS
        if (frame.planes.length != 1) return null;
        final plane = frame.planes.first;

        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(frame.width.toDouble(), frame.height.toDouble()),
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
}
