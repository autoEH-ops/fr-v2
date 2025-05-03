import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../attendance_dashboard/attendance_dashboard.dart';
import '../attendance_dashboard/dashboard_logic.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/attendance.dart';
import '../model/setting.dart';
import 'mark_attendance_response.dart';

final supabase = Supabase.instance.client;
final DashboardLogic dashboardLogic = DashboardLogic();
Future<Account?> getAccountByName({
  required SupabaseDbHelper dbHelper,
  required String recognizedName,
}) async {
  try {
    return await dbHelper.getRowByField<Account>(
      'accounts',
      'name',
      recognizedName,
      (data) => Account.fromMap(data),
    );
  } catch (e) {
    debugPrint("Failed to get Account: $e");
    return null;
  }
}

Future<void> insertActivity(
    {required SupabaseDbHelper dbHelper,
    required Map<String, dynamic> row}) async {
  try {
    await dbHelper.insert('activities', row);
  } catch (e) {
    debugPrint("Failed to insert activity: $e");
  }
}

Future<Attendance?> getLatestAttendance({
  required SupabaseDbHelper dbHelper,
  required int? accountId,
}) async {
  const table = "attendance_v2";

  try {
    return await dbHelper.getRowWhereFieldForCurrentDay<Attendance>(
      table: table,
      fieldName: 'account_id',
      fieldValue: accountId,
      dateTimeField: 'attendance_time',
      fromMap: (data) => Attendance.fromMap(data),
    );
  } catch (e) {
    debugPrint("Failed to get Attendance: $e");
    return null;
  }
}

enum MarkAttendanceResult {
  successCheckIn,
  successCheckOut,
  updatedActivity,
  cancelled,
  error,
}

Future<MarkAttendanceResponse> markAttendance({
  required BuildContext context,
  required SupabaseDbHelper dbHelper,
  required String recognizedName,
}) async {
  final table = "attendance_v2";
  final now = DateTime.now();

  final account = await getAccountByName(
    dbHelper: dbHelper,
    recognizedName: recognizedName,
  );

  if (account == null) {
    return MarkAttendanceResponse(result: MarkAttendanceResult.cancelled);
  }
  final attendance = await getLatestAttendance(
    dbHelper: dbHelper,
    accountId: account.id,
  );

  String? status;
  String? activity;

  if (attendance == null) {
    status = 'check_in';
  } else {
    final isCheckIn = attendance.attendanceStatus == 'check_in';

    if (isCheckIn && now.hour < 18) {
      if (!context.mounted) {
        return MarkAttendanceResponse(result: MarkAttendanceResult.error);
      }
      activity = await showManageActivityDialog(context, account, dbHelper);
      if (activity == null) {
        return MarkAttendanceResponse(result: MarkAttendanceResult.cancelled);
      }
      if (!context.mounted) {
        return MarkAttendanceResponse(result: MarkAttendanceResult.error);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Current activity updated: ${dashboardLogic.readableString(activity)}"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      return MarkAttendanceResponse(
          result: MarkAttendanceResult.updatedActivity, account: account);
    }

    status =
        attendance.attendanceStatus == 'check_in' ? 'check_out' : 'check_in';
  }
  if (!context.mounted) {
    return MarkAttendanceResponse(result: MarkAttendanceResult.error);
  }
  final confirmed = await showConfirmCheckDialog(context, status);
  if (!confirmed) {
    return MarkAttendanceResponse(result: MarkAttendanceResult.cancelled);
  }
  try {
    await dbHelper.insert(table, {
      'account_id': account.id,
      'attendance_status': status,
    });

    final cutOff = DateTime(now.year, now.month, now.day, 9, 0, 0);

    if (status == 'check_in' && now.isBefore(cutOff)) {
      await insertActivity(dbHelper: dbHelper, row: {
        'activity': 'work',
        'account_id': account.id,
      });
    } else if (status == 'check_in') {
      await insertActivity(dbHelper: dbHelper, row: {
        'activity': 'work',
        'account_id': account.id,
        'is_late': true,
      });
    }
    debugPrint("Attendance marked for ${account.name}");
    if (!context.mounted) {
      return MarkAttendanceResponse(result: MarkAttendanceResult.error);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          "${status == 'check_in' ? 'Check in' : 'Check out'} for: ${account.name}"),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.green,
    ));

    return MarkAttendanceResponse(
      result: status == 'check_in'
          ? MarkAttendanceResult.successCheckIn
          : MarkAttendanceResult.successCheckOut,
      account: account,
      attendance: attendance,
    );
  } catch (e) {
    debugPrint("Attendance Data is not Saved: $e");
    return MarkAttendanceResponse(result: MarkAttendanceResult.error);
  }
}

void handleAttendanceResult(BuildContext context, MarkAttendanceResult result,
    MarkAttendanceResponse response, List<Setting> systemSettings) {
  switch (result) {
    case MarkAttendanceResult.successCheckIn:
    case MarkAttendanceResult.updatedActivity:
    case MarkAttendanceResult.successCheckOut:
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceDashboard(
            account: response.account!,
            systemSettings: systemSettings,
          ),
        ),
      );

      break;

    case MarkAttendanceResult.cancelled:
      Navigator.of(context).pop();
      break;

    case MarkAttendanceResult.error:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot mark in current time. Try again later."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      break;
  }
}

Future<String?> showManageActivityDialog(
    BuildContext context, Account account, SupabaseDbHelper dbHelper) async {
  String? selectedActivity;
  final TextEditingController reasonController = TextEditingController();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Current Status'),
            content: ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text('Work'),
                      value: 'work',
                      groupValue: selectedActivity,
                      onChanged: (value) {
                        setState(() {
                          selectedActivity = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Toilet'),
                      value: 'toilet',
                      groupValue: selectedActivity,
                      onChanged: (value) {
                        setState(() {
                          selectedActivity = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Break'),
                      value: 'break',
                      groupValue: selectedActivity,
                      onChanged: (value) {
                        setState(() {
                          selectedActivity = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Meeting'),
                      value: 'meeting',
                      groupValue: selectedActivity,
                      onChanged: (value) {
                        setState(() {
                          selectedActivity = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Prayers'),
                      value: 'prayers',
                      groupValue: selectedActivity,
                      onChanged: (value) {
                        setState(() {
                          selectedActivity = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Early Leave'),
                      value: 'early_leave',
                      groupValue: selectedActivity,
                      onChanged: (value) {
                        setState(() {
                          selectedActivity = value;
                        });
                      },
                    ),
                    if (selectedActivity == 'early_leave') ...[
                      SizedBox(height: 10),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Reason for Early Leave',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(null);
                },
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedActivity != null) {
                    if (selectedActivity != 'early_leave') {
                      Map<String, dynamic> row = {
                        'activity': selectedActivity,
                        'account_id': account.id,
                      };
                      await insertActivity(dbHelper: dbHelper, row: row);
                    } else {
                      Map<String, dynamic> row = {
                        'activity': selectedActivity,
                        'account_id': account.id,
                        'message': reasonController.text,
                      };
                      await insertActivity(dbHelper: dbHelper, row: row);
                      await dbHelper.insert('attendance_v2', {
                        'account_id': account.id,
                        'attendance_status': 'check_out',
                      });
                    }
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop(selectedActivity);
                },
                child: Text("Yes"),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool> showConfirmCheckDialog(BuildContext context, String status) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(
                'Confirm ${status == 'check_in' ? 'Check In' : 'Check Out'}'),
            content: Text(
                'Are you sure you want to ${status == 'check_in' ? 'check in' : 'check out'}?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('Yes'),
              ),
            ],
          );
        },
      ) ??
      false;
}
