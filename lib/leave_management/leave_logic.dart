import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/leave.dart';

class LeaveLogic {
  Future<String> createAttachmentUrlInBucket(
      {required SupabaseDbHelper dbHelper,
      required String uniqueUrl,
      required String filePath,
      required Uint8List imageBytes}) async {
    try {
      await dbHelper.insertAttachmentIntoBucket('leaves', filePath, imageBytes);
      debugPrint("Inserted in bucket successfully.");
    } catch (e) {
      debugPrint("Something went wrong in uploading image: $e");
    }

    String imageUrl =
        '${dotenv.env['SUPABASE_URL']}/storage/v1/object/public/leaves/public/$uniqueUrl';

    return imageUrl;
  }

  Future<void> createLeaveRequest(
      {required SupabaseDbHelper dbHelper,
      required DateTime startTime,
      required DateTime endTime,
      required Account account,
      required String leaveType,
      required String reason,
      required String? attachmentUrl}) async {
    try {
      Map<String, dynamic> row = {
        'account_id': account.id,
        'leave_type': leaveType,
        'start_date': startTime.toIso8601String(),
        'end_date': endTime.toIso8601String(),
        'leave_reason': reason,
        'attachment_url': attachmentUrl,
        'leave_status': 'pending',
      };
      await dbHelper.insert('leaves', row);
    } catch (e) {
      debugPrint("Failed to create leave request: $e");
    }
  }

  Future<Account?> fetchAccount(
      {required SupabaseDbHelper dbHelper, required Leave leave}) async {
    Account? account;
    try {
      final response = await dbHelper.getRowByField(
          'accounts', 'id', leave.accountId, Account.fromMap);
      account = response;
    } catch (e) {
      debugPrint("Failed to fetch account: $e");
    }
    return account;
  }

  Future<void> updateApprovalStatus(
      {required SupabaseDbHelper dbHelper,
      required Leave leave,
      required String action,
      required Account account}) async {
    Map<String, dynamic> row = {
      'leave_status': action == "approve" ? 'approved' : 'rejected',
      'approved_at': DateTime.now().toUtc().toIso8601String(),
      'approved_by': account.id
    };
    try {
      await dbHelper.updateWhere('leaves', 'id', leave.id, row);
    } catch (e) {
      debugPrint("Failed to update leave approval status: $e");
    }
  }

  Future<void> createNewOnLeaveAttendances(
      {required SupabaseDbHelper dbHelper, required Leave leave}) async {
    DateTime startDate = leave.startDate;
    DateTime endDate = leave.endDate;

    for (DateTime date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))) {
      if (date.weekday == DateTime.sunday) {
        continue; // skip Sundays
      }

      Map<String, dynamic> row = {
        'account_id': leave.accountId,
        'attendance_time': date.toIso8601String(),
        'attendance_status': 'on_leave',
        'leave_id': leave.id
      };

      try {
        await dbHelper.insert('attendance_v2', row);
      } catch (e) {
        debugPrint("Failed to create new on_leave attendance record: $e");
      }
    }
  }

  String formatTime(DateTime time) {
    String formattedTime = DateFormat('EEE, dd/MM/yyyy').format(time);
    return formattedTime;
  }

  String formatTimeDayAndYear(DateTime time) {
    String formattedTime = DateFormat('EEE, dd/MM').format(time);
    return formattedTime;
  }

  Future<List<Leave>> fetchAccountLeaveRequest(
      {required Account account, required SupabaseDbHelper dbHelper}) async {
    List<Leave> leaves = [];
    try {
      final response = await dbHelper.getRowsWhereField(
          'leaves', 'account_id', account.id, (row) => Leave.fromMap(row));
      leaves = response;
      debugPrint(leaves.toList().toString());
    } catch (e) {
      debugPrint("Failed to fetch account leave requests: $e");
    }

    return leaves;
  }

  Future<List<Leave>> fetchAllLeaveRequest(
      {required SupabaseDbHelper dbHelper}) async {
    List<Leave> leaves = [];
    try {
      final response = await dbHelper.getAllRows<Leave>(
          'leaves', (row) => Leave.fromMap(row));
      leaves = response;
    } catch (e) {
      debugPrint("Failed to fetch all leave request: $e");
    }
    return leaves;
  }

  String readableStrings(String word) {
    return word
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
