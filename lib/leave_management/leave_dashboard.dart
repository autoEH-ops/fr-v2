import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/leave.dart';
import 'leave_category.dart';
import 'leave_logic.dart';
import 'leave_report.dart';

class LeaveDashboard extends StatefulWidget {
  final Account account;
  final String ocrDictionary;
  const LeaveDashboard(
      {super.key, required this.account, required this.ocrDictionary});

  @override
  State<LeaveDashboard> createState() => _LeaveDashboardState();
}

class _LeaveDashboardState extends State<LeaveDashboard> {
  List<Leave> leaves = [];
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final LeaveLogic leaveLogic = LeaveLogic();
  bool _isLoading = true;
  late final bool isAdmin;
  late final PageController _pageController;
  int _currentPage = 0;
  @override
  void initState() {
    super.initState();
    isAdmin =
        widget.account.role == "admin" || widget.account.role == "super_admin";
    if (isAdmin) {
      _pageController = PageController(initialPage: _currentPage);
    }
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadLeaves = await leaveLogic.fetchAccountLeaveRequest(
        account: widget.account, dbHelper: dbHelper);

    setState(() {
      leaves = loadLeaves;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isAdmin
              ? Column(
                  children: [
                    // Page navigation buttons (previously in AppBar)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPageButton("Apply", 0),
                        _buildPageButton("Report", 1),
                      ],
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        children: [
                          _buildApplyPage(),
                          _buildReportPage(),
                        ],
                      ),
                    ),
                  ],
                )
              : _buildApplyPage(),
    );
  }

  Widget _buildApplyPage() {
    return _isLoading
        ? Center(child: const CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Big Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to Apply Leave Page or show form
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LeaveCategory(
                                onRefresh: loadLatestData,
                                account: widget.account,
                                ocrDictionary: widget.ocrDictionary)),
                      );
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Apply for Leave',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Leave Requests List
                Expanded(
                  child: leaves.isEmpty
                      ? const Center(
                          child: Text("No leave request found."),
                        )
                      : ListView.builder(
                          itemCount: leaves.length,
                          itemBuilder: (context, index) {
                            final leave = leaves[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                  leading: const Icon(Icons.calendar_month),
                                  title: Text(leaveLogic
                                      .readableStrings(leave.leaveType)),
                                  subtitle: Text(
                                    'From: ${leaveLogic.formatTime(leave.startDate)} \nTo: ${leaveLogic.formatTime(leave.endDate)}',
                                  ),
                                  trailing: Text(
                                    leaveLogic
                                        .readableStrings(leave.leaveStatus),
                                    style: TextStyle(
                                      color: leave.leaveStatus == 'approved'
                                          ? Colors.green
                                          : (leave.leaveStatus == 'rejected'
                                              ? Colors.red
                                              : Colors.orange),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () =>
                                      _showDialogRequestInformation(leave)),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
  }

  _buildReportPage() {
    return LeaveReport();
  }

  _showDialogRequestInformation(Leave leave) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Request Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Leave Type:\n${leaveLogic.readableStrings(leave.leaveType)}"),
              const SizedBox(height: 8.0),
              Text("Status:\n${leaveLogic.readableStrings(leave.leaveStatus)}"),
              const SizedBox(height: 8.0),
              Text(
                  "Start:\n${leaveLogic.formatTimeDayAndYear(leave.startDate)}"),
              const SizedBox(height: 8.0),
              Text("End:\n${leaveLogic.formatTimeDayAndYear(leave.endDate)}"),
              const SizedBox(height: 8.0),
              Text("Reason:\n${leave.leaveReason}"),
              if (leave.attachmentUrl != null &&
                  leave.attachmentUrl!.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Text("Attachment:"),
                const SizedBox(height: 8.0),
                Image.network(
                  leave.attachmentUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Failed to load image.');
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
