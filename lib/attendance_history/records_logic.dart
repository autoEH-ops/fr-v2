import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/attendance.dart';

class RecordsLogic {
  Future<List<Attendance>> getAllAttendance(
      SupabaseDbHelper dbHelper, Account account) async {
    late List<Attendance> attendances;
    try {
      final response = await dbHelper.getRowsWhereField('attendance_v2',
          'account_id', account.id, (row) => Attendance.fromMap(row));

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
}
