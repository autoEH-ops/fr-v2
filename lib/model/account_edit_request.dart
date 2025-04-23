import 'dart:convert';

class AccountEditRequest {
  final int? id;
  final int accountId;
  final Map<String, dynamic> requestedChanges;
  final String requestStatus; // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final int? reviewedBy;

  AccountEditRequest({
    this.id,
    required this.accountId,
    required this.requestedChanges,
    required this.requestStatus,
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory AccountEditRequest.fromMap(Map<String, dynamic> map) {
    return AccountEditRequest(
      id: map['id'] as int?,
      accountId: map['user_id'] as int,
      requestedChanges: Map<String, dynamic>.from(
        map['requested_changes'] is String
            ? jsonDecode(map['requested_changes'])
            : map['requested_changes'],
      ),
      requestStatus: map['request_status'] as String,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'])
          : null,
      reviewedBy: map['reviewed_by'] as int?,
    );
  }
}
