import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/requests.dart';
import 'request_changes_logic.dart';

class AccountEditRequest extends StatefulWidget {
  final List<Request> editRequests;
  final Account account;
  final Future<void> Function()? onRefresh;
  const AccountEditRequest(
      {super.key,
      required this.account,
      required this.editRequests,
      this.onRefresh});

  @override
  State<AccountEditRequest> createState() => _AccountEditRequestState();
}

class _AccountEditRequestState extends State<AccountEditRequest> {
  Account? accountRequested;
  RequestChangesLogic requestLogic = RequestChangesLogic();
  SupabaseDbHelper dbHelper = SupabaseDbHelper();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final pendingRequests = widget.editRequests
        .where((req) => req.requestStatus == 'pending')
        .toList();
    final approvedRequests = widget.editRequests
        .where((req) => req.requestStatus == 'approved')
        .toList();
    final rejectedRequests = widget.editRequests
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
              color: Colors.black.withOpacity(0.3),
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
                              .withOpacity(0.4),
                          child: Text(
                            "${request.id}",
                            style: TextStyle(
                                color: requestLogic
                                    .getStatusColor(request.requestStatus)),
                          ),
                        ),
                        title: Text(
                          "Edit Account: ${request.requestedChanges['name']}",
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

  void _showRequestDialog(BuildContext context, Request request) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      Account? accountRequested = await requestLogic.getRequestedAccount(
          dbHelper: dbHelper, requested: request);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Center(
              child: Text(
                'Edit Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Before Card:
                  _buildInfoCardAccount(
                      accountRequested!, "Account Information"),
                  _buildInfoCardRequest(
                      accountRequested, request, "Requested Changes"),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: _buildDialogActions(request, accountRequested),
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

  List<Widget> _buildDialogActions(Request request, Account account) {
    if (request.requestStatus == 'pending') {
      return [
        TextButton(
          onPressed: () {
            // Handle Approve
            Navigator.pop(context);
            _handleAprrovedRequest(request, account);
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

  Widget _buildInfoCardAccount(Account account, String cardTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "$cardTitle :",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: account.imageUrl != null
                        ? NetworkImage(account.imageUrl!)
                        : null,
                    child: account.imageUrl == null
                        ? Text(
                            (account.name.isNotEmpty)
                                ? account.name[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 28),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.person, 'Name', account.name),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, 'Phone', account.phone),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCardRequest(
      Account account, Request request, String cardTitle) {
    Map<String, dynamic> requested = request.requestedChanges;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "$cardTitle :",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: requested['image_url'] != null
                        ? NetworkImage(requested['image_url'])
                        : account.imageUrl != null
                            ? NetworkImage(account.imageUrl!)
                            : null,
                    child: requested['image_url'] == null &&
                            account.imageUrl == null
                        ? Text(
                            (requested['name'] != null &&
                                    requested['name'].toString().isNotEmpty)
                                ? requested['name'][0].toString().toUpperCase()
                                : "?",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 28),
                          )
                        : null,
                  ),
                ),
                if (requested['image_url'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Requested changes of profile picture",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  )
                ],
                const SizedBox(height: 16),
                _buildInfoRow(Icons.person, 'Name', requested['name']),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, 'Phone', requested['phone']),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAprrovedRequest(Request request, Account account) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      await requestLogic.updateAccount(dbHelper: dbHelper, request: request);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request Accepted. Account updated.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleRejectedRequest(Request request) async {
    setState(() {
      _isProcessing = true;
    });
    try {
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
