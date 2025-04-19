import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/attendance.dart';

class DashboardLogic {
  Future<Attendance?> getLatestAttendance({
    required SupabaseDbHelper dbHelper,
    required int? accountId,
  }) async {
    const table = "attendance_v2";

    try {
      return await dbHelper.getLatestRowByField<Attendance>(
        table: table,
        fieldName: 'account_id',
        fieldValue: accountId,
        orderByField: 'attendance_time',
        fromMap: (data) => Attendance.fromMap(data),
      );
    } catch (e) {
      debugPrint("Failed to get Attendance: $e");
      return null;
    }
  }

  Future<Activity?> getLatestActivity({
    required SupabaseDbHelper dbHelper,
    required int? accountId,
  }) async {
    const table = "activities";

    try {
      return await dbHelper.getLatestRowByField<Activity>(
        table: table,
        fieldName: 'account_id',
        fieldValue: accountId,
        orderByField: 'activity_time',
        fromMap: (data) => Activity.fromMap(data),
      );
    } catch (e) {
      debugPrint("Failed to get Activity: $e");
      return null;
    }
  }

  Future<Activity?> checkEarlyCheckOut(
      SupabaseDbHelper dbHelper, Account account) async {
    try {
      return await dbHelper.getActivityRowWhere(
          'activities', account, DateTime.now(), Activity.fromMap);
    } catch (e) {
      debugPrint("Something is wrong in checkEarlyCheckOut: $e");
      return null;
    }
  }

  Future<Activity?> checkIfLate(
      SupabaseDbHelper dbHelper, Account account) async {
    try {
      return await dbHelper.getRowIfLateWhere(
          'activities', account, DateTime.now(), Activity.fromMap);
    } catch (e) {
      return null;
    }
  }
}
