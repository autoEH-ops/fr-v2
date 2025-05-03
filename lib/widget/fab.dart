import 'package:flutter/material.dart';

import '../attendance_marking/take_attendance.dart';
import '../geolocator/geolocator_service.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/attendance.dart';
import '../model/setting.dart';

class Fab {
  void _navigateTo(BuildContext context, Widget routeName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => routeName),
    );
  }

  Widget buildFab({
    required BuildContext context,
    required List<Setting> systemSettings,
    required GeolocatorService geolocatorService,
    required Future<Activity?> Function() checkEarlyCheckOut,
    required Future<List<Attendance>> fetchTodayAttendance,
    required double locationLat,
    required double locationLong,
    required double approximateRange,
    required Account account,
  }) =>
      FloatingActionButton(
        onPressed: () async {
          final isNearby = await geolocatorService.isWithinRange(
            targetLat: locationLat,
            targetLng: locationLong,
            rangeInMeters: approximateRange,
          );
          if (!context.mounted) return;
          if (!isNearby) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "You are not within the allowed location to access this feature."),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final List<Attendance> latestAttendance = await fetchTodayAttendance;
          if (!context.mounted) return;
          if (latestAttendance.isNotEmpty &&
              latestAttendance.first.attendanceStatus == "on_leave") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text("Enjoy your leave. No need to take attendance today."),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final Activity? checkoutEarly = await checkEarlyCheckOut();
          if (!context.mounted) return;
          if (checkoutEarly?.message == null) {
            _navigateTo(
                context,
                TakeAttendance(
                  account: account,
                  systemSettings: systemSettings,
                ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text("Already checked out today. Please talk to Admin."),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        },
        backgroundColor: Colors.indigo.shade600,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.face, size: 28, color: Colors.white),
      );
}
