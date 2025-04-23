import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account_edit_request.dart';
import 'request_changes_logic.dart';

class ProcessRequest extends StatefulWidget {
  const ProcessRequest({super.key});

  @override
  State<ProcessRequest> createState() => _ProcessRequestState();
}

class _ProcessRequestState extends State<ProcessRequest> {
  List<AccountEditRequest> requests = [];
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final RequestChangesLogic requestsLogic = RequestChangesLogic();
  bool _isLoading = true;

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

  // void _showRequestDialog(Map<String, dynamic> request, bool allowActions) {
  //   showDialog(
  //     context: context,
  //     builder: (_) {
  //       return AlertDialog(
  //         title: Text('Request #${request['id']} (${request['status']})'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text("Requested Changes"),
  //               ...request['after']
  //                   .entries
  //                   .map((e) => Text("${e.key}: ${e.value}")),
  //             ],
  //           ),
  //         ),
  //         actions: allowActions
  //             ? [
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                     _updateRequestStatus(request['id'], 'approved');
  //                   },
  //                   child: const Text("Approve"),
  //                 ),
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                     _updateRequestStatus(request['id'], 'rejected');
  //                   },
  //                   child: const Text("Reject"),
  //                 ),
  //               ]
  //             : [
  //                 TextButton(
  //                   onPressed: () => Navigator.of(context).pop(),
  //                   child: const Text("Close"),
  //                 ),
  //               ],
  //       );
  //     },
  //   );
  // }

  // void _showRequestDialogPending(
  //     Map<String, dynamic> request, bool allowActions) {
  //   showDialog(
  //     context: context,
  //     builder: (_) {
  //       return AlertDialog(
  //         title: Text('Request #${request['id']} (${request['status']})'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text("Before:"),
  //               ...request['before']
  //                   .entries
  //                   .map((e) => Text("${e.key}: ${e.value}")),
  //               const SizedBox(height: 8),
  //               Text("After:"),
  //               ...request['after']
  //                   .entries
  //                   .map((e) => Text("${e.key}: ${e.value}")),
  //             ],
  //           ),
  //         ),
  //         actions: allowActions
  //             ? [
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                     _updateRequestStatus(request['id'], 'approved');
  //                   },
  //                   child: const Text("Approve"),
  //                 ),
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                     _updateRequestStatus(request['id'], 'rejected');
  //                   },
  //                   child: const Text("Reject"),
  //                 ),
  //               ]
  //             : [
  //                 TextButton(
  //                   onPressed: () => Navigator.of(context).pop(),
  //                   child: const Text("Close"),
  //                 ),
  //               ],
  //       );
  //     },
  //   );
  // }

  // void _updateRequestStatus(int id, String newStatus) {
  //   setState(() {
  //     final index = requests.indexWhere((req) => req['id'] == id);
  //     if (index != -1) {
  //       requests[index]['status'] = newStatus;
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // final pending = requests.where((r) => r['status'] == 'pending').toList();
    // final approved = requests.where((r) => r['status'] == 'approved').toList();
    // final rejected = requests.where((r) => r['status'] == 'rejected').toList();

    return Scaffold(
        appBar: AppBar(title: const Text('Process Edit Requests')),
        body: Center(
          child: Text(requests[0].requestStatus),
        )
        // ListView(
        //   padding: const EdgeInsets.all(12),
        //   children: [
        //     const Text('Pending',
        //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        //     ...pending.map((r) => ListTile(
        //           title: Text('Request #${r['id']}'),
        //           subtitle: const Text('Tap to review'),
        //           onTap: () => _showRequestDialogPending(r, true),
        //         )),
        //     const Divider(),
        //     const Text('Approved',
        //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        //     ...approved.map((r) => ListTile(
        //           title: Text('Request #${r['id']}'),
        //           subtitle: const Text('Approved'),
        //           onTap: () => _showRequestDialog(r, false),
        //         )),
        //     const Divider(),
        //     const Text('Rejected',
        //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        //     ...rejected.map((r) => ListTile(
        //           title: Text('Request #${r['id']}'),
        //           subtitle: const Text('Rejected'),
        //           onTap: () => _showRequestDialog(r, false),
        //         )),
        //   ],
        // ),
        );
  }
}
