import 'dart:io';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../attendance_dashboard/recognizer.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import 'embedding_logic.dart';
import 'manage_accounts_logic.dart';

class ManageAccount extends StatefulWidget {
  final Account account;
  const ManageAccount({super.key, required this.account});

  @override
  State<ManageAccount> createState() => _ManageAccountState();
}

class _ManageAccountState extends State<ManageAccount> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedRole = 'super_admin';
  late FaceDetector faceDetector;
  late Recognizer recognizer;
  SupabaseDbHelper dbHelper = SupabaseDbHelper();
  ManageAccountsLogic managementLogic = ManageAccountsLogic();
  EmbeddingLogic embeddingLogic = EmbeddingLogic();
  File? _imageFile;
  DateTime? _startDate;
  DateTime? _endDate;

  final Map<String, String> _roles = {
    'super_admin': 'Super Admin',
    'admin': 'Admin',
    'security': 'Security',
    'viewer': 'Viewer',
    'intern': 'Intern'
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _emailController = TextEditingController(text: widget.account.email);
    _phoneController = TextEditingController(text: widget.account.phone);
    _selectedRole = widget.account.role;

    _startDate = widget.account.startDate;
    _endDate = widget.account.endDate;

    final options =
        FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    faceDetector = FaceDetector(options: options);
    recognizer = Recognizer();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _updateEmbedding() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: const Text(
              'Update Embedding',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.blueAccent,
                ),
                icon: const Icon(
                  Icons.upload_file,
                  color: Colors.white,
                ),
                label: const Text(
                  'Upload Image',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  embeddingLogic.pickImageFromGallery(
                      context: context,
                      faceDetector: faceDetector,
                      recognizer: recognizer,
                      dbHelper: dbHelper,
                      name: _nameController.text.trim());
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.green,
                ),
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                ),
                label: const Text(
                  'Live Detection',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  embeddingLogic.showFaceRegistrationDialog(
                      context: context, name: _nameController.text.trim());
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.red,
                ),
                icon: const Icon(
                  Icons.cancel,
                  color: Colors.white,
                ),
                label: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateAccount() async {
    Map<String, dynamic> row = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'phone': _phoneController.text.trim(),
      'start_date':
          _startDate!.toUtc().add(Duration(hours: 16)).toIso8601String(),
      'end_date': widget.account.role == "intern"
          ? _endDate!.toUtc().add(Duration(hours: 16)).toIso8601String()
          : null,
    };
    if (_imageFile != null) {
      await dbHelper.updateFromBucket(_imageFile!, widget.account);
      debugPrint("Sucessful in replacing image");
    }
    try {
      await managementLogic.updateAccountInformation(
          account: widget.account, dbHelper: dbHelper, row: row);
      setState(() {
        widget.account.name = _nameController.text.trim();
        widget.account.email = _emailController.text.trim();
        widget.account.role = _selectedRole;
        widget.account.phone = _phoneController.text.trim();
        widget.account.startDate = _startDate!;
        if (widget.account.role == "intern") {
          widget.account.endDate = _endDate;
        }
      });
    } catch (e) {
      debugPrint('Update error: $e');
    } finally {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Account updated. Updated photo will take time to process and take effect')),
        );

        Navigator.pop(context, widget.account);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Account Information"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueAccent,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : NetworkImage(widget.account.imageUrl!),
                      child: widget.account.imageUrl == null
                          ? Text(
                              widget.account.name.isNotEmpty
                                  ? widget.account.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: _roles.entries
                  .map((entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedRole = value);
              },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 16),
            Text(
              "Start Date",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            _buildSingleDatePicker(
              label: 'Start Date',
              selectedDate: _startDate,
              onDateSelected: (date) => setState(() => _startDate = date),
            ),
            const SizedBox(height: 16),
            if (widget.account.role == 'intern') ...[
              Text(
                "End Date",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              _buildSingleDatePicker(
                label: 'End Date',
                selectedDate: _endDate,
                onDateSelected: (date) => setState(() => _endDate = date),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _updateEmbedding,
              child: const Text('Embedding'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _updateAccount,
              child: const Text('Update Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleDatePicker({
    required String label,
    required DateTime? selectedDate,
    required void Function(DateTime?) onDateSelected,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final result = await showCalendarDatePicker2Dialog(
                context: context,
                config: CalendarDatePicker2WithActionButtonsConfig(
                  calendarType: CalendarDatePicker2Type.single,
                ),
                dialogSize: const Size(325, 400),
                value: [selectedDate],
                borderRadius: BorderRadius.circular(15),
              );

              if (result != null && result.isNotEmpty) {
                onDateSelected(result.first);
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.calendar_today, color: Colors.blueAccent),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              selectedDate != null
                  ? DateFormat('E, dd/MM/yyyy').format(selectedDate)
                  : 'Select $label',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
