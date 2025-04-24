import 'package:flutter/material.dart';

import '../attendance_marking/take_attendance.dart';
import '../geolocator/geolocator_service.dart';
import '../model/activity.dart';
import '../model/setting.dart';

class Fab {
  void _navigateTo(BuildContext context, Widget routeName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => routeName),
    );
  }

  Widget buildFab(
          {required BuildContext context,
          required List<Setting> systemSettings,
          required GeolocatorService geolocatorService,
          required Future<Activity?> Function() checkEarlyCheckOut,
          required double locationLat,
          required double locationLong,
          required double approximateRange}) =>
      FloatingActionButton(
        onPressed: () async {
          final isNearby = await geolocatorService.isWithinRange(
            targetLat: locationLat,
            targetLng: locationLong,
            rangeInMeters: approximateRange,
          );

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

          final Activity? checkoutEarly = await checkEarlyCheckOut();
          debugPrint("get here");
          if (checkoutEarly?.message == null) {
            _navigateTo(
                context,
                TakeAttendance(
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
        // onPressed: () => _onFabPressed(
        //     context: context,
        //     systemSettings: systemSettings,
        //     geolocatorService: geolocatorService,
        //     checkEarlyCheckOut: checkEarlyCheckOut,
        //     locationLat: locationLat,
        //     locationLong: locationLong,
        //     approximateRange: approximateRange),
        backgroundColor: Colors.indigo.shade600,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.face, size: 28, color: Colors.white),
      );
}
