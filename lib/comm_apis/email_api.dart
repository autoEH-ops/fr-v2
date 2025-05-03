import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GmailAPI {
  final List<String> scopes = ['https://www.googleapis.com/auth/gmail.send'];

  // Send email using Gmail API
  Future<void> sendEmail(String receiverEmail, String code) async {
    var client = http.Client();
    debugPrint(dotenv.env['ADMINSDK_CA_CLIENT_EMAIL']);
    var credentials = ServiceAccountCredentials.fromJson({
      "type": "${dotenv.env['ADMINSDK_CA_TYPE']}",
      "project_id": "${dotenv.env['ADMINSDK_CA_PROJECT_ID']}",
      "private_key_id": "${dotenv.env['ADMINSDK_CA_PRIVATE_KEY_ID']}",
      "private_key":
          dotenv.env['ADMINSDK_CA_PRIVATE_KEY']!.replaceAll(r'\n', '\n'),
      "client_email": dotenv.env['ADMINSDK_CA_CLIENT_EMAIL'],
      "client_id": dotenv.env['ADMINSDK_CA_CLIENT_ID'],
      "auth_uri": dotenv.env['ADMINSDK_CA_AUTH_URI'],
      "token_uri": dotenv.env['ADMINSDK_CA_TOKEN_URI'],
      "auth_provider_x509_cert_url":
          dotenv.env['ADMINSDK_CA_AUTH_PROVIDER_X509_CERT_URL'],
      "client_x509_cert_url": dotenv.env['ADMINSDK_CA_CLIENT_X509_CERT_URL'],
      "universe_domain": dotenv.env['ADMINSDK_CA_UNIVERSE_DOMAIN']
    }, impersonatedUser: "eh14@kawalanseripadang.com");

    var authClient =
        await clientViaServiceAccount(credentials, scopes, baseClient: client);

    var gmailApi = GmailApi(authClient);
    var from = 'eh14@kawalanseripadang.com'; // The service account email
    var subject = 'Your Code';
    var body = 'Here is your code for the Attendance System: $code';

    var messageBody = '''
Content-Type: text/plain; charset="UTF-8"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
to: $receiverEmail
from: $from
subject: $subject

$body
''';

    var message = Message()..raw = base64Url.encode(utf8.encode(messageBody));

    try {
      var sentMessage = await gmailApi.users.messages.send(message, 'me');
      print('Message sent: ${sentMessage.id}');
    } catch (error) {
      print('An error occurred: $error');
    } finally {
      client.close();
    }
  }
}
