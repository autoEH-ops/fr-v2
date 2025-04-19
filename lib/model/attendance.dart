class Attendance {
// -- Create attendance table
// CREATE TABLE attendance_v2 (
//     id SERIAL PRIMARY KEY,
//     account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
//     attendance_time TIMESTAMPTZ DEFAULT NOW(),
//     attendance_status TEXT CHECK (attendance_status IN ('check_in', 'check_out')) NOT NULL
// );

  int? id;
  int accountId;
  DateTime? attendanceTime;
  String attendanceStatus;

  Attendance(
      this.id, this.accountId, this.attendanceTime, this.attendanceStatus);
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      map['id'] as int?,
      map['account_id'] as int,
      map['attendance_time'] != null
          ? DateTime.parse(map['attendance_time'])
          : null,
      map['attendance_status'] as String,
    );
  }
}
