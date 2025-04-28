class Leave {
  final int? id;
  final int accountId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String status;
  final DateTime? appliedAt;
  final DateTime? approvedAt;
  final int? approvedBy;

  Leave(
      {this.id,
      required this.accountId,
      required this.leaveType,
      required this.startDate,
      required this.endDate,
      required this.status,
      this.reason,
      this.appliedAt,
      this.approvedAt,
      this.approvedBy});

  factory Leave.fromMap(Map<String, dynamic> map) {
    return Leave(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      leaveType: map['leave_type'] as String,
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      reason: map['reason'] as String?,
      status: map['status'] as String,
      appliedAt:
          map['applied_at'] != null ? DateTime.parse(map['applied_at']) : null,
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'])
          : null,
      approvedBy: map['approved_by'] as int?,
    );
  }
}
