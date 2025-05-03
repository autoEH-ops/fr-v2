import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/requests.dart';
import 'request_changes_logic.dart';

class AccountRegisterRequest extends StatefulWidget {
  final List<Request> registerRequests;
  final Account account;
  final Future<void> Function()? onRefresh;
  const AccountRegisterRequest(
      {super.key,
      required this.account,
      required this.registerRequests,
      this.onRefresh});

  @override
  State<AccountRegisterRequest> createState() => _AccountRegisterRequestState();
}

class _AccountRegisterRequestState extends State<AccountRegisterRequest> {
  RequestChangesLogic requestLogic = RequestChangesLogic();
  SupabaseDbHelper dbHelper = SupabaseDbHelper();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final pendingRequests = widget.registerRequests
        .where((req) => req.requestStatus == 'pending')
        .toList();
    final approvedRequests = widget.registerRequests
        .where((req) => req.requestStatus == 'approved')
        .toList();
    final rejectedRequests = widget.registerRequests
        .where((req) => req.requestStatus == 'rejected')
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

  Widget _buildCategorySection(String title, List<Request> requests) {
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
                              .getStatusColor(request.requestStatus)
                              .withValues(alpha: 0.4),
                          child: Text(
                            "${request.id}",
                            style: TextStyle(
                                color: requestLogic
                                    .getStatusColor(request.requestStatus)),
                          ),
                        ),
                        title: Text(
                          "Create account: ${requestLogic.readableStrings(request.requestedChanges['role'])} ${request.requestedChanges['name']}",
                        ),
                        subtitle: Text('Request ID: ${request.id}'),
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

  void _showRequestDialog(BuildContext context, Request request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              'Registration Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  color: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blueAccent,
                            backgroundImage:
                                request.requestedChanges['image_url'] != null
                                    ? NetworkImage(
                                        request.requestedChanges['image_url'])
                                    : null,
                            child: request.requestedChanges['image_url'] == null
                                ? Text(
                                    (request.requestedChanges['name']
                                                ?.toString()
                                                .isNotEmpty ??
                                            false)
                                        ? request.requestedChanges['name'][0]
                                            .toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 28),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.person, 'Name',
                            request.requestedChanges['name'] ?? 'Unknown'),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.work,
                            'Role',
                            requestLogic.readableStrings(
                                request.requestedChanges['role'])),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.phone, 'Phone',
                            request.requestedChanges['phone'] ?? 'Unknown'),
                      ],
                    ),
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

  List<Widget> _buildDialogActions(Request request) {
    if (request.requestStatus == 'pending') {
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

  Future<void> _handleAprrovedRequest(Request request) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      // Create new account
      await requestLogic.createNewAccount(
          dbHelper: dbHelper, request: request.requestedChanges);

      // Get the new account
      Account? newAccount = await requestLogic.getNewAccount(
          dbHelper: dbHelper, request: request.requestedChanges);

      // create the embeddings
      if (newAccount != null) {
        await requestLogic.createNewEmbeddings(
            dbHelper: dbHelper,
            account: newAccount,
            request: request.requestedChanges);

        await requestLogic.createNewAnnualLeave(
          dbHelper: dbHelper,
          account: newAccount,
        );
      }

      // Update request status to 'approved'
      await requestLogic.updateRequest(
          dbHelper: dbHelper,
          request: request,
          account: widget.account,
          action: 'approve');

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
            content: Text('Request Accepted. Account created.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectedRequest(Request request) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      // Deleted image in the bucket
      await requestLogic.deleteImageFromBucket(
          dbHelper: dbHelper, request: request.requestedChanges);

      // Update request status to 'rejected'
      await requestLogic.updateRequest(
          dbHelper: dbHelper,
          request: request,
          account: widget.account,
          action: 'reject');

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
}
