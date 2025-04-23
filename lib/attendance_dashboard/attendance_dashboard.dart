import 'package:created_by_618_abdo/attendance_history/attendance_records.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting date/time
import '../activity_logs/activity_logs.dart';
import '../db/supabase_db_helper.dart';
import '../geolocator/geolocator_service.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/attendance.dart';
import '../model/setting.dart';
import '../widget/dashboard_drawer.dart';
import 'dashboard_logic.dart';

class AttendanceDashboard extends StatefulWidget {
  final Account account;
  final List<Setting> systemSettings;
  const AttendanceDashboard(
      {super.key, required this.account, required this.systemSettings});

  @override
  State<AttendanceDashboard> createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard> {
  final DashboardLogic dashboardLogic = DashboardLogic();
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  Attendance? latestAttendance;
  Activity? latestActivity;
  // Activity? checkOutEarly;
  // Activity? isLate;
  bool isLoading = true;
  late Activity? activity;
  double locationLat = 0.0;
  double locationLong = 0.0;
  final GeolocatorService _geolocatorService = GeolocatorService();
  final DashboardDrawer _dashboardDrawer = DashboardDrawer();

  @override
  void initState() {
    super.initState();
    loadLatestData();
    locationLat = double.parse(widget.systemSettings[0].value);
    locationLong = double.parse(widget.systemSettings[1].value);
  }

  Future<Activity?> checkEarlyCheckOut() async {
    activity = await dbHelper.getActivityRowWhere(
        'activities', widget.account, DateTime.now(), Activity.fromMap);
    return activity;
  }

  String statusLogic(Attendance attendance) {
    final status = attendance.attendanceStatus;
    if (status == "check_in") {
      return "Check In";
    }
    return "Check Out";
  }

  String activityLogic(Attendance attendance, Activity activity) {
    final status = attendance.attendanceStatus;
    if (status == "check_out") {
      return "-";
    }

    return activity.activity
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color statusColor(Attendance attendance) {
    final status = attendance.attendanceStatus;
    if (status == "check_in") {
      return Colors.green;
    }
    return Colors.red;
  }

  Future<void> loadLatestData() async {
    final attendance = await dashboardLogic.getLatestAttendance(
        dbHelper: dbHelper, accountId: widget.account.id);
    final activity = await dashboardLogic.getLatestActivity(
        dbHelper: dbHelper, accountId: widget.account.id);
    final activityMessage =
        await dashboardLogic.checkEarlyCheckOut(dbHelper, widget.account);
    final checkLate =
        await dashboardLogic.checkIfLate(dbHelper, widget.account);

    setState(() {
      latestAttendance = attendance;
      latestActivity = activity;
      // checkOutEarly = activityMessage;
      // isLate = checkLate;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      drawer: _dashboardDrawer.buildDashboardDrawer(
          context: context,
          account: widget.account,
          systemSettings: widget.systemSettings,
          geolocatorService: _geolocatorService,
          checkEarlyCheckOut: checkEarlyCheckOut,
          locationLat: locationLat,
          locationLong: locationLong),
      body: isLoading
          ? Center(
              child: const CircularProgressIndicator(),
            )
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
                          roleReadableFormat(widget.account.role),
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
                  // Remarks Section
                  // if (checkOutEarly != null || isLate != null) _buildRemarks(),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to Attendance History
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => AttendanceRecords(
                                        account: widget.account)));
                          },
                          icon: const Icon(
                            Icons.fact_check,
                            color: Colors.white,
                          ),
                          label: const Text("History"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to Daily Activity
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ActivityLogs(account: widget.account)));
                          },
                          icon: const Icon(
                            Icons.today,
                            color: Colors.white,
                          ),
                          label: const Text("Activity"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.teal.shade500,
                            foregroundColor: Colors.white,
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                Text(
                  "${statusLogic(latestAttendance!)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor(latestAttendance!),
                  ),
                ),
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
                Text(
                  activityLogic(latestAttendance!, latestActivity!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildRemarks() => Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Remarks",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // if (checkOutEarly != null)
            Text(
              "Given Reason (Checking Out Early): ", // Function to return message
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            // if (checkOutEarly != null)
            Text(
              "",
              // "${checkOutEarly?.message!}", // Function to return message
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            // if (isLate != null)
            Text(
              "Late:", // Function to return message
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            // if (isLate != null)
            Text(
              "",
              // "${isLate?.message!}", // Function to return message
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );

  String roleReadableFormat(String role) {
    switch (role) {
      case "super_admin":
        return "Super Admin";
      case "admin":
        return "Admin";
      case "security":
        return "Security";
      default:
        return "Viewer";
    }
  }
}
