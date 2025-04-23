import 'package:flutter/material.dart';
import 'package:location/location.dart';

import '../db/supabase_db_helper.dart';
import '../geolocator/geolocator_service.dart';
import '../model/account.dart';
import '../model/setting.dart';

class ManageSettingsLogic {
  Future<List<Setting>> getAllSystemSettings(
      {required SupabaseDbHelper dbHelper}) async {
    List<Setting> systemSettings;
    try {
      final response = await dbHelper.getAllRows<Setting>(
          "system_settings", (row) => Setting.fromMap(row));
      systemSettings = response;
    } catch (e) {
      debugPrint("Failed to get system settings: $e");
      systemSettings = [];
    }
    return systemSettings;
  }

  Future<Map<String, double>> getCurrentLatAndLong(
      {required GeolocatorService geolocatorService}) async {
    LocationData? locationData;
    try {
      final response = await geolocatorService.getCurrentLocation();
      locationData = response;
    } catch (e) {
      debugPrint("Failed to get LocationData: $e");
      return {};
    }

    if (locationData != null) {
      final map = {
        'lat': locationData.latitude!,
        'long': locationData.longitude!,
      };
      return map;
    } else {
      return {};
    }
  }

  Future<void> updateSystemSettings(
      {required SupabaseDbHelper dbHelper,
      required List<Setting> systemSettings,
      required List<TextEditingController> controllers,
      required Account account}) async {
    try {
      for (var i = 0; i < systemSettings.length; i++) {
        final updatedValue = controllers[i].text;
        final setting = systemSettings[i];
        setting.value = updatedValue;
        final row = {
          'value': updatedValue,
          'last_updated': DateTime.now().toUtc().toIso8601String(),
          'updated_by': account.id
        };
        await dbHelper.updateUuid('system_settings', setting.id!, row);
      }
    } catch (e) {
      rethrow;
    }
  }

  String formatReadableSetting(String setting) {
    String readableSetting = setting
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
    return readableSetting;
  }
}
