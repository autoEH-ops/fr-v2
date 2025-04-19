import 'package:location/location.dart';
import 'dart:math';

class GeolocatorService {
  final Location _location = Location();

  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await _location.hasPermission();
      final serviceEnabled = await _location.serviceEnabled();

      if (!serviceEnabled) {
        final serviceRequested = await _location.requestService();
        if (!serviceRequested) return null;
      }

      if (hasPermission == PermissionStatus.denied) {
        final permissionRequested = await _location.requestPermission();
        if (permissionRequested != PermissionStatus.granted) return null;
      }

      await _location.changeSettings(
          accuracy: LocationAccuracy.high, interval: 1000);
      return await _location.getLocation();
    } catch (e) {
      return null;
    }
  }

  // Haversine formula to calculate distance between two lat/long
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // in meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // in meters
  }

  double _degToRad(double degree) {
    return degree * pi / 180;
  }

  /// Returns true if user is within [rangeInMeters] of target location
  Future<bool> isWithinRange({
    required double targetLat,
    required double targetLng,
    double rangeInMeters = 100,
  }) async {
    final location = await getCurrentLocation();
    if (location == null) return false;

    final distance = calculateDistance(
      location.latitude!,
      location.longitude!,
      targetLat,
      targetLng,
    );

    return distance <= rangeInMeters;
  }
}
