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
    try {
      await dbHelper.update(
          'accounts', request.accountId, request.requestedChanges);
      debugPrint("Success in update account");
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

  Future<void> createNewAccount(
      {required SupabaseDbHelper dbHelper,
      required Map<String, dynamic> request}) async {
    Map<String, dynamic> row = {
      "name": request['name'],
      "phone": request['phone'],
      "email": request['email'],
      "role": request['role'],
      "image_url": request['image_url']
    };
    try {
      await dbHelper.insert('accounts', row);
    } catch (e) {
      debugPrint("Failed to create new account: $e");
    }
  }

  Future<Account?> getNewAccount(
      {required SupabaseDbHelper dbHelper,
      required Map<String, dynamic> request}) async {
    Account? account;
    try {
      final response = await dbHelper.getRowByField(
          'accounts', 'email', request['email'], Account.fromMap);
      account = response;
    } catch (e) {
      debugPrint("Failed to get new account: $e");
    }
    debugPrint("Fetch the new account: ${account?.name}");
    return account;
  }

  Future<void> createNewEmbeddings(
      {required SupabaseDbHelper dbHelper,
      required Account account,
      required Map<String, dynamic> request}) async {
    Map<String, dynamic> row = {
      'account_id': account.id,
      'embedding': request['embeddings']
    };

    try {
      await dbHelper.insert('embeddings', row);
    } catch (e) {
      debugPrint("Failed to create new embeddings");
    }
  }

  Future<void> deleteImageFromBucket(
      {required SupabaseDbHelper dbHelper,
      required Map<String, dynamic> request}) async {
    List<String> deletedPaths = [];

    debugPrint(request['image_url']);

    if (request['image_url'] != null) {
      deletedPaths.add(request['image_url']);
    }
    try {
      await dbHelper.deleteFromBucket(deletedPaths);
      debugPrint("Deleted image from bucket: ${deletedPaths.toString()}");
    } catch (e) {
      debugPrint("Failed to delete image from bucket: $e");
    }
  }

  String readableString(String word) {
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  String readableStrings(String word) {
    return word
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String formatTime(DateTime time) {
    final malaysiaTime = time.add(Duration(hours: 8));
    final formatter = DateFormat('dd MMMM yyyy - hh:mm a');
    return formatter.format(malaysiaTime);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.grey; // fallback
    }
  }
}
