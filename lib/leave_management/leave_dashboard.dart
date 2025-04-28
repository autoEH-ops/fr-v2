import 'package:flutter/material.dart';

import 'leave_category.dart';

class LeaveDashboard extends StatefulWidget {
  const LeaveDashboard({super.key});

  @override
  State<LeaveDashboard> createState() => _LeaveDashboardState();
}

class _LeaveDashboardState extends State<LeaveDashboard> {
  // Dummy list of leave requests (you'll replace this with your real data)
  final List<Map<String, dynamic>> leaveRequests = const [
    {
      'leaveType': 'Annual Leave',
      'startDate': '2025-05-01',
      'endDate': '2025-05-03',
      'status': 'Approved',
    },
    {
      'leaveType': 'Sick Leave',
      'startDate': '2025-05-05',
      'endDate': '2025-05-06',
      'status': 'Pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Big Apply Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to Apply Leave Page or show form
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaveCategory()),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Apply for Leave',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Leave Requests List
            Expanded(
              child: ListView.builder(
                itemCount: leaveRequests.length,
                itemBuilder: (context, index) {
                  final leave = leaveRequests[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.beach_access),
                      title: Text(leave['leaveType']),
                      subtitle: Text(
                          'From: ${leave['startDate']} To: ${leave['endDate']}'),
                      trailing: Text(
                        leave['status'],
                        style: TextStyle(
                          color: leave['status'] == 'Approved'
                              ? Colors.green
                              : (leave['status'] == 'Rejected'
                                  ? Colors.red
                                  : Colors.orange),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
