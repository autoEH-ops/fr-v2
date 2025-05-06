import 'package:flutter/material.dart';

import '../admin/admin_dashboard.dart';
import '../login/login_page.dart';
import '../geolocator/geolocator_service.dart';
import '../manage_accounts/manage_accounts.dart';
import '../manage_system_settings/manage_settings.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/setting.dart';
import '../registration/register_attendance.dart';
import '../request_changes/process_request.dart';
import '../request_changes/request_changes.dart';
import '../request_changes/request_status.dart';

class DashboardDrawer {
  void _navigateTo(BuildContext context, Widget routeName) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => routeName),
    );
  }

  Drawer buildDashboardDrawer(
          {required BuildContext context,
          required Account account,
          required List<Setting> systemSettings,
          required GeolocatorService geolocatorService,
          required Future<Activity?> Function() checkEarlyCheckOut,
          required double locationLat,
          required double locationLong,
          required double approximateRange,
          required String ocrDictionary}) =>
      Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Center(
                  child: Text(
                    "Menu",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26.0,
                      color: Colors.white,
                    ),
                  ),
                )),
            if (account.role == 'super_admin' || account.role == 'admin') ...[
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
              _drawerTile(
                  icon: Icons.read_more,
                  label: "Approval",
                  onTap: () => _navigateTo(
                      context,
                      ProcessRequest(
                        account: account,
                      )),
                  color: Colors.indigoAccent.shade400),
              _drawerTile(
                  icon: Icons.manage_accounts,
                  label: "Manage Accounts",
                  onTap: () => _navigateTo(
                        context,
                        ManageAccounts(
                            account: account, systemSettings: systemSettings),
                      ),
                  color: Colors.green),
              _drawerTile(
                  icon: Icons.visibility,
                  label: "View Employee Activity",
                  onTap: () => _navigateTo(
                        context,
                        AdminDashboard(
                            account: account, systemSettings: systemSettings),
                      ),
                  color: Colors.lightBlue),
            ],
            if (account.role != 'admin' && account.role != "super_admin") ...[
              _drawerTile(
                  icon: Icons.read_more,
                  label: "Request Profile Change",
                  onTap: () =>
                      _navigateTo(context, RequestChanges(account: account)),
                  color: Colors.lime.shade600),
              _drawerTile(
                  icon: Icons.read_more,
                  label: "Request Status",
                  onTap: () =>
                      _navigateTo(context, RequestStatus(account: account)),
                  color: Colors.lime.shade600),
            ],
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
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          title: Text(label),
          onTap: onTap,
        ),
        Divider()
      ],
    );
  }
}
