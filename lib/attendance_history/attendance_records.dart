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
  Map<String, int> attendanceStats = {
    "Fine": 0,
    "Late": 0,
    "Absent": 0,
    "Left Early": 0,
  };
  bool _isLoading = true;

  @override
  initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadAttendances = await recordsLogic.getAllAttendanceCurrentMonth(
        dbHelper, widget.account);
    setState(() {
      attendances = loadAttendances;
      attendanceStats = recordsLogic.getAttendanceStatistics(
          attendances,
          DateTime.now().year.toInt(),
          DateTime.now().month.toInt(),
          widget.account);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedAttendances = recordsLogic.groupAttendancesByDate(attendances);

    return Scaffold(
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : attendances.isEmpty
              ? const Center(
                  child: Text("No attendances found."),
                )
              : Column(
                  children: [
                    Text(
                      recordsLogic.formatMonthAndYear(),
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard('Fine', attendanceStats["Fine"] ?? -5,
                              Colors.green),
                          _buildStatCard('Late', attendanceStats["Late"] ?? -5,
                              Colors.orange),
                          _buildStatCard('Absent',
                              attendanceStats["Absent"] ?? -5, Colors.red),
                          _buildStatCard(
                              'Left Early',
                              attendanceStats["Left Early"] ?? -5,
                              Colors.purple),
                        ],
                      ),
                    ),
                    // Attendance List
                    Text(
                      "Upcoming",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),

                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: attendances
                          .where((att) => att.attendanceStatus == 'on_leave')
                          .length,
                      itemBuilder: (context, index) {
                        Text("$index");
                      },
                    ),

                    Text(
                      "Attendance List",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedAttendances.length,
                        itemBuilder: (context, index) {
                          final entry =
                              groupedAttendances.entries.elementAt(index);
                          final checkIn = entry.value['check_in'];
                          final checkOut = entry.value['check_out'];

                          final dateTimeInfo = recordsLogic
                              .formatAttendanceTime(checkIn, checkOut);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatCard(String title, int count, Color baseColor) {
    final Color bgColor = baseColor;
    final Color textColor = Colors.white;

    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: bgColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
