import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/attendance.dart';
import 'dashboard_logic.dart';

class InformationPage extends StatefulWidget {
  final Account account;
  const InformationPage({super.key, required this.account});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  List<Attendance> currentDayAttendance = [];
  Activity? latestActivity;
  SupabaseDbHelper dbHelper = SupabaseDbHelper();
  DashboardLogic dashboardLogic = DashboardLogic();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadCurrentDayAttendance = await dashboardLogic.fetchTodayAttendance(
        dbHelper: dbHelper, account: widget.account);
    final loadLatestActivity = await dashboardLogic.getLatestActivity(
        dbHelper: dbHelper, accountId: widget.account.id);

    setState(() {
      currentDayAttendance = loadCurrentDayAttendance;
      latestActivity = loadLatestActivity;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.indigo.shade600,
                          backgroundImage: widget.account.imageUrl != null
                              ? NetworkImage(widget.account.imageUrl!)
                              : null,
                          child: widget.account.imageUrl == null
                              ? Text(
                                  widget.account.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.account.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dashboardLogic.readableString(widget.account.role),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.email, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.account.email,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.account.phone,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  // Status and Activity Container
                  _buildStatus(),
                  // // Remarks Section
                  // if (checkOutEarly != null || isLate != null)
                  //   _buildRemarks(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatus() => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 30),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                if (currentDayAttendance.isEmpty) ...[
                  Text(
                    "Absent",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: dashboardLogic.statusColor('absent'),
                    ),
                  ),
                ] else if (currentDayAttendance.length == 1) ...[
                  Text(
                    dashboardLogic.readableString(
                        currentDayAttendance.first.attendanceStatus),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: dashboardLogic.statusColor(
                            currentDayAttendance.first.attendanceStatus)),
                  ),
                ] else if (currentDayAttendance.length > 1) ...[
                  Text(
                    dashboardLogic.readableString(
                        currentDayAttendance.last.attendanceStatus),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: dashboardLogic.statusColor(
                          currentDayAttendance.last.attendanceStatus),
                    ),
                  ),
                ]
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Activity",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                if (currentDayAttendance.isNotEmpty &&
                    !(currentDayAttendance.length > 1) &&
                    currentDayAttendance.first.attendanceStatus ==
                        "check_in") ...[
                  Text(
                    dashboardLogic.readableString(latestActivity!.activity),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ] else ...[
                  Text(
                    "-",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      );
}
