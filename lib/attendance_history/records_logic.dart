import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
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

  Map<String, Map<String, DateTime?>> groupAttendancesByDate(
      List<Attendance> attendances) {
    final Map<String, Map<String, DateTime?>> grouped = {};

    for (var record in attendances) {
      if (record.attendanceTime == null) continue;
      final dateKey =
          "${record.attendanceTime!.year}-${record.attendanceTime!.month.toString().padLeft(2, '0')}-${record.attendanceTime!.day.toString().padLeft(2, '0')}";

      grouped.putIfAbsent(dateKey, () => {"check_in": null, "check_out": null});

      if (record.attendanceStatus == 'check_in') {
        grouped[dateKey]!["check_in"] = record.attendanceTime;
      } else if (record.attendanceStatus == 'check_out') {
        grouped[dateKey]!["check_out"] = record.attendanceTime;
      }
    }
    return grouped;
  }

  Map<String, int> getAttendanceStatistics(
      List<Attendance> attendances, int year, int month, Account account) {
    int fine = 0;
    int late = 0;
    int absent = 0;
    int leftEarly = 0;

    Map<String, Map<String, DateTime?>> groupedAttendances =
        groupAttendancesByDate(attendances);

    final createdAt = account.createdAt!;
    final totalDaysInMonth = DateUtils.getDaysInMonth(year, month);
    final today = DateTime.now();

    for (int day = 1; day <= totalDaysInMonth; day++) {
      final date = DateTime(year, month, day);

      // Skip Sundays
      if (date.weekday == DateTime.sunday) continue; // Skip Sundays
      // Skip future dates
      if (date.isAfter(DateTime(today.year, today.month, today.day))) continue;
      // Skip days before account creation if same month and year
      // Skip days before account creation if same month and year
      if (createdAt.year == year &&
          createdAt.month == month &&
          date.isBefore(createdAt)) {
        continue;
      }

      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final dayData = groupedAttendances[dateKey];

      if (dayData == null) {
        absent++;
        continue;
      }

      final checkIn = dayData["check_in"]?.add(Duration(hours: 8));
      final checkOut = dayData["check_out"]?.add(Duration(hours: 8));

      if (checkIn == null && checkOut == null) {
        absent++;
      } else {
        if (checkIn!.hour > 9 || (checkIn.hour == 9 && checkIn.minute > 0)) {
          late++;
        } else {
          fine++;
        }

        if (checkOut != null && checkOut.hour < 18) {
          leftEarly++;
        }
      }
    }

    return {
      "Fine": fine,
      "Late": late,
      "Absent": absent,
      "Left Early": leftEarly,
    };
  }
}
