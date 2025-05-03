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
  String ocrDictionary = "";
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
    for (final setting in widget.systemSettings) {
      switch (setting.setting) {
        case 'location_lat':
          locationLat = double.parse(setting.value);
          break;
        case 'location_long':
          locationLong = double.parse(setting.value);
          break;
        case 'approximate_range':
          approximateRange = double.parse(setting.value);
          break;
        case 'ocr_dictionary':
          ocrDictionary = setting.value;
          break;
      }
    }
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
          approximateRange: approximateRange,
          ocrDictionary: ocrDictionary),
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
                InformationPage(account: widget.account),
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
}
