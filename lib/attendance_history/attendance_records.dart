import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/attendance.dart';
import 'records_logic.dart';

class AttendanceRecords extends StatefulWidget {
  final Account account;
  const AttendanceRecords({super.key, required this.account});

  @override
  State<AttendanceRecords> createState() => _AttendanceRecordsState();
}

class _AttendanceRecordsState extends State<AttendanceRecords> {
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final RecordsLogic recordsLogic = RecordsLogic();
  List<Attendance> attendances = [];
  bool _isLoading = true;

  @override
  initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadAttendances =
        await recordsLogic.getAllAttendance(dbHelper, widget.account);
    setState(() {
      attendances = loadAttendances;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedAttendances = recordsLogic.groupAttendancesByDate(attendances);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : attendances.isEmpty
              ? const Center(
                  child: Text("No attendances found."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedAttendances.length,
                  itemBuilder: (context, index) {
                    final entry = groupedAttendances.entries.elementAt(index);
                    final checkIn = entry.value['check_in'];
                    final checkOut = entry.value['check_out'];

                    final dateTimeInfo =
                        recordsLogic.formatAttendanceTime(checkIn, checkOut);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Colored Day+Month box
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "${dateTimeInfo['day']}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    "${dateTimeInfo['month']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Check In
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Check In',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                                const SizedBox(height: 4),
                                Text("${dateTimeInfo["checkIn"]}"),
                              ],
                            ),

                            // Check Out
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Check Out',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red)),
                                const SizedBox(height: 4),
                                Text("${dateTimeInfo["checkOut"]}"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
