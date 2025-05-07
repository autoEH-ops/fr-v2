import 'dart:io';

import 'package:attendance_system_fr_v3/db/supabase_db_helper.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/account.dart';
import 'leave_logic.dart';

class LeaveRequest extends StatefulWidget {
  final Account account;
  final String title;
  final String leaveType;
  final int? annualLeaveUsed;
  final CalendarDatePicker2Config datePickerConfig;
  final List<String> reasons;
  final Future<bool> Function(
      {required DateTime startDate,
      required DateTime endDate,
      File? selectedImage,
      String reason}) onSubmit;

  const LeaveRequest({
    super.key,
    required this.account,
    required this.title,
    required this.leaveType,
    required this.datePickerConfig,
    required this.onSubmit,
    required this.reasons,
    this.annualLeaveUsed,
  });

  @override
  State<LeaveRequest> createState() => _LeaveRequestState();
}

class _LeaveRequestState extends State<LeaveRequest> {
  List<DateTime?> _dates = [];
  LeaveLogic leaveLogic = LeaveLogic();
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final TextEditingController _reasonController = TextEditingController();
  String? selectedReason;

  File? _selectedImage;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _imagePath = image.name;
      });
    }
  }

  Future<void> _submitRequest() async {
    DateTime? startDate = _dates.isNotEmpty ? _dates.first : null;
    DateTime? endDate = _dates.length > 1 ? _dates.last : null;

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick Start Date and End Date.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    int requestedDays = leaveLogic.daysExcludingSundays(startDate, endDate);
    if (widget.leaveType == "annual_leave" &&
        requestedDays > widget.annualLeaveUsed!) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Requested leave exceed amount left: ${widget.annualLeaveUsed} day(s) left"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));

      setState(() {
        _dates = [];
      });
      return;
    }

    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a reason.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (selectedReason == "Other (Please Specify)" &&
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify a reason.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    String reason = selectedReason == "Other (Please Specify)"
        ? _reasonController.text.trim()
        : selectedReason!;

    if (widget.leaveType == "medical_leave" && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Must attached medical document'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool autoApproved = await widget.onSubmit(
        endDate: endDate,
        startDate: startDate,
        selectedImage: _selectedImage,
        reason: reason);

    if (!mounted) return;
    debugPrint("autoApproved bool: $autoApproved");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(autoApproved == true
          ? "Leave auto-approved. Get well soon."
          : "Leave request is pending. Wait for admin approval"),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    DateTime? startDate = _dates.isNotEmpty ? _dates.first : null;
    DateTime? endDate = _dates.length > 1 ? _dates.last : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Leave Dates",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            CalendarDatePicker2(
              config: widget.datePickerConfig,
              value: _dates,
              onValueChanged: (dates) {
                setState(() {
                  _dates = dates;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "Start Date: ${startDate != null ? leaveLogic.formatTimeDayAndYear(startDate) : '-'}",
                    style: const TextStyle(fontSize: 16)),
                Text(
                    "End Date: ${endDate != null ? leaveLogic.formatTimeDayAndYear(endDate) : '-'}",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Reason for Leave",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: widget.reasons
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedReason = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Reason to Leave',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            if (selectedReason == "Other (Please Specify)") ...[
              const SizedBox(height: 12.0),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: 'Enter your reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 30),
            Text(
              "Attachment ${widget.leaveType == "medical_leave" ? "" : "(Optional)"}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _imagePath ?? "No file selected",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload"),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 10),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, height: 150),
                ),
              ),
            ],
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                  shadowColor: Colors.black54,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text(
                  "Submit Request",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
