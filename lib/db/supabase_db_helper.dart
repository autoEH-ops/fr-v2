import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/account.dart';

class SupabaseDbHelper {
  final supabase = Supabase.instance.client;

  Future<void> insert(String table, Map<String, dynamic> row) async {
    try {
      await supabase.from(table).insert(row);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<T>> getAllRows<T>(
    String table,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    try {
      final response = await supabase.from(table).select();
      return (response as List)
          .map((row) => fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getRowCount(String table) async {
    try {
      final response =
          await supabase.from(table).select('*').count(CountOption.exact);
      return response.count;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> update(
      String table, dynamic id, Map<String, dynamic> row) async {
    try {
      await supabase.from(table).update(row).eq('id', id).select();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateWhere(String table, String fieldName, dynamic fieldValue,
      Map<String, dynamic> row) async {
    try {
      final data = await supabase
          .from(table)
          .update(row)
          .eq(fieldName, fieldValue)
          .select();
      debugPrint("This is the updated data: $data");
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUuid(
      String table, String id, Map<String, dynamic> row) async {
    try {
      await supabase.from(table).update(row).eq('id', id).select();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String table, int id) async {
    try {
      await supabase.from(table).delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMultiple<T>(
      {required String table,
      required List<T> ids,
      required String fieldName}) async {
    try {
      if (ids.isNotEmpty) {
        await supabase.from(table).delete().inFilter(fieldName, ids);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<T?> getRowByField<T>(
    String table,
    String fieldName,
    dynamic fieldValue,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    try {
      final response = await supabase
          .from(table)
          .select()
          .eq(fieldName, fieldValue)
          .maybeSingle();
      if (response != null) {
        return fromMap(response);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<T?> getLatestRowByField<T>({
    required String table,
    required String fieldName,
    required dynamic fieldValue,
    required String orderByField, // e.g., 'attendance_time'
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    // Format date to just the date part for comparison
    try {
      final response = await supabase
          .from(table)
          .select()
          .eq(fieldName, fieldValue)
          .order(orderByField, ascending: false) // Sort by latest
          .limit(1) // Only the latest one
          .maybeSingle();

      if (response != null) {
        return fromMap(response);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<T>> getRowsWhereField<T>(
    String table,
    String fieldName,
    dynamic fieldValue,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    try {
      final response =
          await supabase.from(table).select().eq(fieldName, fieldValue);

      return (response as List)
          .map((row) => fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<T?> getActivityRowWhere<T>(
    String table,
    Account account,
    DateTime date,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    try {
      // Format date to just the date part for comparison
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final response = await supabase
          .from(table)
          .select()
          .not('message', 'eq', null)
          .eq('account_id', account.id!)
          .gte('activity_time', startOfDay.toIso8601String())
          .lt('activity_time', endOfDay.toIso8601String())
          .maybeSingle();

      if (response != null) {
        return fromMap(response);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<T?> getRowIfLateWhere<T>(
    String table,
    Account account,
    DateTime date,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    try {
      // Format date to just the date part for comparison
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final response = await supabase
          .from(table)
          .select()
          .eq('is_late', true)
          .eq('account_id', account.id!)
          .gte('activity_time', startOfDay.toIso8601String())
          .lt('activity_time', endOfDay.toIso8601String())
          .maybeSingle();

      if (response != null) {
        return fromMap(response);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<T>> getRowsWhereFieldForCurrentMonth<T>({
    required String table,
    required String fieldName,
    required dynamic fieldValue,
    required String dateTimeField, // e.g., 'activity_time'
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

      final response = await supabase
          .from(table)
          .select()
          .eq(fieldName, fieldValue)
          .gte(dateTimeField, startOfMonth.toIso8601String())
          .lt(dateTimeField, startOfNextMonth.toIso8601String());

      return (response as List)
          .map((row) => fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<T?> getRowWhereFieldForCurrentDay<T>({
    required String table,
    required String fieldName,
    required dynamic fieldValue,
    required String dateTimeField, // e.g., 'check_in_time'
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfNextDay = startOfDay.add(const Duration(days: 1));

      final response = await supabase
          .from(table)
          .select()
          .eq(fieldName, fieldValue)
          .gte(dateTimeField, startOfDay.toIso8601String())
          .lt(dateTimeField, startOfNextDay.toIso8601String())
          .maybeSingle();

      if (response != null) {
        return fromMap(response);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<T>> getRowsWhereFieldForCurrentDay<T>({
    required String table,
    required String fieldName,
    required dynamic fieldValue,
    required String dateTimeField, // e.g., 'check_in_time'
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfNextDay = startOfDay.add(const Duration(days: 1));

      final response = await supabase
          .from(table)
          .select()
          .eq(fieldName, fieldValue)
          .gte(dateTimeField, startOfDay.toIso8601String())
          .lt(dateTimeField, startOfNextDay.toIso8601String());

      return (response as List)
          .map((row) => fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<T>> getRowsWhereFieldForUpcoming<T>({
    required String table,
    required String fieldName,
    required dynamic fieldValue,
    required String dateTimeField, // e.g., 'activity_time'
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    try {
      final now = DateTime.now();

      final response = await supabase
          .from(table)
          .select()
          .eq(fieldName, fieldValue)
          .gte(dateTimeField, now.toIso8601String());

      return (response as List)
          .map((row) => fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> insertIntoBucket(String filePath, Uint8List imageBytes) async {
    try {
      await supabase.storage.from('images').uploadBinary(filePath, imageBytes);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> insertAttachmentIntoBucket(
      String bucketName, String filePath, Uint8List imageBytes) async {
    try {
      await supabase.storage
          .from(bucketName)
          .uploadBinary(filePath, imageBytes);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFromBucket(List<String> filePaths) async {
    try {
      if (filePaths.isNotEmpty) {
        await supabase.storage.from('images').remove(filePaths);
      }
      debugPrint("Deleted successfully for: $filePaths");
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateFromBucket(File pickFile, Account account) async {
    String result = account.imageUrl!.split('public/').last;
    String publicPath = 'public/$result';
    try {
      await supabase.storage.from('images').update(
            publicPath,
            pickFile,
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<T>> getRowsForToday<T>({
    required String table,
    required Account account,
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await supabase
          .from(table)
          .select()
          .eq('account_id', account.id!)
          .gte('activity_time', startOfDay.toIso8601String())
          .lt('activity_time', endOfDay.toIso8601String());

      return (response as List)
          .map((row) => fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
