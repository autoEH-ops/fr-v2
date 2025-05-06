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
  List<Attendance> upcomings = [];
  Map<String, int> attendanceCount = {};
  bool _isLoading = true;

  @override
  initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadAttendances = await recordsLogic.getAllAttendanceCurrentMonth(
        dbHelper, widget.account);
    final loadUpcomings = await recordsLogic.fetchUpcomingOnLeave(
        account: widget.account, dbHelper: dbHelper);

    final loadAttendanceCount = await recordsLogic.getAttendanceStatistics(
        dbHelper: dbHelper, account: widget.account);
    setState(() {
      attendances = loadAttendances;
      upcomings = loadUpcomings;
      attendanceCount = loadAttendanceCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Map<String, dynamic>> groupedAttendances =
        recordsLogic.groupAttendancesByDate(attendances);
    groupedAttendances = Map.fromEntries(groupedAttendances.entries.toList()
      ..sort((a, b) => DateTime.parse(a.key).compareTo(DateTime.parse(b.key))));
    final upcomingLeaves = upcomings
        .where((a) => a.attendanceStatus == "on_leave" && a.leaveId != null)
        .toList();
    final filteredUpcoming = upcomingLeaves.where((attendance) {
      return attendance.attendanceTime!.isAfter(DateTime.now());
    }).toList();
    return Scaffold(
        body: _isLoading
            ? Center(child: const CircularProgressIndicator())
            : attendances.isEmpty
                ? const Center(
                    child: Text("No attendances found."),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 32), // prevent content cutoff
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            recordsLogic.formatMonthAndYear(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatCard('Fine',
                                      attendanceCount['fine']!, Colors.green),
                                  _buildStatCard(
                                      'Late',
                                      attendanceCount['late']!,
                                      Colors.amberAccent),
                                  _buildStatCard('Absent',
                                      attendanceCount['absent']!, Colors.red),
                                  _buildStatCard(
                                      'Left Early',
                                      attendanceCount["left_early"]!,
                                      Colors.purple),
                                  _buildStatCard(
                                      'On Leave',
                                      attendanceCount['on_leave']!,
                                      Colors.orange),
                                ]
                                    .map((card) => Padding(
                                          padding:
                                              const EdgeInsets.only(right: 12),
                                          child: SizedBox(
                                              width: 100,
                                              child:
                                                  card), // fixed width for consistent sizing
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          if (filteredUpcoming.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Upcoming",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ),
                            ...filteredUpcoming.map((attendance) {
                              final dateTimeInfo =
                                  recordsLogic.formatUpcomingTime(
                                      attendance.attendanceTime);
                              return _buildUpcomingLeaveCard(dateTimeInfo);
                            })
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text("Attendance List",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          ...groupedAttendances.entries.where((entry) {
                            final entryDate = DateTime.parse(entry.key);
                            return entryDate.isBefore(DateTime.now()) ||
                                entryDate.isAtSameMomentAs(DateTime.now());
                          }).map((entry) {
                            final checkIn = entry.value['check_in'];
                            final checkOut = entry.value['check_out'];
                            final onLeave = entry.value['on_leave'];
                            final absent = entry.value['absent'];
                            final upcoming = recordsLogic
                                .formatUpcomingTime(DateTime.parse(entry.key));
                            final dateTimeInfo = recordsLogic
                                .formatAttendanceTime(checkIn, checkOut);
                            return _buildAttendanceCard(
                                dateTimeInfo, onLeave, upcoming, absent);
                          }),
                        ],
                      ),
                    ),
                  ));
  }

  Widget _buildAttendanceCard(Map<String, dynamic> dateTimeInfo, bool onLeave,
      Map<String, String> upcoming, bool absent) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!onLeave && !absent) ...[
              // Colored Day+Month box
              Container(
                width: 80,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  const Text(
                    'Check In',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("${dateTimeInfo["checkIn"]}"),
                ],
              ),

              // Check Out
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check Out',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("${dateTimeInfo["checkOut"]}"),
                ],
              ),
            ] else ...[
              Container(
                width: 80,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "${upcoming['day']}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      "${upcoming['month']}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // "On Leave" text
              Expanded(
                child: Text(
                  onLeave
                      ? "On Leave"
                      : absent
                          ? "Absent"
                          : "",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: onLeave
                        ? Colors.orange.shade700
                        : absent
                            ? Colors.red
                            : null,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingLeaveCard(Map<String, String> upcoming) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Colored Day+Month box with fixed width
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    "${upcoming['day']}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    "${upcoming['month']}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // "On Leave" text
            Expanded(
              child: Text(
                "On Leave",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
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
