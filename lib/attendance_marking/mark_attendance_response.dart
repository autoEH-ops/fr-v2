import '../model/account.dart';
import '../model/attendance.dart';
import 'attendance_logic.dart';

class MarkAttendanceResponse {
  final MarkAttendanceResult result;
  final Account? account;
  final Attendance? attendance;

  MarkAttendanceResponse({required this.result, this.account, this.attendance});
}
