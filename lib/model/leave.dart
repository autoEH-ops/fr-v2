class Leave {
  int? id;
  int accountId;
  String leaveType;
  DateTime startDate;
  DateTime endDate;
  String leaveStatus;
  String? attachmentUrl;
  String leaveReason;
  DateTime? appliedAt;
  DateTime? approvedAt;
  int? approvedBy;

  Leave(
      {this.id,
      required this.accountId,
      required this.leaveType,
      required this.startDate,
      required this.endDate,
      required this.leaveStatus,
      required this.leaveReason,
      this.attachmentUrl,
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
      leaveStatus: map['leave_status'] as String,
      attachmentUrl: map['attachment_url'] as String?,
      leaveReason: map['leave_reason'] as String,
      appliedAt:
          map['applied_at'] != null ? DateTime.parse(map['applied_at']) : null,
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'])
          : null,
      approvedBy: map['approved_by'] as int?,
    );
  }
}
