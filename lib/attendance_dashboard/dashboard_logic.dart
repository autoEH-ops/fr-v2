import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/attendance.dart';

class DashboardLogic {
  Future<List<Attendance>> fetchTodayAttendance(
      {required SupabaseDbHelper dbHelper, required Account account}) async {
    List<Attendance> attendance = [];
    try {
      final response = await dbHelper.getRowsWhereFieldForCurrentDay(
          table: 'attendance_v2',
          fieldName: 'account_id',
          fieldValue: account.id,
          dateTimeField: 'attendance_time',
          fromMap: (row) => Attendance.fromMap(row));

      attendance = response;
    } catch (e) {
      debugPrint("Failed to fetch today attendance: $e");
    }
    return attendance;
  }

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

  String readableString(String role) {
    String readableRole = role
        .split('_')
        .map((role) => role[0].toUpperCase() + role.substring(1).toLowerCase())
        .join(' ');

    return readableRole;
  }

  Color statusColor(String status) {
    switch (status) {
      case 'check_in':
        return Colors.green;
      case 'on_leave':
        return Colors.deepOrange;
      case 'absent':
      case 'check_out':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatTime(DateTime time) {
    final malaysiaTime = time.add(Duration(hours: 8));
    final formatter = DateFormat('hh:mm a');
    return formatter.format(malaysiaTime);
  }
}
