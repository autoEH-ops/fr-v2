import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../geolocator/geolocator_service.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/setting.dart';
import '../widget/dashboard_drawer.dart';

class AdminDashboard extends StatefulWidget {
  final Account account;
  final List<Setting> systemSettings;
  const AdminDashboard(
      {super.key, required this.account, required this.systemSettings});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Activity? activity;
  double locationLat = 0.0;
  double locationLong = 0.0;
  final dbHelper = SupabaseDbHelper();
  final GeolocatorService _geolocatorService = GeolocatorService();
  final DashboardDrawer _dashboardDrawer = DashboardDrawer();

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
      drawer: _dashboardDrawer.buildDashboardDrawer(
          context: context,
          account: widget.account,
          systemSettings: widget.systemSettings,
          geolocatorService: _geolocatorService,
          checkEarlyCheckOut: checkEarlyCheckOut,
          locationLat: locationLat,
          locationLong: locationLong),
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
          ],
        ),
      ),
    );
  }
}
