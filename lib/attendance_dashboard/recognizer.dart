import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/embedding.dart';
import '../model/pair.dart';
import '../model/recognition.dart';

class Recognizer {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;
  static const int WIDTH = 112;
  static const int HEIGHT = 112;

  final dbHelper = SupabaseDbHelper();
  List<Embedding> embeddings = [];

  Map<String, Recognition> registered = {};

  @override
  String get modelName => 'assets/mobile_face_net.tflite';

  Recognizer({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }
    loadModel();
    initDb();
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(modelName);
    } catch (e) {
      throw "Unable to create interpreter, Caught Exception: $e";
    }
  }

  Future<void> initDb() async {
    loadRegisteredFaces();
  }

  void loadRegisteredFaces() async {
    registered.clear();
    late List<Embedding> allRows;
    try {
      allRows =
          await dbHelper.getAllRows<Embedding>('embeddings', Embedding.fromMap);
    } catch (e) {
      debugPrint(
          "Something went wrong in trying to get all rows from embeddings: $e");
    }

    for (final row in allRows) {
      late Account? account;

      try {
        account = await dbHelper.getRowByField<Account>(
            'accounts', 'id', row.accountId, (data) => Account.fromMap(data));
      } catch (e) {
        debugPrint(
            "Something went wrong in trying to get row from account: $e");
      }

      if (account != null) {
        String name = account.name;
        List<dynamic> jsonList = jsonDecode(row.embedding);
        List<double> embd = jsonList.map((e) => e as double).toList();
        Recognition recognition = Recognition(name, Rect.zero, embd, 0);
        registered.putIfAbsent(name, () => recognition);
        debugPrint("R= $name");
      } else {
        debugPrint("get here and its null");
      }
    }
  }

  Future<void> registerFaceInDb(List<double> embedding, Account account) async {
    String embeddingJson = jsonEncode(embedding);
    Map<String, dynamic> row = {
      "account_id": account.id,
      "embedding": embeddingJson,
    };

    try {
      await dbHelper.insert('embeddings', row);
      debugPrint("Succesfully insert the embedding data");
    } catch (e) {
      debugPrint("Something went wrong when insert embedding: $e");
    }

    loadRegisteredFaces();
  }

  List<dynamic> imageToArray(img.Image inputImage) {
    img.Image resizedImage =
        img.copyResize(inputImage, width: WIDTH, height: HEIGHT);
    List<double> flattenedList = resizedImage.data!
        .expand((channel) => [channel.r, channel.g, channel.b])
        .map((value) => value.toDouble())
        .toList();
    Float32List float32Array = Float32List.fromList(flattenedList);
    int channels = 3;
    int height = HEIGHT;
    int width = WIDTH;
    Float32List reshapedArray = Float32List(1 * height * width * channels);
    for (int c = 0; c < channels; c++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          int index = c * height * width + h * width + w;
          reshapedArray[index] =
              (float32Array[c * height * width + h * width + w] - 127.5) /
                  127.5;
        }
      }
    }
    return reshapedArray.reshape([1, 112, 112, 3]);
  }

  findNearest(List<double> emb) {
    Pair pair = Pair("Unknown", -5);
    for (MapEntry<String, Recognition> item in registered.entries) {
      final String name = item.key;
      List<double> knownEmb = item.value.embeddings;
      double distance = 0;
      for (int i = 0; i < emb.length; i++) {
        double diff = emb[i] - knownEmb[i];
        distance += diff * diff;
      }
      distance = sqrt(distance);
      if (pair.distance == -5 || distance < pair.distance) {
        pair.distance = distance;
        pair.name = name;
      }
    }
    return pair;
  }

  Recognition recognize(img.Image image, Rect location) {
    var input = imageToArray(image);

    List output = List.filled(1 * 192, 0).reshape([1, 192]);

    interpreter.run(input, output);

    List<double> outputArray = output.first.cast<double>();

    Pair pair = findNearest(outputArray);
    debugPrint("pair name: ${pair.name}");
    return Recognition(pair.name, location, outputArray, pair.distance);
  }

  void close() {
    interpreter.close();
  }
}
