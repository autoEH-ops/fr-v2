class Metric {
  int? id;
  int accountId;
  int? annualLeave;
  Metric({this.id, required this.accountId, this.annualLeave});

  factory Metric.fromMap(Map<String, dynamic> map) {
    return Metric(
        id: map['id'] as int?,
        accountId: map['account_id'] as int,
        annualLeave: map['annual_leave_entitlement'] as int?);
  }
}
