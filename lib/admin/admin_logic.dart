import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/attendance.dart';

class AdminLogic {
  Future<List<Attendance>> getAttendanceCurrentDay(
      {required SupabaseDbHelper dbHelper}) async {
    List<Attendance> attendances = [];
    try {
      final response =
          await dbHelper.getRowsWhereFieldForCurrentDay<Attendance>(
              table: 'attendance_v2',
              fieldName: 'attendance_status',
              fieldValue: 'check_in',
              dateTimeField: 'attendance_time',
              fromMap: (row) => Attendance.fromMap(row));
      attendances = response;
    } catch (e) {
      debugPrint("Failed to get attendance for current day");
    }
    return attendances;
  }

  Future<Account?> getAccount(
      {required SupabaseDbHelper dbHelper,
      required Attendance attendance}) async {
    Account? account;
    try {
      final response = await dbHelper.getRowByField<Account>(
          'accounts', 'id', attendance.accountId, Account.fromMap);
      account = response;
    } catch (e) {
      debugPrint("Failed to get account: $e");
    }

    return account;
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

  String readableString(String word) {
    return word
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String formatTime(DateTime time) {
    final malaysiaTime = time.add(Duration(hours: 8));
    final formatter = DateFormat('hh:mm a');
    return formatter.format(malaysiaTime);
  }

  String formatYearMonthAndDay(DateTime time) {
    return DateFormat('EEEE, dd MMMM').format(time);
  }

  String formatHourAndSecond(DateTime time) {
    return DateFormat('hh:mm a').format(time);
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
}
