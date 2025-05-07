import 'dart:io';
import 'dart:typed_data';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import 'leave_logic.dart';
import 'leave_request.dart';

class LeaveCategory extends StatefulWidget {
  final Account account;
  final String ocrDictionary;
  final Future<void> Function()? onRefresh;
  const LeaveCategory(
      {super.key,
      required this.account,
      required this.ocrDictionary,
      this.onRefresh});

  @override
  State<LeaveCategory> createState() => _LeaveCategoryState();
}

class _LeaveCategoryState extends State<LeaveCategory> {
  int annualLeaveUsed = 0;
  bool _isLoading = true;
  SupabaseDbHelper dbHelper = SupabaseDbHelper();
  LeaveLogic leaveLogic = LeaveLogic();
  late TextRecognizer textRecognizer;

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadAnnualLeaveUsed = await leaveLogic.fetchAccountAnnualLeave(
        dbHelper: dbHelper, accountId: widget.account.id!);

    setState(() {
      annualLeaveUsed = loadAnnualLeaveUsed;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Categories'),
      ),
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : ListView(
              children: [
                _buildLeaveTile(
                  context,
                  title: 'Annual Leave',
                  subtitle: /*_isLoadingAnnualLeave
                ? 'Loading...'
                : */
                      '$annualLeaveUsed more days',
                  icon: Icons.calendar_today,
                  onTap: () {
                    if (annualLeaveUsed <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Annual leave used up.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LeaveRequest(
                                account: widget.account,
                                title: "Annual Leave",
                                leaveType: 'annual_leave',
                                datePickerConfig: calendarConfigAnnualLeave(),
                                annualLeaveUsed: annualLeaveUsed,
                                onSubmit: onSubmitAnnualLeave,
                                reasons: annualLeaveReasons,
                              )),
                    );
                  },
                ),
                _buildLeaveTile(
                  context,
                  title: 'Medical Leave',
                  icon: Icons.local_hospital,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LeaveRequest(
                                account: widget.account,
                                title: 'Medical Leave',
                                leaveType: 'medical_leave',
                                datePickerConfig: calendarConfigMedicalLeave(),
                                onSubmit: onSubmitMedicalLeave,
                                reasons: medicalLeaveReasons,
                              )),
                    );
                  },
                ),
                _buildLeaveTile(
                  context,
                  title: 'Emergency Leave',
                  icon: Icons.warning,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LeaveRequest(
                                account: widget.account,
                                title: 'Emergency Leave',
                                leaveType: 'emergency_leave',
                                datePickerConfig:
                                    calendarConfigEmergencyLeave(),
                                onSubmit: onSubmitEmergencyLeave,
                                reasons: emergencyLeaveReasons,
                              )),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildLeaveTile(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap,
      String? subtitle}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  CalendarDatePicker2Config calendarConfigAnnualLeave() =>
      CalendarDatePicker2Config(
          firstDate: DateTime.now().add(const Duration(days: 14)),
          currentDate: DateTime.now().add(const Duration(days: 14)),
          lastDate: DateTime(2100),
          calendarType: CalendarDatePicker2Type.range,
          selectableDayPredicate: (DateTime day) {
            return day.weekday != DateTime.sunday;
          });

  Future<bool> onSubmitAnnualLeave({
    required DateTime startDate,
    required DateTime endDate,
    File? selectedImage,
    String reason = '',
  }) async {
    // Upload picture
    String leaveType = "annual_leave";
    String uniqueUrl =
        '${widget.account.email}_${leaveType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    String filePath = 'public/$uniqueUrl';
    Uint8List imageBytes;
    String? attachmentUrl;
    if (selectedImage != null) {
      imageBytes = await selectedImage.readAsBytes();
      attachmentUrl = await leaveLogic.createAttachmentUrlInBucket(
          dbHelper: dbHelper,
          uniqueUrl: uniqueUrl,
          filePath: filePath,
          imageBytes: imageBytes);
    }

    // Create leave request
    await leaveLogic.createLeaveRequest(
        dbHelper: dbHelper,
        startTime: startDate,
        endTime: endDate,
        account: widget.account,
        leaveType: leaveType,
        reason: reason,
        attachmentUrl: attachmentUrl);

    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }

    return false;
  }

  List<String> annualLeaveReasons = [
    "Vacation/Travel",
    "Family Time/Personal Time",
    "Festive Holiday/Religious Celebration",
    "Rest/Recuperation",
    "Family Event (e.g., Wedding, Birthday)",
    "Childcare/School Holiday",
    "Personal Errands",
    "Special Occasion",
    "Other (Please Specify)",
  ];

  CalendarDatePicker2Config calendarConfigMedicalLeave() =>
      CalendarDatePicker2Config(
          firstDate: DateTime.now().subtract(Duration(days: 1)),
          currentDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 2)),
          calendarType: CalendarDatePicker2Type.range,
          selectableDayPredicate: (DateTime day) {
            return day.weekday != DateTime.sunday;
          });

  Future<bool> onSubmitMedicalLeave({
    required DateTime startDate,
    required DateTime endDate,
    File? selectedImage,
    String reason = '',
  }) async {
    // Text Recognition
    final InputImage inputImage = InputImage.fromFile(selectedImage!);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final String extractedText = recognizedText.text.toLowerCase();

    //
    // Upload picture flow
    String leaveType = "medical_leave";
    String uniqueUrl =
        '${widget.account.email}_${leaveType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    String filePath = 'public/$uniqueUrl';
    Uint8List imageBytes;
    String? attachmentUrl;
    imageBytes = await selectedImage.readAsBytes();
    attachmentUrl = await leaveLogic.createAttachmentUrlInBucket(
        dbHelper: dbHelper,
        uniqueUrl: uniqueUrl,
        filePath: filePath,
        imageBytes: imageBytes);
    debugPrint("Attachment URL: $attachmentUrl");
    debugPrint("Start Date: $startDate");
    debugPrint("End Date: $endDate");
    debugPrint("Reason: $reason");
    debugPrint("Image Selected: ${selectedImage.path}");
    List<String> autoApproveKeywords = widget.ocrDictionary.split('|');

    bool shouldAutoApprove = autoApproveKeywords
        .any((keyword) => extractedText.toLowerCase().contains(keyword));

    if (shouldAutoApprove) {
      await leaveLogic.createLeaveRequestAndApproved(
          dbHelper: dbHelper,
          startTime: startDate,
          endTime: endDate,
          account: widget.account,
          leaveType: leaveType,
          reason: reason,
          attachmentUrl: attachmentUrl);
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
      return true;
    } else {
      await leaveLogic.createLeaveRequest(
          dbHelper: dbHelper,
          startTime: startDate,
          endTime: endDate,
          account: widget.account,
          leaveType: leaveType,
          reason: reason,
          attachmentUrl: attachmentUrl);
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
      return false;
    }
  }

  List<String> medicalLeaveReasons = [
    "General Illness",
    "Injury or Accident",
    "Medical Appointment/Check-up",
    "Other (Please Specify)",
  ];

  CalendarDatePicker2Config calendarConfigEmergencyLeave() =>
      CalendarDatePicker2Config(
          firstDate: DateTime.now(),
          currentDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 1)),
          calendarType: CalendarDatePicker2Type.range,
          selectableDayPredicate: (DateTime day) {
            return day.weekday != DateTime.sunday;
          });

  Future<bool> onSubmitEmergencyLeave({
    required DateTime startDate,
    required DateTime endDate,
    File? selectedImage,
    String reason = '',
  }) async {
    // Upload picture
    String leaveType = "emergency_leave";
    String uniqueUrl =
        '${widget.account.email}_${leaveType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    String filePath = 'public/$uniqueUrl';
    Uint8List imageBytes;
    String? attachmentUrl;
    if (selectedImage != null) {
      imageBytes = await selectedImage.readAsBytes();
      attachmentUrl = await leaveLogic.createAttachmentUrlInBucket(
          dbHelper: dbHelper,
          uniqueUrl: uniqueUrl,
          filePath: filePath,
          imageBytes: imageBytes);
    }

    // Create leave request
    await leaveLogic.createLeaveRequest(
        dbHelper: dbHelper,
        startTime: startDate,
        endTime: endDate,
        account: widget.account,
        leaveType: leaveType,
        reason: reason,
        attachmentUrl: attachmentUrl);

    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
    return false;
  }

  List<String> emergencyLeaveReasons = [
    "Family Emergency",
    "Bereavement/Death in Family",
    "Natural Disaster/Weather-Related",
    "Legal Obligation/Court Appearance",
    "Transport Breakdown/Vehicle Accident",
  ];
}
