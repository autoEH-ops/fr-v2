import 'package:created_by_618_abdo/attendance_history/attendance_records.dart';
import 'package:flutter/material.dart';
import '../activity_logs/activity_logs.dart';
import '../admin/admin_dashboard.dart';
import '../db/supabase_db_helper.dart';
import '../geolocator/geolocator_service.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/attendance.dart';
import '../model/setting.dart';
import '../request_changes/request_status.dart';
import '../widget/dashboard_drawer.dart';
import '../widget/fab.dart';
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
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  List<String> pageTitles = [];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _appBarTitle = pageTitles[index];
    });
    _pageController.jumpToPage(index);
  }

  final DashboardLogic dashboardLogic = DashboardLogic();
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  Attendance? latestAttendance;
  Activity? latestActivity;
  Activity? checkOutEarly;
  Activity? isLate;
  bool isLoading = true;
  String _appBarTitle = "Attendance Dashboard";
  String conditionalTitle() {
    if (widget.account.role == "super_admin" ||
        widget.account.role == "admin") {
      return "View Employee Activity";
    }
    return "Approval";
  }

  late Activity? activity;
  double locationLat = 0.0;
  double locationLong = 0.0;
  double approximateRange = 0.0;
  final GeolocatorService _geolocatorService = GeolocatorService();
  final DashboardDrawer _dashboardDrawer = DashboardDrawer();
  final Fab _fab = Fab();

  @override
  void initState() {
    super.initState();
    pageTitles = [
      'Attendance Dashboard',
      'Attendance Records',
      'Daily Logs',
      conditionalTitle()
    ];
    loadLatestData();
    locationLat = double.parse(widget.systemSettings[0].value);
    locationLong = double.parse(widget.systemSettings[1].value);
    approximateRange = double.parse(widget.systemSettings[2].value);
  }

  Future<Activity?> checkEarlyCheckOut() async {
    activity = await dbHelper.getActivityRowWhere(
        'activities', widget.account, DateTime.now(), Activity.fromMap);
    return activity;
  }

  String statusLogic(Attendance? attendance) {
    String status = attendance!.attendanceStatus;

    if (status == "check_in") {
      return "Check In";
    }
    return "Check Out";
  }

  String activityLogic(Attendance attendance, Activity activity) {
    String status = attendance.attendanceStatus;

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
      checkOutEarly = activityMessage;
      isLate = checkLate;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(_appBarTitle),
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
          locationLong: locationLong,
          approximateRange: approximateRange),
      floatingActionButton: _fab.buildFab(
          context: context,
          systemSettings: widget.systemSettings,
          geolocatorService: _geolocatorService,
          checkEarlyCheckOut: checkEarlyCheckOut,
          locationLat: locationLat,
          locationLong: locationLong,
          approximateRange: approximateRange,
          account: widget.account),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 12,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home_rounded,
                  size: 28,
                  color: _selectedIndex == 0
                      ? Colors.indigo
                      : Colors.grey.shade400,
                ),
                onPressed: () => _onItemTapped(0),
              ),
              IconButton(
                icon: Icon(
                  Icons.fact_check_rounded,
                  size: 28,
                  color: _selectedIndex == 1
                      ? Colors.indigo
                      : Colors.grey.shade400,
                ),
                onPressed: () => _onItemTapped(1),
              ),
              const SizedBox(
                width: 26,
              ),
              IconButton(
                icon: Icon(
                  Icons.today,
                  size: 28,
                  color: _selectedIndex == 2
                      ? Colors.indigo
                      : Colors.grey.shade400,
                ),
                onPressed: () => _onItemTapped(2),
              ),
              IconButton(
                icon: Icon(
                  widget.account.role == 'super_admin' ||
                          widget.account.role == 'super_admin'
                      ? Icons.visibility
                      : Icons.assignment,
                  size: 28,
                  color: _selectedIndex == 3
                      ? Colors.indigo
                      : Colors.grey.shade400,
                ),
                onPressed: () => _onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: const CircularProgressIndicator(),
            )
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SingleChildScrollView(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.email,
                                          color: Colors.grey),
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
                                      const Icon(Icons.phone,
                                          color: Colors.grey),
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
                      if (checkOutEarly != null || isLate != null)
                        _buildRemarks(),
                    ],
                  ),
                ),
                AttendanceRecords(account: widget.account),
                ActivityLogs(account: widget.account),
                widget.account.role == 'super_admin' ||
                        widget.account.role == 'super_admin'
                    ? AdminDashboard(
                        account: widget.account,
                        systemSettings: widget.systemSettings,
                      )
                    : RequestStatus(account: widget.account),
              ],
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
        child: latestAttendance != null && latestActivity != null
            ? Row(
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
                        "${statusLogic(latestAttendance)}",
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
              )
            : Center(child: Text("Please check in first.")),
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
            if (isLate != null)
              Text(
                "Late: ", // Function to return message
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            if (isLate != null)
              Text(
                "Check in on ${dashboardLogic.formatTime(isLate!.activityTime!)}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            const SizedBox(height: 8),
            if (checkOutEarly != null)
              Text(
                "Checking Out Early: ", // Function to return message
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            if (checkOutEarly != null)
              Text(
                "Reasoning - ${checkOutEarly!.message}", // Function to return message
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
