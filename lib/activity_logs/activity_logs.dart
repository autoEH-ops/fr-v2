import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';
import 'activity_logs_logic.dart';

class ActivityLogs extends StatefulWidget {
  final Account account;
  const ActivityLogs({super.key, required this.account});

  @override
  State<ActivityLogs> createState() => _ActivityLogsState();
}

class _ActivityLogsState extends State<ActivityLogs> {
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final ActivityLogsLogic logsLogic = ActivityLogsLogic();
  List<Activity> activities = [];
  bool _isLoading = true;

  @override
  initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadActivities = await logsLogic.getActivityRowsForToday(
        dbHelper: dbHelper, account: widget.account);
    setState(() {
      activities = loadActivities;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> activityLogs =
        logsLogic.getActivityTimeRanges(activities);

    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : activities.isEmpty
              ? const Center(
                  child: Text("No activities found for today."),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header - Last Updated
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today: ${logsLogic.formatDay(activityLogs.last['end'] as DateTime)}',
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Last update: ${logsLogic.formatTime(activityLogs.last['end'] as DateTime)}',
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // List
                    Expanded(
                      child: ListView.builder(
                        itemCount: activityLogs.length,
                        itemBuilder: (context, index) {
                          final log = activityLogs[index];
                          final start = logsLogic.formatTime(log['start']);
                          final end = logsLogic.formatTime(log['end']);
                          final activity =
                              logsLogic.formatReadableActivity(log['activity']);
                          final color = logsLogic.getActivityColor(activity);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: color, width: 4),
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Time
                                // Timeline dot
                                // Time column
                                Container(
                                  width: 80,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        start,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '-',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 14,
                                        ),
                                      ),
                                      log['activity'] != "early_check_out"
                                          ? Text(
                                              end,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                                fontSize: 14,
                                              ),
                                            )
                                          : Text(
                                              start,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),

                                // Vertical separator
                                Container(
                                  width: 4,
                                  height: 40,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                // Activity Name
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      activity,
                                      style:
                                          theme.textTheme.bodyMedium!.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
