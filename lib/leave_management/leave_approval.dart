import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/leave.dart';
import '../request_changes/request_changes_logic.dart';
import 'leave_logic.dart';

class LeaveApproval extends StatefulWidget {
  final List<Leave> leaves;
  final Account account;
  final Future<void> Function()? onRefresh;
  const LeaveApproval(
      {super.key, required this.leaves, required this.account, this.onRefresh});

  @override
  State<LeaveApproval> createState() => _LeaveApprovalState();
}

class _LeaveApprovalState extends State<LeaveApproval> {
  SupabaseDbHelper dbHelper = SupabaseDbHelper();
  RequestChangesLogic requestLogic = RequestChangesLogic();
  LeaveLogic leaveLogic = LeaveLogic();
  bool _isProcessing = false;

  Future<void> _handleAprrovedRequest(Leave request) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      Account? userAccount =
          await leaveLogic.fetchAccount(dbHelper: dbHelper, leave: request);
      // Create New Attendances - attendance_status = on_leave
      await leaveLogic.createNewOnLeaveAttendances(
          dbHelper: dbHelper, leave: request, userAccount: userAccount!);

      // Update annual leave amount
      await leaveLogic.updateAnnualLeaveDays(
          dbHelper: dbHelper, accountId: request.accountId, leave: request);
      // Update Leave Status to Approved
      await leaveLogic.updateApprovalStatus(
          dbHelper: dbHelper,
          leave: request,
          action: 'approve',
          account: widget.account);

      // Refresh
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
    } catch (e) {
      debugPrint(
          "Failed to create account and update request in updateRequestStatus: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request Accepted. Updated Attendance.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectedRequest(Leave request) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      // Update request status to rejected
      await leaveLogic.updateApprovalStatus(
          dbHelper: dbHelper,
          leave: request,
          action: 'reject',
          account: widget.account);

      // Refresh
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
    } catch (e) {
      debugPrint(
          "Failed to create account and update request in updateRequestStatus: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request Rejected.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequests =
        widget.leaves.where((leave) => leave.leaveStatus == 'pending').toList();
    final approvedRequests = widget.leaves
        .where((leave) => leave.leaveStatus == 'approved')
        .toList();
    final rejectedRequests = widget.leaves
        .where((leave) => leave.leaveStatus == 'rejected')
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            children: [
              _buildCategorySection('Pending', pendingRequests),
              _buildCategorySection('Approved', approvedRequests),
              _buildCategorySection('Rejected', rejectedRequests),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Leave> requests) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...requests.isNotEmpty
              ? requests
                  .map((request) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: requestLogic
                              .getStatusColor(request.leaveStatus)
                              .withValues(alpha: 0.4),
                          child: Text(
                            "${request.id}",
                            style: TextStyle(
                                color: requestLogic
                                    .getStatusColor(request.leaveStatus)),
                          ),
                        ),
                        title: Text(
                          "Leave Request: ",
                        ),
                        subtitle: Text(
                            'Date: ${leaveLogic.formatTimeDayAndYear(request.startDate)} - ${leaveLogic.formatTimeDayAndYear(request.endDate)}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showRequestDialog(context, request);
                        },
                      ))
                  .toList()
              : [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No requests found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
        ],
      ),
    );
  }

  void _showRequestDialog(BuildContext context, Leave request) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      Account? accountRequested =
          await leaveLogic.fetchAccount(dbHelper: dbHelper, leave: request);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Center(
              child: Text(
                'Leave Request',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildInfoRow(
                            Icons.person, 'Name', accountRequested!.name),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.catching_pokemon, 'Leave Type',
                            requestLogic.readableStrings(request.leaveType)),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.play_arrow, 'Start Date',
                            leaveLogic.formatTimeDayAndYear(request.startDate)),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.stop, 'End Date',
                            leaveLogic.formatTimeDayAndYear(request.endDate)),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.notes, 'Leave Reason', request.leaveReason),
                        if (request.attachmentUrl != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.attachment, 'Attachment', ''),
                          Image.network(
                            request.attachmentUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text('Failed to load image.');
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: _buildDialogActions(request),
          );
        },
      );
    } catch (e) {
      debugPrint('Failed to fetch account: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDialogActions(Leave request) {
    if (request.leaveStatus == 'pending') {
      return [
        TextButton(
          onPressed: () {
            // Handle Approve
            Navigator.pop(context);
            _handleAprrovedRequest(request);
          },
          child: const Text('Approve'),
        ),
        TextButton(
          onPressed: () {
            // Handle Reject
            Navigator.pop(context);

            _handleRejectedRequest(request);
          },
          child: const Text('Reject'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ];
    }
  }
}
