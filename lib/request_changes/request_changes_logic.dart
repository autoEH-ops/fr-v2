import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/account_edit_request.dart';

class RequestChangesLogic {
  getRequests({required SupabaseDbHelper dbHelper}) async {
    List<AccountEditRequest> requests = [];
    try {
      final response = await dbHelper.getAllRows(
          'account_edit_requests', (row) => AccountEditRequest.fromMap(row));
      requests = response;
    } catch (e) {
      debugPrint("Failed to get all requests: $e");
    }

    return requests;
  }

  Future<Account?> getRequestedAccount(
      {required SupabaseDbHelper dbHelper,
      required AccountEditRequest requested}) async {
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
}
