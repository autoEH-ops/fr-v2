import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/requests.dart';
import 'request_changes_logic.dart';

// class ProcessRequest extends StatefulWidget {
//   final Account account;
//   const ProcessRequest({super.key, required this.account});

//   @override
//   State<ProcessRequest> createState() => _ProcessRequestState();
// }

// class _ProcessRequestState extends State<ProcessRequest> {
//   List<Request> requests = [];
//   late Account? requestedAccount;
//   final SupabaseDbHelper dbHelper = SupabaseDbHelper();
//   final RequestChangesLogic requestsLogic = RequestChangesLogic();
//   bool _isLoading = true;
//   bool _isLoadingModal = true;

//   @override
//   void initState() {
//     super.initState();
//     loadLatestData();
//   }

//   Future<void> loadLatestData() async {
//     final loadRequests = await requestsLogic.getRequests(dbHelper: dbHelper);

//     setState(() {
//       requests = loadRequests;
//       _isLoading = false;
//     });
//   }

//   Widget _buildUserAvatar(String? imageUrl, String name) {
//     return Center(
//       child: CircleAvatar(
//         radius: 50,
//         backgroundColor: Colors.blueAccent,
//         backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
//         child: imageUrl == null
//             ? Text(
//                 name.isNotEmpty ? name[0].toUpperCase() : "?",
//                 style: const TextStyle(color: Colors.white, fontSize: 28),
//               )
//             : null,
//       ),
//     );
//   }

//   void _showRequestDialog(Request request) async {
//     try {
//       _isLoadingModal = true;
//       final loadRequestedAccount = await requestsLogic.getRequestedAccount(
//         dbHelper: dbHelper,
//         requested: request,
//       );

//       setState(() {
//         requestedAccount = loadRequestedAccount;
//       });
//     } catch (e) {
//       debugPrint("Failed to get requested account: $e");
//     } finally {
//       _isLoadingModal = false;
//     }

//     return showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) {
//         return AlertDialog(
//           title: Text(
//               'Request ${request.id} (${requestsLogic.readableString(request.requestStatus)})'),
//           content: SingleChildScrollView(
//             child: _isLoadingModal
//                 ? const Center(child: CircularProgressIndicator())
//                 : requestedAccount == null
//                     ? const Center(child: Text("Account does not exist"))
//                     : request.requestCategory == 'register_account'
//                         ? _buildRegisterRequestUI(request)
//                         : _buildEditRequestUI(request),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text("Close"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<Request?> _showRequestDialogPending(Request request) async {
//     try {
//       _isLoadingModal = true;
//       final loadRequestedAccount = await requestsLogic.getRequestedAccount(
//         dbHelper: dbHelper,
//         requested: request,
//       );

//       setState(() {
//         requestedAccount = loadRequestedAccount;
//       });
//     } catch (e) {
//       debugPrint("Failed to get requested account: $e");
//     } finally {
//       _isLoadingModal = false;
//     }

//     if (request.requestCategory == 'register_account') {
//       // Show Register Request Dialog
//       return showDialog<Request>(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) {
//           return AlertDialog(
//             title: Text('New Account Registration (Request ${request.id})'),
//             content: SingleChildScrollView(
//               child: _isLoadingModal
//                   ? const Center(child: CircularProgressIndicator())
//                   : _buildRegisterRequestUI(request),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () async {
//                   _updateRequestStatus(request, "approve");
//                 },
//                 child: const Text("Approve Registration"),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   _updateRequestStatus(request, "reject");
//                 },
//                 child: const Text("Reject Registration"),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text("Close"),
//               ),
//             ],
//           );
//         },
//       );
//     } else {
//       // Show Edit Request Dialog
//       return showDialog<Request>(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) {
//           return AlertDialog(
//             title: Text('Edit Account Request (Request ${request.id})'),
//             content: SingleChildScrollView(
//               child: _isLoadingModal
//                   ? const Center(child: CircularProgressIndicator())
//                   : requestedAccount == null
//                       ? const Center(child: Text("Account does not exist"))
//                       : _buildEditRequestUI(request),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () async {
//                   _updateRequestStatus(request, "approve");
//                 },
//                 child: const Text("Approve Changes"),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   _updateRequestStatus(request, "reject");
//                 },
//                 child: const Text("Reject Changes"),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text("Close"),
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }

//   Future<void> _updateRequestStatus(Request request, String action) async {
//     try {
//       if (action == "approve") {
//         List<String> deletedPath = [];
//         debugPrint("Requested account: ${requestedAccount!.imageUrl}");

//         if (requestedAccount != null) {
//           if (requestedAccount!.imageUrl != null) {
//             deletedPath.add(requestedAccount!.imageUrl!);
//           }
//           debugPrint("deletedPath: $deletedPath");

//           await dbHelper.deleteFromBucket(deletedPath);
//         }
//         await requestsLogic.updateAccount(dbHelper: dbHelper, request: request);
//       }

//       await requestsLogic.updateRequest(
//           dbHelper: dbHelper,
//           request: request,
//           account: widget.account,
//           action: action);
//     } catch (e) {
//       debugPrint(
//           "Failed to update account and request in updateRequestStatus: $e");
//     } finally {
//       if (action == "approve") {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Request Accepted. Account updated.'),
//             behavior: SnackBarBehavior.floating,
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Request Rejected.'),
//             behavior: SnackBarBehavior.floating,
//             backgroundColor: Colors.red,
//           ),
//         );
//       }

//       Navigator.pop(context, request);
//     }
//   }

//   Widget _buildEditRequestUI(Request request) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Center(
//             child: _buildUserAvatar(
//                 requestedAccount!.imageUrl, requestedAccount!.name)),
//         const SizedBox(height: 16),
//         const Text("Request:", style: TextStyle(fontWeight: FontWeight.bold)),
//         if (request.requestedChanges.containsKey('image_url'))
//           _buildUserAvatar(request.requestedChanges['image_url'],
//               request.requestedChanges['name']),
//         if (request.requestedChanges.containsKey('image_url'))
//           Text("Requested changes in profile picture"),
//         const SizedBox(height: 6),
//         ...request.requestedChanges.entries
//             .where((entry) => entry.key != 'image_url')
//             .map((e) => Text(
//                 "${e.key.toString()[0].toUpperCase() + e.key.toString().substring(1).toLowerCase()}: ${e.value}")),
//         if (request.requestedChanges.isEmpty)
//           const Text("No changes specified."),
//       ],
//     );
//   }

//   Widget _buildRegisterRequestUI(Request request) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("New Account Registration:",
//             style: TextStyle(fontWeight: FontWeight.bold)),
//         const SizedBox(height: 8),
//         _buildUserAvatar(request.requestedChanges['image_url'],
//             request.requestedChanges['name']),
//         const SizedBox(height: 12),
//         ...request.requestedChanges.entries
//             .where((entry) => entry.key != 'embeddings')
//             .map((e) => Text(
//                 "${e.key[0].toUpperCase()}${e.key.substring(1)}: ${e.value}")),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pending =
//         requests.where((r) => r.requestStatus == 'pending').toList();
//     final approved =
//         requests.where((r) => r.requestStatus == 'approved').toList();
//     final rejected =
//         requests.where((r) => r.requestStatus == 'rejected').toList();

//     Widget buildSection(String title, List<Request> data, Color color,
//         void Function(Request) onTap, String emptyText) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style:
//                   const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 8),
//           if (data.isEmpty)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               child: Center(
//                   child: Text(emptyText, style: TextStyle(color: Colors.grey))),
//             )
//           else
//             ...data.map((r) => Card(
//                   color: color.withOpacity(0.1),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: color,
//                       child: Text(r.requestStatus[0].toUpperCase(),
//                           style: const TextStyle(color: Colors.white)),
//                     ),
//                     title: Text('Request ${r.id ?? "-"}'),
//                     subtitle: Text(
//                         'Tap to ${r.requestStatus == "pending" ? "review" : "view"}'),
//                     trailing:
//                         Icon(Icons.arrow_forward_ios, size: 16, color: color),
//                     onTap: () async {
//                       if (r.requestStatus == 'pending') {
//                         final result = await _showRequestDialogPending(r);
//                         if (result != null) {
//                           await loadLatestData();
//                         }
//                       } else {
//                         _showRequestDialog(r);
//                       }
//                     },
//                   ),
//                 )),
//           const SizedBox(height: 16),
//         ],
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Approval')),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : requests.isEmpty
//               ? const Center(child: Text("No requests found."))
//               : ListView(
//                   padding: const EdgeInsets.all(16),
//                   children: [
//                     buildSection(
//                         'Pending Requests',
//                         pending,
//                         Colors.orange,
//                         _showRequestDialogPending,
//                         'No Pending Requests So Far'),
//                     buildSection('Approved Requests', approved, Colors.green,
//                         _showRequestDialog, 'No Approved Requests Yet'),
//                     buildSection('Rejected Requests', rejected, Colors.red,
//                         _showRequestDialog, 'No Rejected Requests Yet'),
//                   ],
//                 ),
//     );
//   }
// }

class ProcessRequest extends StatefulWidget {
  final Account? account;
  const ProcessRequest({super.key, this.account});

  @override
  State<ProcessRequest> createState() => _ProcessRequestState();
}

class _ProcessRequestState extends State<ProcessRequest> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Request> requests = [];
  late Account? requestedAccount;
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final RequestChangesLogic requestsLogic = RequestChangesLogic();
  bool _isLoading = true;
  bool _isLoadingModal = true;

  List<Request> registerRequests = []; // only 'register_account'
  List<Request> editRequests = []; // only 'edit_account'

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final allRequests = await requestsLogic.getRequests(dbHelper: dbHelper);

    setState(() {
      registerRequests = allRequests
          .where((r) => r.requestCategory == 'register_account')
          .toList();
      editRequests = allRequests
          .where((r) => r.requestCategory == 'account_edit')
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Requests Manager'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPageButton("Register", 0),
              _buildPageButton("Edit", 1),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildRequestList(registerRequests, category: 'register_account'),
          _buildRequestList(editRequests, category: 'account_edit'),
        ],
      ),
    );
  }

  Widget _buildPageButton(String label, int pageIndex) {
    return TextButton(
      onPressed: () => _pageController.jumpToPage(pageIndex),
      child: Text(
        label,
        style: TextStyle(
          color: _currentPage == pageIndex ? Colors.blue : Colors.grey,
          fontWeight:
              _currentPage == pageIndex ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRequestList(List<Request> requests, {required String category}) {
    if (requests.isEmpty) {
      return Center(child: Text('No $category requests'));
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('Request ID: ${request.id}'),
            onTap: () => _openRequestDialog(request),
          ),
        );
      },
    );
  }

  Future<void> _openRequestDialog(Request request) async {
    if (request.requestCategory == 'register_account') {
      await _showRegisterRequestDialog(request);
    } else {
      await _showEditRequestDialog(request);
    }
  }

  Future<void> _showRegisterRequestDialog(Request request) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Register Account Request'),
        content: Text('Handle registration here for request ${request.id}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Close'))
        ],
      ),
    );
  }

  Future<void> _showEditRequestDialog(Request request) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Account Request'),
        content: Text('Handle edit here for request ${request.id}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Close'))
        ],
      ),
    );
  }
}
