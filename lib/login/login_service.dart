import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../comm_apis/email_api.dart';
import '../comm_apis/whatsapp_api.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/otp.dart';

class LoginService {
  late List<Account> accounts;
  final dbHelper = SupabaseDbHelper();
  final supabase = Supabase.instance.client;

  // Generate a 6-digit OTP
  int generateSixDigitOTP() {
    Random random = Random();
    return 100000 +
        random.nextInt(900000); // Generates a number between 100000 and 999999
  }

  // Fetch account data and send OTP
  Future<Account?> getData(String input) async {
    Account? matchingAccount;
    try {
      accounts =
          await dbHelper.getAllRows<Account>('accounts', Account.fromMap);
      final matchingAccounts =
          accounts.where((acc) => acc.email == input || acc.phone == input);
      matchingAccount =
          matchingAccounts.isNotEmpty ? matchingAccounts.first : null;

      if (matchingAccount == null) {
        return null;
      }
      String otp = generateSixDigitOTP().toString();
      debugPrint("This is the OTP: $otp");
      sendMessage(otp, matchingAccount.phone);
      sendEmail(matchingAccount.email, otp);
      await updateOTP(matchingAccount.id!, otp);

      return matchingAccount;
    } catch (e) {
      debugPrint("Unable to get Account data: $e");
      return null;
    }
  }

  // Update the OTP in Google Sheets (column B)
  Future<void> updateOTP(int accountId, String otp) async {
    try {
      // Upsert OTP: if an entry with the accountId exists, update it; otherwise, insert it
      await supabase.from('otps').upsert({
        'account_id': accountId,
        'otp': otp,
      }, onConflict: 'account_id'); // Ensures update on conflict by account_id

      print('OTP upserted successfully for accountId $accountId');
    } catch (e) {
      print('Exception while upserting OTP: $e');
    }
  }

  // Send WhatsApp OTP
  void sendMessage(String otp, String phone) {
    WhatsAppAPI whatsAppAPI = WhatsAppAPI();
    whatsAppAPI.sendMessage(otp, phone);
  }

  // Send Email OTP
  void sendEmail(String email, String otp) {
    GmailAPI gmailAPI = GmailAPI();
    gmailAPI.sendEmail(email, otp);
  }

  // Login method
  Future<Account?> login(String otp, String input) async {
    try {
      accounts = await dbHelper.getAllRows('accounts', Account.fromMap);

      final matchingAccounts =
          accounts.where((acc) => acc.email == input || acc.phone == input);

      final Account? account =
          matchingAccounts.isNotEmpty ? matchingAccounts.first : null;

      if (account == null) {
        return null;
      }

      late Otp? otpResponse;

      try {
        otpResponse = await dbHelper.getRowByField<Otp>(
            'otps', 'account_id', account.id, (data) => Otp.fromMap(data));
      } catch (e) {
        debugPrint("Something went wrong in trying to get row from otp: $e ");
      }
      if (otpResponse == null) {
        debugPrint("OTP not found");
        return null;
      } else {
        if (otpResponse.otp == otp) {
          await updateOTP(account.id!, "");
          return account;
        } else {
          return null;
        }
      }
    } catch (e) {
      debugPrint("Login error: $e");
      return null;
    }
  }
}
