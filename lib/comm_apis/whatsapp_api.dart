import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WhatsAppAPI {
  static String webHookUrl = "${dotenv.env['WHATSAPP_API']}";

  TimeRelatedFunction timeRelatedFunction = TimeRelatedFunction();

  Future<void> sendMessage(String msg, String phoneNumber) async {
    String template = "Your OTP : $msg\nRegards by Admin";

    String webhookURL = webHookUrl;
    Map<String, dynamic> payload = {
      "action": "send-message",
      "type": "text",
      "content": template,
      "phone": phoneNumber,
    };

    try {
      http.Response response = await http.post(
        Uri.parse(webhookURL),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint("Message sent successfully");
        debugPrint("Response body: ${response.body}");
      } else {
        debugPrint("Failed to send message: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
      }
    } catch (error) {
      debugPrint("Error sending message: $error");
    }
  }
}

class TimeRelatedFunction {
  // This is to return Round Down Time Example (9.59am = 9:00)
  String getCurrentHour() {
    DateTime currentDate = DateTime.now();
    DateTime timeNor = DateTime(
        currentDate.year, currentDate.month, currentDate.day, currentDate.hour);
    timeNor = timeNor.subtract(Duration(
        minutes: timeNor.minute,
        seconds: timeNor.second,
        milliseconds: timeNor.millisecond));
    String currentHour = DateFormat('HH:mm:ss')
        .format(timeNor.toUtc().add(const Duration(hours: 8)));
    return currentHour;
  }

  String getCurrentDate() {
    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat('MM/dd/yyyy').format(currentDate);
    return formattedDate;
  }

  String getCurrentTime() {
    DateTime currentDate = DateTime.now();
    String formattedTime = DateFormat('HH:mm:ss').format(currentDate);
    return formattedTime;
  }
}
