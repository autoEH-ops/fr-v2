// -- Create activities table
// CREATE TABLE activities (
//     id SERIAL PRIMARY KEY,
//     account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
//     activity TEXT NOT NULL,
//     activity_time TIMESTAMPTZ DEFAULT NOW(),
//     message TEXT,
//     is_late boolean
// );
class Activity {
  final int? id;
  final int accountId;
  final String activity;
  final DateTime? activityTime;
  final String? message;
  final bool? isLate;

  Activity({
    this.id,
    required this.accountId,
    required this.activity,
    this.activityTime,
    this.message,
    this.isLate,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      activity: map['activity'] as String,
      activityTime: map['activity_time'] != null
          ? DateTime.parse(map['activity_time'])
          : null,
      message: map['message'] as String?,
      isLate: map['is_late'] as bool?,
    );
  }
}
