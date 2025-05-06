import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/requests.dart';
import 'request_changes_logic.dart';

class RequestStatus extends StatefulWidget {
  final Account account;
  const RequestStatus({super.key, required this.account});

  @override
  State<RequestStatus> createState() => _RequestStatusState();
}

class _RequestStatusState extends State<RequestStatus> {
  List<Request> requests = [];
  late Account reviewerAccount;

  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final RequestChangesLogic requestsLogic = RequestChangesLogic();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadRequests = await requestsLogic.getAccountRequests(
        dbHelper: dbHelper, account: widget.account);

    setState(() {
      requests = loadRequests;
      _isLoading = false;
    });
  }

  String _getStatusMessage(Request request) {
    switch (request.requestStatus) {
      case 'pending':
        return 'Please wait for admin approval.';
      case 'approved':
        return 'Your request is approved. Please re-login to see the changes.';
      case 'rejected':
        return 'Your request has been rejected. Submit another request or contact the admin.';
      default:
        return 'Unknown status.';
    }
  }

  Color _getCardColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade100;
      case 'approved':
        return Colors.green.shade100;
      case 'rejected':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  void _showRequestDetails(Request request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Request ${request.id} Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Status: ${requestsLogic.readableString(request.requestStatus)}"),
            const SizedBox(height: 10),
            Text(_getStatusMessage(request)),
            const SizedBox(height: 10),
            Text("Requested on: "),
            Text(requestsLogic.formatTime(request.createdAt!)),
            const SizedBox(height: 10),
            if (request.requestStatus == "approved")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text("Approved on: "),
                  Text(requestsLogic.formatTime(request.reviewedAt!))
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("View Employee Activity"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : requests.isEmpty
                ? const Center(child: Text("No requests have been made."))
                : ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return GestureDetector(
                        onTap: () => _showRequestDetails(request),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: _getCardColor(request.requestStatus),
                          child: ListTile(
                            title: Text("Request #${request.id}"),
                            subtitle: Text(_getStatusMessage(request)),
                            leading: const Icon(Icons.info_outline),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
