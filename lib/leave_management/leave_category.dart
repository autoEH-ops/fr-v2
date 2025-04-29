import 'package:flutter/material.dart';

import '../model/account.dart';
import 'leave_request.dart';

class LeaveCategory extends StatefulWidget {
  final Account account;
  final Future<void> Function()? onRefresh;
  const LeaveCategory({super.key, required this.account, this.onRefresh});

  @override
  State<LeaveCategory> createState() => _LeaveCategoryState();
}

class _LeaveCategoryState extends State<LeaveCategory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Categories'),
      ),
      body: ListView(
        children: [
          _buildLeaveTile(
            context,
            title: 'Annual Leave',
            icon: Icons.calendar_today,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => LeaveRequest(
                          account: widget.account,
                          leaveType: 'annual_leave',
                          onRefresh: widget.onRefresh,
                        )),
              );
            },
          ),
          _buildLeaveTile(
            context,
            title: 'Medical Leave',
            icon: Icons.local_hospital,
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const MedicalLeavePage()),
              // );
            },
          ),
          _buildLeaveTile(
            context,
            title: 'Emergency Leave',
            icon: Icons.warning,
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const EmergencyLeavePage()),
              // );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTile(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(icon, color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
