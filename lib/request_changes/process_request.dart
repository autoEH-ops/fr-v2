import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/account_edit_request.dart';
import 'request_changes_logic.dart';

class ProcessRequest extends StatefulWidget {
  final Account account;
  const ProcessRequest({super.key, required this.account});

  @override
  State<ProcessRequest> createState() => _ProcessRequestState();
}

class _ProcessRequestState extends State<ProcessRequest> {
  List<AccountEditRequest> requests = [];
  late Account? requestedAccount;
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final RequestChangesLogic requestsLogic = RequestChangesLogic();
  bool _isLoading = true;
  bool _isLoadingModal = true;

  @override
  void initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadRequests = await requestsLogic.getRequests(dbHelper: dbHelper);

    setState(() {
      requests = loadRequests;
      _isLoading = false;
    });
  }

  Widget _buildUserAvatar(String? imageUrl, String name) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.blueAccent,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
      child: imageUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(color: Colors.white, fontSize: 28),
            )
          : null,
    );
  }

  void _showRequestDialog(AccountEditRequest request) async {
    try {
      _isLoadingModal = true;
      final loadRequestedAccount = await requestsLogic.getRequestedAccount(
        dbHelper: dbHelper,
        requested: request,
      );

      setState(() {
        requestedAccount = loadRequestedAccount;
      });
    } catch (e) {
      debugPrint("Failed to get requested account: $e");
    } finally {
      _isLoadingModal = false;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(
              'Request #${request.id} (${request.requestStatus.toUpperCase()})'),
          content: SingleChildScrollView(
            child: _isLoadingModal
                ? const Center(child: CircularProgressIndicator())
                : requestedAccount == null
                    ? const Center(child: Text("Account does not exist"))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: _buildUserAvatar(
                                  requestedAccount!.imageUrl,
                                  requestedAccount!.name)),
                          const SizedBox(height: 16),
                          const Text("After:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...request.requestedChanges.entries.map((e) => Text(
                              "${e.key.toString()[0].toUpperCase() + e.key.toString().substring(1).toLowerCase()}: ${e.value}")),
                          if (request.requestedChanges.isEmpty)
                            const Text("No changes specified."),
                        ],
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<AccountEditRequest?> _showRequestDialogPending(
      AccountEditRequest request) async {
    try {
      _isLoadingModal = true;
      final loadRequestedAccount = await requestsLogic.getRequestedAccount(
        dbHelper: dbHelper,
        requested: request,
      );

      setState(() {
        requestedAccount = loadRequestedAccount;
      });
    } catch (e) {
      debugPrint("Failed to get requested account: $e");
    } finally {
      _isLoadingModal = false;
    }

    return showDialog<AccountEditRequest>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(
              'Request #${request.id} (${request.requestStatus.toUpperCase()})'),
          content: SingleChildScrollView(
            child: _isLoadingModal
                ? const Center(child: CircularProgressIndicator())
                : requestedAccount == null
                    ? const Center(child: Text("Account does not exist"))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: _buildUserAvatar(
                                  requestedAccount!.imageUrl,
                                  requestedAccount!.name)),
                          const SizedBox(height: 16),
                          const Text("Before:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text("Name: ${requestedAccount!.name}"),
                          Text("Email: ${requestedAccount!.email}"),
                          Text("Phone: ${requestedAccount!.phone}"),
                          const SizedBox(height: 16),
                          const Text("After:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...request.requestedChanges.entries.map((e) => Text(
                              "${e.key.toString()[0].toUpperCase() + e.key.toString().substring(1).toLowerCase()}: ${e.value}")),
                          if (request.requestedChanges.isEmpty)
                            const Text("No changes specified."),
                        ],
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _updateRequestStatus(request, "approve");
              },
              child: const Text("Approve"),
            ),
            TextButton(
              onPressed: () async {
                _updateRequestStatus(request, "reject");
                Navigator.of(context).pop();
              },
              child: const Text("Reject"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _updateRequestStatus(AccountEditRequest request, String action) async {
    try {
      if (action == "approve") {
        await requestsLogic.updateAccount(dbHelper: dbHelper, request: request);
      }

      await requestsLogic.updateRequest(
          dbHelper: dbHelper,
          request: request,
          account: widget.account,
          action: action);
    } catch (e) {
      debugPrint(
          "Failed to update account and request in updateRequestStatus: $e");
    } finally {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Account updated. Updated photo will take time to process and take effect')),
      );

      Navigator.pop(context, request);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        requests.where((r) => r.requestStatus == 'pending').toList();
    final approved =
        requests.where((r) => r.requestStatus == 'approved').toList();
    final rejected =
        requests.where((r) => r.requestStatus == 'rejected').toList();

    Widget buildSection(
        String title,
        List<AccountEditRequest> data,
        Color color,
        void Function(AccountEditRequest) onTap,
        String emptyText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                  child: Text(emptyText, style: TextStyle(color: Colors.grey))),
            )
          else
            ...data.map((r) => Card(
                  color: color.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: Text(r.requestStatus[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text('Request #${r.id ?? "-"}'),
                    subtitle: Text(
                        'Tap to ${r.requestStatus == "pending" ? "review" : "view"}'),
                    trailing:
                        Icon(Icons.arrow_forward_ios, size: 16, color: color),
                    onTap: () async {
                      final result = await _showRequestDialogPending(r);
                      if (result != null) {
                        await loadLatestData();
                      }
                    },
                  ),
                )),
          const SizedBox(height: 16),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Process Edit Requests')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(child: Text("No requests found."))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    buildSection(
                        'Pending Requests',
                        pending,
                        Colors.orange,
                        _showRequestDialogPending,
                        'No Pending Requests So Far'),
                    buildSection('Approved Requests', approved, Colors.green,
                        _showRequestDialog, 'No Approved Requests Yet'),
                    buildSection('Rejected Requests', rejected, Colors.red,
                        _showRequestDialog, 'No Rejected Requests Yet'),
                  ],
                ),
    );
  }
}
