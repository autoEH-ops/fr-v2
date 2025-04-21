import 'package:created_by_618_abdo/attendance_dashboard/attendance_dashboard.dart';
import 'package:created_by_618_abdo/attendance_marking/take_attendance.dart';

import '../registration/register_attendance.dart';
import 'Login/LoginPage.dart';
import 'activity_logs/activity_logs.dart';
import 'attendance_history/attendance_records.dart';
import 'db/supabase_db_helper.dart';
import 'geolocator/geolocator_service.dart';
import 'manage_accounts/manage_accounts.dart';
import 'model/activity.dart';
import 'package:flutter/material.dart';
import 'model/account.dart';
import 'model/setting.dart';

class AccountDashboard extends StatefulWidget {
  final Account account;
  final List<Setting> systemSettings;
  const AccountDashboard(
      {super.key, required this.account, required this.systemSettings});

  @override
  State<AccountDashboard> createState() => _AccountDashboardState();
}

class _AccountDashboardState extends State<AccountDashboard> {
  late Activity? activity;
  double locationLat = 0.0;
  double locationLong = 0.0;
  final dbHelper = SupabaseDbHelper();
  final GeolocatorService _geolocatorService = GeolocatorService();

  @override
  void initState() {
    super.initState();
    locationLat = double.parse(widget.systemSettings[0].value);
    locationLong = double.parse(widget.systemSettings[1].value);
  }

  Future<Activity?> checkEarlyCheckOut() async {
    activity = await dbHelper.getActivityRowWhere(
        'activities', widget.account, DateTime.now(), Activity.fromMap);
    return activity;
  }

  void _navigateTo(BuildContext context, Widget routeName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => routeName),
    );
  }

  String readableRole(String role) {
    return role
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${readableRole(widget.account.role)} Dashboard',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 6,
        shadowColor: const Color.fromRGBO(33, 150, 243, 0.4),
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade600,
                    Colors.blue.shade400,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(33, 150, 243, 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  widget.account.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5.0),
                    Text(
                      'Role: ${readableRole(widget.account.role)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromRGBO(255, 255, 255, 0.9),
                      ),
                    ),
                    Text(
                      'Email: ${widget.account.email}',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromRGBO(255, 255, 255, 0.9),
                      ),
                    ),
                    Text(
                      'Phone: ${widget.account.phone}',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromRGBO(255, 255, 255, 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Access Section
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                "Quick Access",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade800,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (widget.account.role == 'super_admin' ||
                      widget.account.role == 'admin')
                    _buildAccessCard(
                        icon: Icons.person,
                        title: "Account Registration",
                        subtitle: "Register new accounts",
                        color: Colors.blue.shade600,
                        onTap: () => _navigateTo(
                            context,
                            RegisterAttendance(
                                account: widget.account,
                                systemSettings: widget.systemSettings))),
                  if (widget.account.role == 'super_admin' ||
                      widget.account.role == 'admin' ||
                      widget.account.role == 'security')
                    _buildAccessCard(
                      icon: Icons.security,
                      title: "Attendance Marking",
                      subtitle: "Mark Your Attendance",
                      color: Colors.green.shade600,
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        try {
                          final isNearby =
                              await _geolocatorService.isWithinRange(
                                  targetLat: locationLat,
                                  targetLng: locationLong);

                          if (!isNearby) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "You are not within the allowed location to access this feature."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final Activity? checkoutEarly =
                              await checkEarlyCheckOut();

                          Navigator.of(context).pop();

                          if (checkoutEarly?.message == null) {
                            _navigateTo(context, TakeAttendance());
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Already checked out today. Please talk to the Admin if this is a mistake.",
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          Navigator.of(context)
                              .pop(); // Ensure dialog is removed on error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Something went wrong. Please try again."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  if (widget.account.role == 'super_admin' ||
                      widget.account.role == 'viewer')
                    _buildAccessCard(
                      icon: Icons.assignment,
                      title: "Attendance Dashboard",
                      subtitle: "All about attendance here.",
                      color: Colors.red.shade600,
                      onTap: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AttendanceDashboard(
                                    account: widget.account)));
                      },
                    ),
                  if (widget.account.role == 'super_admin' ||
                      widget.account.role == 'viewer')
                    _buildAccessCard(
                      icon: Icons.access_alarm,
                      title: "Daily Activity Logs",
                      subtitle: "Daily logs of activity during work",
                      color: Colors.indigo.shade600,
                      onTap: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ActivityLogs(account: widget.account)));
                      },
                    ),
                  if (widget.account.role == 'super_admin' ||
                      widget.account.role == 'viewer')
                    _buildAccessCard(
                      icon: Icons.calendar_month,
                      title: "Attendance History",
                      subtitle: "History of attendance",
                      color: Colors.teal.shade600,
                      onTap: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AttendanceRecords(
                                    account: widget.account)));
                      },
                    ),
                  if (widget.account.role == 'super_admin' ||
                      widget.account.role == 'admin')
                    _buildAccessCard(
                      icon: Icons.manage_accounts,
                      title: "Manage Accounts",
                      subtitle: "Create, Update, and Delete Accounts",
                      color: Colors.indigo.shade600,
                      onTap: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ManageAccounts(
                                    account: widget.account,
                                    systemSettings: widget.systemSettings)));
                      },
                    ),
                  if (widget.account.role == 'super_admin' ||
                      widget.account.role == 'viewer')
                    _buildAccessCard(
                      icon: Icons.logout,
                      title: "Logout",
                      subtitle: "Sign out and return to login screen",
                      color: Colors.yellow.shade600,
                      onTap: () async {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                            (Route<dynamic> route) => false);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
