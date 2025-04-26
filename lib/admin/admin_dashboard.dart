import 'dart:ui';

import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/attendance.dart';
import '../model/setting.dart';
import 'admin_logic.dart';

class AdminDashboard extends StatefulWidget {
  final Account account;
  final List<Setting> systemSettings;
  const AdminDashboard(
      {super.key, required this.account, required this.systemSettings});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Attendance> currentAttendances = [];
  List<Account> accounts = [];
  List<Activity> activities = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Account> filteredAccounts = [];
  List<Activity> filteredActivities = [];
  DateTime time = DateTime.now();
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final AdminLogic adminLogic = AdminLogic();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadCurrentAttendances =
        await adminLogic.getAttendanceCurrentDay(dbHelper: dbHelper);

    List<Account> loadAccounts = [];
    for (final attendance in loadCurrentAttendances) {
      final account = await adminLogic.getAccount(
        dbHelper: dbHelper,
        attendance: attendance,
      );
      if (account != null) {
        loadAccounts.add(account);
      }
    }

    List<Activity> loadActivity = [];
    for (final account in loadAccounts) {
      final activity = await adminLogic.getLatestActivity(
          dbHelper: dbHelper, accountId: account.id);
      if (activity != null) {
        loadActivity.add(activity);
      }
    }
    setState(() {
      currentAttendances = loadCurrentAttendances;
      accounts = loadAccounts;
      activities = loadActivity;
      filteredAccounts = loadAccounts;
      filteredActivities = loadActivity;
      _isLoading = false;
    });
  }

  void _filterAccounts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredAccounts = accounts;
        filteredActivities = activities;
      });
    } else {
      final lowerQuery = query.toLowerCase();
      final List<Account> matchedAccounts = [];
      final List<Activity> matchedActivities = [];

      for (int i = 0; i < accounts.length; i++) {
        if (accounts[i].name.toLowerCase().contains(lowerQuery)) {
          matchedAccounts.add(accounts[i]);
          matchedActivities.add(activities[i]);
        }
      }

      setState(() {
        filteredAccounts = matchedAccounts;
        filteredActivities = matchedActivities;
        _searchQuery = query;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _isLoading
            ? Center(child: const CircularProgressIndicator())
            : currentAttendances.isEmpty || activities.isEmpty
                ? const Center(
                    child: Text("No account currently check in."),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today: ${adminLogic.formatYearMonthAndDay(time)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Current Time: ${adminLogic.formatHourAndSecond(time)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterAccounts,
                          decoration: InputDecoration(
                            hintText: 'Search by name...',
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        filteredAccounts = accounts;
                                        filteredActivities = activities;
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: filteredAccounts.isNotEmpty
                              ? ListView.builder(
                                  itemCount: filteredAccounts.length,
                                  itemBuilder: (context, index) {
                                    final account = filteredAccounts[index];
                                    final activity = filteredActivities[index];
                                    return Column(
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 45,
                                              backgroundColor:
                                                  Colors.indigo.shade600,
                                              backgroundImage:
                                                  account.imageUrl != null
                                                      ? NetworkImage(
                                                          account.imageUrl!)
                                                      : null,
                                              child: account.imageUrl == null
                                                  ? Text(
                                                      account.name[0]
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 40,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    account.name,
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    adminLogic.readableString(
                                                        account.role),
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 10,
                                                        height: 10,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: adminLogic
                                                              .getActivityColor(
                                                                  activity
                                                                      .activity), // define role-based colors
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          "${adminLogic.readableString(activity.activity)} since ${adminLogic.formatTime(activity.activityTime!)}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24, thickness: 1),
                                      ],
                                    );
                                  },
                                )
                              : const Center(
                                  child: Text(
                                    'No account with that name found.',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ));
  }
}
