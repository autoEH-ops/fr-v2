import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/requests.dart';
import 'account_edit_request.dart';
import 'account_register_request.dart';
import 'request_changes_logic.dart';

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
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Approval"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPageButton("Edit", 0),
              _buildPageButton("Register", 1),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : registerRequests.isEmpty && editRequests.isEmpty
              ? const Center(
                  child: Text("No requests found."),
                )
              : PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: [
                    AccountEditRequest(
                      editRequests: editRequests,
                      account: widget.account!,
                      onRefresh: _loadRequests,
                    ),
                    AccountRegisterRequest(
                      registerRequests: registerRequests,
                      account: widget.account!,
                      onRefresh: _loadRequests,
                    ),
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
}
