import 'package:created_by_618_abdo/account_dashboard.dart';
import 'package:flutter/material.dart';

import '../Login/LoginPage.dart';
import '../activity_logs/activity_logs.dart';
import '../attendance_dashboard/attendance_dashboard.dart';
import '../attendance_history/attendance_records.dart';
import '../attendance_marking/take_attendance.dart';
import '../geolocator/geolocator_service.dart';
import '../manage_accounts/manage_accounts.dart';
import '../manage_system_settings/manage_settings.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/setting.dart';
import '../registration/register_attendance.dart';

class DashboardDrawer {
  void _navigateTo(BuildContext context, Widget routeName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => routeName),
    );
  }

  Drawer buildDashboardDrawer({
    required BuildContext context,
    required Account account,
    required List<Setting> systemSettings,
    required GeolocatorService geolocatorService,
    required Future<Activity?> Function() checkEarlyCheckOut,
    required double locationLat,
    required double locationLong,
  }) =>
      Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Center(
                  child: Text(
                    "Quick Access",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26.0,
                      color: Colors.white,
                    ),
                  ),
                )),
            if (account.role == 'super_admin' || account.role == 'admin')
              _drawerTile(
                icon: Icons.person,
                label: "Account Registration",
                color: Colors.blue.shade600,
                onTap: () => _navigateTo(
                  context,
                  RegisterAttendance(
                    account: account,
                    systemSettings: systemSettings,
                  ),
                ),
              ),
            if (account.role == 'super_admin' ||
                account.role == 'admin' ||
                account.role == 'security')
              _drawerTile(
                icon: Icons.security,
                label: "Attendance Marking",
                color: Colors.red.shade600,
                onTap: () async {
                  Navigator.pop(context); // Close drawer
                  final isNearby = await geolocatorService.isWithinRange(
                    targetLat: locationLat,
                    targetLng: locationLong,
                  );
                  if (!isNearby) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "You are not within the allowed location to access this feature."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final Activity? checkoutEarly = await checkEarlyCheckOut();
                  if (checkoutEarly?.message == null) {
                    _navigateTo(
                        context,
                        TakeAttendance(
                          systemSettings: systemSettings,
                        ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "Already checked out today. Please talk to Admin."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            if (account.role == 'super_admin' || account.role == 'viewer')
              _drawerTile(
                icon: Icons.assignment,
                label: "Attendance Dashboard",
                color: Colors.indigo.shade600,
                onTap: () => _navigateTo(
                  context,
                  AttendanceDashboard(
                    account: account,
                    systemSettings: systemSettings,
                  ),
                ),
              ),
            if (account.role == 'super_admin' || account.role == 'viewer')
              _drawerTile(
                icon: Icons.settings,
                label: "System Settings",
                color: Colors.cyan.shade600,
                onTap: () => _navigateTo(
                  context,
                  ManageSettings(
                    account: account,
                  ),
                ),
              ),
            if (account.role == 'super_admin' || account.role == 'viewer')
              _drawerTile(
                icon: Icons.access_alarm,
                label: "Daily Activity Logs",
                color: Colors.teal.shade600,
                onTap: () => _navigateTo(
                  context,
                  ActivityLogs(account: account),
                ),
              ),
            if (account.role == 'super_admin' || account.role == 'viewer')
              _drawerTile(
                icon: Icons.calendar_month,
                label: "Attendance History",
                color: Colors.green.shade600,
                onTap: () => _navigateTo(
                  context,
                  AttendanceRecords(account: account),
                ),
              ),
            if (account.role == 'super_admin' || account.role == 'viewer')
              _drawerTile(
                icon: Icons.calendar_month,
                label: "Temp Dashboard",
                color: Colors.green.shade600,
                onTap: () => _navigateTo(
                  context,
                  AccountDashboard(
                    account: account,
                    systemSettings: systemSettings,
                  ),
                ),
              ),
            if (account.role == 'super_admin' || account.role == 'admin')
              _drawerTile(
                icon: Icons.manage_accounts,
                label: "Manage Accounts",
                color: Colors.amber.shade600,
                onTap: () => _navigateTo(
                  context,
                  ManageAccounts(
                    account: account,
                    systemSettings: systemSettings,
                  ),
                ),
              ),
            _drawerTile(
              icon: Icons.logout,
              label: "Logout",
              color: Colors.blueGrey.shade600,
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              ),
            ),
          ],
        ),
      );

  Widget _drawerTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color color}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
