import 'package:flutter/material.dart';
import '../activity_logs/activity_logs.dart';
import '../admin/admin_dashboard.dart';
import '../attendance_history/attendance_records.dart';
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
import 'information_page.dart';

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
  List<Attendance> latestAttendance = [];
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

  Future<void> loadLatestData() async {
    final attendance = await dashboardLogic.fetchTodayAttendance(
        dbHelper: dbHelper, account: widget.account);
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
        fetchTodayAttendance: dashboardLogic.fetchTodayAttendance(
            dbHelper: dbHelper, account: widget.account),
        account: widget.account,
      ),
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
                InformationPage(
                  account: widget.account,
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
}
