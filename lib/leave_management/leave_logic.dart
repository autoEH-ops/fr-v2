import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/leave.dart';
import '../model/metric.dart';

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

  Future<void> createLeaveRequestAndApproved(
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
        'leave_status': 'approved',
        'approved_at': DateTime.now().toUtc().toIso8601String(),
      };
      await dbHelper.insert('leaves', row);
    } catch (e) {
      debugPrint("Failed to create leave request: $e");
    }

    Leave? leave;
    try {
      final response = await dbHelper.getRowByField(
          'leaves', 'attachment_url', attachmentUrl, Leave.fromMap);
      leave = response;
    } catch (e) {
      debugPrint("Failed to  fetch leave: $e");
    }

    Account? userAccount;
    try {
      final response = await fetchAccount(dbHelper: dbHelper, leave: leave!);
      userAccount = response;
    } catch (e) {
      debugPrint("Failed to fetch user account: $e");
    }

    if (leave != null && userAccount != null) {
      createNewOnLeaveAttendances(
          dbHelper: dbHelper, leave: leave, userAccount: userAccount);
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

  Future<void> updateAnnualLeaveDays(
      {required SupabaseDbHelper dbHelper,
      required int accountId,
      required Leave leave}) async {
    // Update Annual Leave days
    int annualLeave =
        await fetchAccountAnnualLeave(dbHelper: dbHelper, accountId: accountId);

    DateTime startDate = leave.startDate;
    DateTime endDate = leave.endDate;
    final requestedDays = daysExcludingSundays(startDate, endDate);

    int updatedAnnualLeaveAmount = annualLeave - requestedDays;
    Map<String, dynamic> row = {
      'annual_leave_entitlement': updatedAnnualLeaveAmount,
    };

    try {
      await dbHelper.updateWhere(
          'employee_metrics', 'account_id', accountId, row);
    } catch (e) {
      debugPrint("Failed to update annual leave days: $e");
    }
  }

  Future<void> createNewOnLeaveAttendances(
      {required SupabaseDbHelper dbHelper,
      required Leave leave,
      required Account userAccount}) async {
    DateTime startDate = leave.startDate;
    DateTime endDate = leave.endDate;
    int countedLeaveDays = 0;

    for (DateTime date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))) {
      if (date.weekday == DateTime.sunday) {
        continue; // Skip Sundays
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      try {
        // Check if there's already an attendance record for that date
        final existingRecords = await dbHelper.supabase
            .from('attendance_v2')
            .select()
            .eq('account_id', leave.accountId)
            .gte('attendance_time', startOfDay.toIso8601String())
            .lt('attendance_time', endOfDay.toIso8601String());

        bool alreadyOnLeave = existingRecords.any(
          (record) => record['attendance_status'] == 'on_leave',
        );

        if (alreadyOnLeave) {
          continue; // Skip if already marked as on_leave
        }

        bool updatedFromAbsent = false;

        // Update existing "absent" records to "on_leave"
        for (final record in existingRecords) {
          if (record['attendance_status'] == 'absent') {
            await dbHelper.updateWhere('attendance_v2', 'id', record['id'], {
              'attendance_status': 'on_leave',
              'leave_id': leave.id,
            });
            updatedFromAbsent = true;
          }
        }

        // Insert new record if none existed
        if (existingRecords.isEmpty) {
          Map<String, dynamic> row = {
            'account_id': leave.accountId,
            'attendance_time': startOfDay.toIso8601String(),
            'attendance_status': 'on_leave',
            'leave_id': leave.id,
          };

          await dbHelper.insert('attendance_v2', row);

          countedLeaveDays++;
        } else if (!updatedFromAbsent) {
          countedLeaveDays++;
        }
      } catch (e) {
        debugPrint("Error processing date $date: $e");
      }
    }
    if (countedLeaveDays > 0 && userAccount.role == 'intern') {
      final newEndDate =
          userAccount.endDate!.add(Duration(days: countedLeaveDays));
      try {
        Map<String, dynamic> updatedRow = {
          'end_date': newEndDate.toUtc().toIso8601String(),
        };
        await dbHelper.updateWhere(
            'accounts', 'id', userAccount.id, updatedRow);
      } catch (e) {
        debugPrint("Failed to update the end date: $e");
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
    } catch (e) {
      debugPrint("Failed to fetch account leave requests: $e");
    }

    return leaves;
  }

  Future<int> fetchAccountAnnualLeave(
      {required SupabaseDbHelper dbHelper, required int accountId}) async {
    Metric? employeeMetric;
    try {
      final response = await dbHelper.getRowByField(
          'employee_metrics', 'account_id', accountId, Metric.fromMap);
      employeeMetric = response;
    } catch (e) {
      debugPrint("Failed to fetch account annual leave: $e");
    }
    int annualLeave;
    if (employeeMetric != null && employeeMetric.annualLeave != null) {
      annualLeave = employeeMetric.annualLeave!;
      return annualLeave;
    } else {
      return -1;
    }
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

  int daysExcludingSundays(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;

    while (!current.isAfter(end)) {
      if (current.weekday != DateTime.sunday) {
        count++;
      }

      current = current.add(Duration(days: 1));
    }
    return count;
  }

  String readableStrings(String word) {
    return word
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
