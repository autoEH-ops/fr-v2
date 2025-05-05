import 'package:attendance_system_fr_v3/leave_management/leave_logic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/leave.dart';

class LeaveReport extends StatefulWidget {
  const LeaveReport({super.key});

  @override
  State<LeaveReport> createState() => _LeaveReportState();
}

class _LeaveReportState extends State<LeaveReport> {
  List<Leave> allLeaveRequests = [];
  List<Leave> filteredLeaves = [];
  LeaveLogic leaveLogic = LeaveLogic();
  SupabaseDbHelper dbHelper = SupabaseDbHelper();

  bool _isLoading = true;
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    loadLatestData();
  }

  void refreshFilteredLeaves() async {
    setState(() => _isFiltering = true);
    final loadFilteredLeaves = await getFilteredLeaves();
    setState(() {
      filteredLeaves = loadFilteredLeaves;
      _isFiltering = false;
    });
  }

  Future<void> loadLatestData() async {
    final loadAllLeaveRequest =
        await leaveLogic.fetchAllLeaveRequest(dbHelper: dbHelper);
    setState(() {
      allLeaveRequests = loadAllLeaveRequest;
    });
    final loadFilteredLeaves = await getFilteredLeaves();

    debugPrint("Leave Request: ${loadFilteredLeaves.length}");
    setState(() {
      filteredLeaves = loadFilteredLeaves;
      _isLoading = false;
    });
  }

  String searchQuery = '';
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool viewAll = false;

  Future<List<Leave>> getFilteredLeaves() async {
    List<Leave> filtered = [];

    for (Leave leave in allLeaveRequests) {
      Account? userAccount =
          await leaveLogic.fetchAccount(dbHelper: dbHelper, leave: leave);

      final matchesSearch =
          userAccount!.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              leave.leaveType.toLowerCase().contains(searchQuery.toLowerCase());

      final date = leave.startDate;
      final matchesMonthYear =
          viewAll || (date.month == selectedMonth && date.year == selectedYear);

      if (matchesSearch && matchesMonthYear) {
        filtered.add(leave);
      }
    }

    return filtered;
  }

  void _showLeaveDetails(Leave leave, Account account) async {
    Account? adminAccount;
    if (leave.approvedBy != null) {
      adminAccount =
          await leaveLogic.fetchAdminAccount(dbHelper: dbHelper, leave: leave);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Details"),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.7, // 70% of screen height
            maxWidth: 400, // Optional: control width
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailText("Name", account.name),
                _buildDetailText(
                    "Leave Type", leaveLogic.readableStrings(leave.leaveType)),
                _buildDetailText(
                    "From", leaveLogic.formatTimeDayAndYear(leave.startDate)),
                _buildDetailText(
                    "To", leaveLogic.formatTimeDayAndYear(leave.endDate)),
                _buildDetailText('Days Requested',
                    "${leaveLogic.daysExcludingSundays(leave.startDate, leave.endDate)} Days"),
                _buildDetailText("Applied At",
                    leaveLogic.formatTimeReport(leave.appliedAt!)),
                _buildDetailText("Approval Status",
                    leaveLogic.readableStrings(leave.leaveStatus)),
                const SizedBox(height: 8),
                const Text("Reason:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(leave.leaveReason),
                const SizedBox(height: 12),
                if (leave.attachmentUrl != null) ...[
                  const Text("Attachment:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
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
                  ),
                ],
                const SizedBox(height: 12),
                if (leave.approvedBy != null)
                  _buildDetailText(
                      "Approved By", adminAccount?.name ?? "Unknown")
                else if (leave.leaveStatus == "approved")
                  _buildDetailText(
                      "Approved By", "Auto-approved by the system"),
                if (leave.approvedAt != null)
                  _buildDetailText("Approved At",
                      leaveLogic.formatTimeReport(leave.approvedAt!)),
              ],
            ),
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

  Widget _buildDetailText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(
        12, (index) => DateFormat.MMMM().format(DateTime(0, index + 1)));
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);

    return Scaffold(
      appBar: AppBar(title: Text('Leave Report')),
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : allLeaveRequests.isEmpty
              ? const Center(
                  child: Text("No leave request found."),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // 🔍 Search Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Search by name or type",
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onChanged: (value) {
                                  setState(() => searchQuery = value);
                                  refreshFilteredLeaves();
                                }),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // 📅 Filter Row + View All Checkbox
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedMonth,
                              decoration: InputDecoration(
                                labelText: "Month",
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(12, (i) {
                                return DropdownMenuItem(
                                  value: i + 1,
                                  child: Text(months[i]),
                                );
                              }),
                              onChanged: (value) {
                                setState(() => selectedMonth = value!);
                                refreshFilteredLeaves();
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedYear,
                              decoration: InputDecoration(
                                labelText: "Year",
                                border: OutlineInputBorder(),
                              ),
                              items: years
                                  .map((y) => DropdownMenuItem(
                                      value: y, child: Text(y.toString())))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => selectedMonth = value!);
                                refreshFilteredLeaves();
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Column(
                            children: [
                              Checkbox(
                                value: viewAll,
                                onChanged: (val) =>
                                    setState(() => viewAll = val!),
                              ),
                              Text("View All"),
                            ],
                          )
                        ],
                      ),
                      SizedBox(height: 10),
                      // 📋 Leave List
                      Expanded(
                        child: _isFiltering
                            ? Center(child: const CircularProgressIndicator())
                            : filteredLeaves.isEmpty
                                ? Center(child: Text("No leave records found."))
                                : ListView.builder(
                                    itemCount: filteredLeaves.length,
                                    itemBuilder: (context, index) {
                                      final leave = filteredLeaves[index];

                                      return FutureBuilder<Account?>(
                                        future: leaveLogic.fetchAccount(
                                            dbHelper: dbHelper, leave: leave),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return ListTile(
                                              title: Text('Loading account...'),
                                            );
                                          }

                                          if (snapshot.hasError ||
                                              !snapshot.hasData) {
                                            return ListTile(
                                              title: Text('Unknown account'),
                                            );
                                          }

                                          final account = snapshot.data!;
                                          return Card(
                                            color:
                                                leave.leaveStatus == "approved"
                                                    ? Colors.green
                                                    : null,
                                            child: ListTile(
                                              title: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(account.name),
                                                  Text(
                                                      "(${leaveLogic.readableStrings(leave.leaveType)})")
                                                ],
                                              ),
                                              subtitle: Text(
                                                "From: ${DateFormat.yMMMd().format(leave.startDate)}  To: ${DateFormat.yMMMd().format(leave.endDate)}",
                                                style: TextStyle(fontSize: 13),
                                              ),
                                              trailing: Text(
                                                  "${leaveLogic.daysExcludingSundays(leave.startDate, leave.endDate)} days"),
                                              onTap: () => _showLeaveDetails(
                                                  leave, account),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
