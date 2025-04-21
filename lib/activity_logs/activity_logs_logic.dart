import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';

class ActivityLogsLogic {
  Future<List<Activity>> getActivityRowsForToday(
      {required SupabaseDbHelper dbHelper, required Account account}) async {
    List<Activity> activities = [];
    try {
      final response = await dbHelper.getRowsForToday<Activity>(
          table: 'activities',
          account: account,
          fromMap: (row) => Activity.fromMap(row));
      activities = response;
    } catch (e) {
      debugPrint("Failed to fetch activities: $e");
      return [];
    }

    return activities;
  }

  List<Map<String, dynamic>> getActivityTimeRanges(List<Activity> activities) {
    List<Map<String, dynamic>> ranges = [];

    for (int i = 0; i < activities.length; i++) {
      final current = activities[i];
      final next = i + 1 < activities.length ? activities[i + 1] : null;

      final start =
          current.activityTime?.add(Duration(hours: 8)) ?? DateTime.now();
      final end = next?.activityTime?.add(Duration(hours: 8)) ?? DateTime.now();

      ranges.add({
        'start': start,
        'end': end,
        'activity': current.activity,
      });
    }

    return ranges;
  }

  Color getActivityColor(String activity) {
    switch (activity.toLowerCase()) {
      case 'work':
        return Colors.green;
      case 'break':
        return Colors.orange;
      case 'meeting':
        return Colors.purple;
      case 'toilet':
        return Colors.blue;
      case 'prayers':
        return Colors.indigo;
      case 'early_check_out':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatTime(DateTime time) => DateFormat('HH:mm').format(time);

  String formatDay(DateTime time) => DateFormat('EEEE, dd MMMM').format(time);

  String formatReadableActivity(String activity) {
    String readableActivity = activity
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
    return readableActivity;
  }
}
