import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';

class ManageAccountsLogic {
  Future<List<Account>> getAllAccounts(
      {required SupabaseDbHelper dbHelper}) async {
    List<Account> accounts = [];
    try {
      final response =
          await dbHelper.getAllRows('accounts', (row) => Account.fromMap(row));
      accounts = response;
    } catch (e) {
      debugPrint("Failed to get all accounts: $e");
      return [];
    }
    return accounts;
  }

  Future<Activity?> getLatestActivity(
      {required SupabaseDbHelper dbHelper, required Account account}) async {
    Activity? activity;

    try {
      final response = await dbHelper.getRowWhereFieldForCurrentDay<Activity>(
          table: 'activities',
          fieldName: 'account_id',
          fieldValue: account.id,
          dateTimeField: 'activity_time',
          fromMap: (row) => Activity.fromMap(row));

      activity = response;
    } catch (e) {
      debugPrint("Failed to get latest activity: $e");
      return null;
    }

    return activity;
  }

  Future<Map<int, Activity>> getActivitiesMap(
      {required List<Account> accounts,
      required SupabaseDbHelper dbHelper}) async {
    final Map<int, Activity> activitiesMap = {};
    for (final account in accounts) {
      final act = await getLatestActivity(account: account, dbHelper: dbHelper);
      if (act != null) {
        activitiesMap[account.id!] = act;
      }
    }

    return activitiesMap;
  }

  Color getActivityColor(String? activity) {
    switch (activity) {
      case 'work':
        return Colors.green;
      case 'break':
        return Colors.orange;
      case 'meeting':
        return Colors.purple;
      case 'toilet':
        return Colors.blue;
      case 'prayers':
        return Colors.indigo;
      case 'early_check_out':
      case null:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatReadableActivity(String? activity) {
    if (activity == null) {
      return "Check Out";
    }
    String readableActivity = activity
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
    return readableActivity;
  }

  String formatReadableRole(String role) {
    String readableRole = role
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
    return readableRole;
  }

  Future<void> updateAccountInformation(
      {required SupabaseDbHelper dbHelper,
      required Account account,
      required Map<String, dynamic> row}) async {
    try {
      await dbHelper.updateWhere('accounts', 'id', account.id!, row);
      debugPrint("Successfully update account information");
    } catch (e) {
      debugPrint("Failed to update account information: $e");
    }
  }
}
