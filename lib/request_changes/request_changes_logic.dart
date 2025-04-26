import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/requests.dart';

class RequestChangesLogic {
  getRequests({required SupabaseDbHelper dbHelper}) async {
    List<Request> requests = [];
    try {
      final response =
          await dbHelper.getAllRows('requests', (row) => Request.fromMap(row));
      requests = response;
    } catch (e) {
      debugPrint("Failed to get all requests: $e");
    }

    return requests;
  }

  Future<Account?> getRequestedAccount(
      {required SupabaseDbHelper dbHelper, required Request requested}) async {
    Account? requestAccount;
    try {
      final response = await dbHelper.getRowByField<Account>(
          'accounts', 'id', requested.accountId, Account.fromMap);
      requestAccount = response;
    } catch (e) {
      debugPrint("Failed to get account: $e");
    }

    return requestAccount;
  }

  Future<List<Request>> getAccountRequests(
      {required SupabaseDbHelper dbHelper, required Account account}) async {
    List<Request> requests = [];
    try {
      final response = await dbHelper.getRowsWhereField<Request>(
          'requests', 'account_id', account.id, (row) => Request.fromMap(row));
      requests = response;
    } catch (e) {
      debugPrint("Failed to get account: $e");
    }

    return requests;
  }

  Future<void> updateAccount({
    required SupabaseDbHelper dbHelper,
    required Request request,
  }) async {
    debugPrint("request account id: ${request.accountId}");
    try {
      await dbHelper.update(
          'accounts', request.accountId, request.requestedChanges);
    } catch (e) {
      debugPrint("Failed to update account: $e");
    }
  }

  Future<void> updateRequest(
      {required SupabaseDbHelper dbHelper,
      required Request request,
      required Account account,
      required String action}) async {
    debugPrint("request account id: ${account.id}");
    try {
      final row = {
        'request_status': action == "approve" ? 'approved' : 'rejected',
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        'reviewed_by': account.id
      };
      await dbHelper.update('requests', request.id!, row);
    } catch (e) {
      debugPrint("Failed to update requese: $e");
    }
  }

  String readableString(String word) {
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  String formatTime(DateTime time) {
    final malaysiaTime = time.add(Duration(hours: 8));
    final formatter = DateFormat('dd MMMM yyyy - hh:mm a');
    return formatter.format(malaysiaTime);
  }
}
