import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/attendance.dart';

class RecordsLogic {
  Future<List<Attendance>> fetchUpcomingOnLeave(
      {required SupabaseDbHelper dbHelper, required Account account}) async {
    List<Attendance> attendances = [];
    try {
      final response = await dbHelper.getRowsWhereFieldForUpcoming<Attendance>(
          table: 'attendance_v2',
          fieldName: 'account_id',
          fieldValue: account.id,
          dateTimeField: 'attendance_time',
          fromMap: (row) => Attendance.fromMap(row));
      attendances = response;
    } catch (e) {
      debugPrint("Failed to fetch upcoming on leave attendance: $e");
    }
    return attendances;
  }

  Future<List<Attendance>> getAllAttendanceCurrentMonth(
      SupabaseDbHelper dbHelper, Account account) async {
    late List<Attendance> attendances;
    try {
      final response =
          await dbHelper.getRowsWhereFieldForCurrentMonth<Attendance>(
              table: 'attendance_v2',
              fieldName: 'account_id',
              fieldValue: account.id,
              dateTimeField: 'attendance_time',
              fromMap: (row) => Attendance.fromMap(row));

      attendances = response;
    } catch (e) {
      debugPrint("Cannot fetch attendances:$e");
      return [];
    }
    return attendances;
  }

  Map<String, String> formatAttendanceTime(
      DateTime? checkIn, DateTime? checkOut) {
    // Use check-in as the reference for date formatting if available, else fallback to check-out
    final dateTime = (checkIn ?? checkOut)?.add(const Duration(hours: 8));
    if (dateTime == null) {
      return {'day': '', 'month': '', 'checkIn': '', 'checkOut': ''};
    }
    final day = DateFormat('dd').format(dateTime); // e.g., "01"
    final month = DateFormat('MMMM').format(dateTime); // e.g., "April"
    final formattedCheckIn = checkIn != null
        ? DateFormat('HH.mm').format(checkIn.add(const Duration(hours: 8)))
        : '-';
    final formattedCheckOut = checkOut != null
        ? DateFormat('HH.mm').format(checkOut.add(const Duration(hours: 8)))
        : '-';

    return {
      'day': day,
      'month': month,
      'checkIn': formattedCheckIn,
      'checkOut': formattedCheckOut,
    };
  }

  Map<String, String> formatUpcomingTime(DateTime? upcoming) {
    // Use check-in as the reference for date formatting if available, else fallback to check-out
    final dateTime = upcoming;
    if (dateTime == null) {
      return {'day': '', 'month': ''};
    }
    final day = DateFormat('dd').format(dateTime); // e.g., "01"
    final month = DateFormat('MMMM').format(dateTime); // e.g., "April"

    return {
      'day': day,
      'month': month,
    };
  }

  String formatMonthAndYear() {
    DateTime time = DateTime.now();
    final malaysiaTime = time.add(Duration(hours: 8));
    final formatter = DateFormat('MMMM yyyy');
    return formatter.format(malaysiaTime);
  }

  Map<String, Map<String, dynamic>> groupAttendancesByDate(
      List<Attendance> attendances) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (var record in attendances) {
      if (record.attendanceTime == null) continue;

      final date = record.attendanceTime!;
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      grouped.putIfAbsent(
          dateKey,
          () => {
                "check_in": null,
                "check_out": null,
                "on_leave": false,
                "absent": false,
              });

      if (record.attendanceStatus == 'check_in') {
        grouped[dateKey]!["check_in"] = record.attendanceTime;
      } else if (record.attendanceStatus == 'check_out') {
        grouped[dateKey]!["check_out"] = record.attendanceTime;
      } else if (record.attendanceStatus == 'on_leave') {
        grouped[dateKey]!["on_leave"] = true;
      } else if (record.attendanceStatus == 'absent') {
        grouped[dateKey]!["absent"] = true;
      }
    }
    return grouped;
  }

  Future<Map<String, int>> getAttendanceStatistics(
      {required SupabaseDbHelper dbHelper, required Account account}) async {
    List<Attendance> absentAttendances = [];
    List<Attendance> onLeaveAttendances = [];
    List<Activity> lateAttendances = [];
    List<Activity> leftEarlyAttendances = [];
    List<Attendance> fineAttendances = [];
    try {
      final response =
          await dbHelper.getRowsWhereFieldForCurrentMonthWithCondition(
              table: 'attendance_v2',
              fieldName: 'account_id',
              fieldValue: account.id,
              conditionField: 'attendance_status',
              conditionValue: 'absent',
              dateTimeField: 'attendance_time',
              fromMap: (row) => Attendance.fromMap(row));
      absentAttendances = response;
    } catch (e) {
      debugPrint("Failed to fetch absent records: $e");
    }

    try {
      final response =
          await dbHelper.getRowsWhereFieldForCurrentMonthWithCondition(
              table: 'attendance_v2',
              fieldName: 'account_id',
              fieldValue: account.id,
              conditionField: 'attendance_status',
              conditionValue: 'on_leave',
              dateTimeField: 'attendance_time',
              fromMap: (row) => Attendance.fromMap(row));
      onLeaveAttendances = response;
    } catch (e) {
      debugPrint("Failed to fetch absent records: $e");
    }

    try {
      final response =
          await dbHelper.getRowsWhereFieldForCurrentMonthWithCondition(
              table: 'activities',
              fieldName: 'account_id',
              fieldValue: account.id,
              conditionField: 'is_late',
              conditionValue: true,
              dateTimeField: 'activity_time',
              fromMap: (row) => Activity.fromMap(row));
      lateAttendances = response;
    } catch (e) {
      debugPrint("Failed to fetch absent records: $e");
    }

    try {
      final response =
          await dbHelper.getRowsWhereFieldForCurrentMonthWithConditionNull(
              table: 'activities',
              fieldName: 'account_id',
              fieldValue: account.id,
              conditionField: 'message',
              dateTimeField: 'activity_time',
              fromMap: (row) => Activity.fromMap(row));
      leftEarlyAttendances = response;
    } catch (e) {
      debugPrint("Failed to fetch absent records: $e");
    }

    final Set<DateTime> excludedDates = {
      ...leftEarlyAttendances.map((a) => DateTime(
          a.activityTime!.year, a.activityTime!.month, a.activityTime!.day)),
      ...lateAttendances.map((a) => DateTime(
          a.activityTime!.year, a.activityTime!.month, a.activityTime!.day)),
    };

    try {
      final response =
          await dbHelper.getRowsWhereFieldForCurrentMonthWithCondition(
              table: 'attendance_v2',
              fieldName: 'account_id',
              fieldValue: account.id,
              conditionField: 'attendance_status',
              conditionValue: 'check_in',
              dateTimeField: 'attendance_time',
              fromMap: (row) => Attendance.fromMap(row));
      fineAttendances = response;
    } catch (e) {
      debugPrint("Failed to fetch absent records: $e");
    }

    fineAttendances = fineAttendances.where((a) {
      final date = DateTime(a.attendanceTime!.year, a.attendanceTime!.month,
          a.attendanceTime!.day);
      return !excludedDates.contains(date);
    }).toList();

    return {
      'absent': absentAttendances.length,
      'on_leave': onLeaveAttendances.length,
      'late': lateAttendances.length,
      'left_early': leftEarlyAttendances.length,
      'fine': fineAttendances.length,
    };
  }
}
