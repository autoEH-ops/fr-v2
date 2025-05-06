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
      dbHelper: dbHelper,
      account: widget.account,
    );

    loadRequests.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    setState(() {
      requests = loadRequests;
      _isLoading = false;
    });
  }

  String _getStatusMessage(Request request) {
    switch (request.requestStatus) {
      case 'pending':
        return 'Awaiting admin approval.';
      case 'approved':
        return 'Approved. Please re-login to apply changes.';
      case 'rejected':
        return 'Rejected. Submit a new request or contact admin.';
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
        title: Text("Request #${request.id}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(
                  "Requested on", requestsLogic.formatTime(request.createdAt!)),
              if (request.requestStatus == "approved")
                _infoRow("Approved on",
                    requestsLogic.formatTime(request.reviewedAt!)),
              const Divider(),
              Text("Changes Requested:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _infoRow("Name", request.requestedChanges['name']),
              _infoRow("Email", request.requestedChanges['email']),
              _infoRow("Phone", request.requestedChanges['phone']),
              const SizedBox(height: 8),
              if (request.requestedChanges['image_url'] != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      request.requestedChanges['image_url']!,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text('Failed to load image.'),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
            ],
          ),
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

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
              child: Text(value ?? "-", style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Status"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(child: Text("No requests made yet."))
              : ListView.separated(
                  itemCount: requests.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4),
                          child: Text(
                            requestsLogic.formatTime(request.createdAt!),
                            style: const TextStyle(
                                fontSize: 14.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showRequestDetails(request),
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: _getCardColor(request.requestStatus),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: const Icon(Icons.info_outline),
                              title: Text("Request #${request.id}"),
                              subtitle: Text(_getStatusMessage(request)),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
