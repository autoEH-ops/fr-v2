import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';

class RegisterGuestLogic {
  Future<void> insertRegisterAccountRequests(
      {required SupabaseDbHelper dbHelper,
      required Map<String, dynamic> row}) async {
    try {
      Map<String, dynamic> tableRow = {
        'account_id': -1,
        'request_status': 'pending',
        'requested_changes': row,
        "request_category": "register_account"
      };
      await dbHelper.insert('requests', tableRow);
    } catch (e) {
      debugPrint("Failed to insert requests: $e");
    }
  }
}
