import 'dart:typed_data';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../login/login_page.dart';
import '../attendance_dashboard/attendance_dashboard.dart';
import '../db/supabase_db_helper.dart';
import '../model/recognition.dart';
import '../model/setting.dart';
import 'face_registration.dart';
import '../model/account.dart';
import '../attendance_dashboard/recognizer.dart';
import 'register_guest_logic.dart';

class RegisterAttendance extends StatefulWidget {
  final Account? account;
  final List<Setting>? systemSettings;
  final bool isGuest;
  const RegisterAttendance(
      {super.key, this.account, this.systemSettings, this.isGuest = false});

  @override
  State<RegisterAttendance> createState() => _RegisterAttendanceState();
}

class _RegisterAttendanceState extends State<RegisterAttendance> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  late ImagePicker imagePicker;
  late Account account;
  late FaceDetector faceDetector;
  late Recognizer recognizer;
  final dbHelper = SupabaseDbHelper();
  final RegisterGuestLogic guestLogic = RegisterGuestLogic();

  final Map<String, String> _roleMap = {
    'admin': 'Admin',
    'super_admin': 'Super Admin',
    'security': 'Security',
    'intern': 'Intern',
  };
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    recognizer = Recognizer();
    final options =
        FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    faceDetector = FaceDetector(options: options);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    late Uint8List imageBytes;
    late List<Face> faces;

    if (!_formKey.currentState!.validate() || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      XFile? pickedFile =
          await imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (pickedFile == null) {
        Navigator.of(context).pop();
        return;
      }

      imageBytes = await pickedFile.readAsBytes();
      final inputImage = InputImage.fromFilePath(pickedFile.path);

      faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();
    } catch (e) {
      debugPrint("Something went wrong when processing image from uploading");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to process image.")),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    if (faces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No face found in the selected image")),
      );
      return;
    }

    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return;

    final Face face = faces.first;

    _performFaceRegistration(face, originalImage, imageBytes);
  }

  _performFaceRegistration(
      Face face, img.Image originalImage, Uint8List imageBytes) async {
    final faceRect = face.boundingBox;
    final croppedFace = img.copyCrop(originalImage,
        x: faceRect.left.toInt(),
        y: faceRect.top.toInt(),
        width: faceRect.width.toInt(),
        height: faceRect.height.toInt());

    Recognition recognition =
        recognizer.recognize(croppedFace, face.boundingBox);

    _showFaceRegistrationDialogUploadedImage(
        croppedFace, recognition, imageBytes);
  }

  void _showFaceRegistrationDialogUploadedImage(
      img.Image croppedFace, Recognition recognition, Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "Confirm Face Registration",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
          ),
        ),
        content: SizedBox(
          height: 360,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    Uint8List.fromList(img.encodeBmp(croppedFace)),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Is this face correctly captured?",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      final String uniqueUrl =
                          '${_emailController.text}_${_selectedRole}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                      final String filePath = 'public/$uniqueUrl';

                      try {
                        await dbHelper.insertIntoBucket(filePath, imageBytes);
                        debugPrint("Inserted in bucket successfully.");
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Uploading image failed. Contact Admin for changes.")),
                        );
                        debugPrint(
                            "Something went wrong in uploading image: $e");
                      }

                      String imageUrl =
                          '${dotenv.env['SUPABASE_URL']}/storage/v1/object/public/images/public/$uniqueUrl';

                      try {
                        if (widget.isGuest) {
                          Map<String, dynamic> guestRow = {
                            'name': _nameController.text.trim(),
                            'phone': _phoneController.text.trim(),
                            'email': _emailController.text.trim(),
                            'role': _selectedRole!,
                            'image_url': imageUrl,
                            'start_date': _startDate!.toUtc().toIso8601String(),
                            'end_date': _endDate!.toUtc().toIso8601String(),
                            'embeddings': recognition.embeddings
                          };
                          await guestLogic.insertRegisterAccountRequests(
                              dbHelper: dbHelper, row: guestRow);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Please wait for admin approval."),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ));
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        } else {
                          Map<String, dynamic> row = {
                            'name': _nameController.text.trim(),
                            'phone': _phoneController.text.trim(),
                            'email': _emailController.text.trim(),
                            'role': _selectedRole!,
                            'image_url': imageUrl,
                            'start_date': _startDate!.toUtc().toIso8601String(),
                            'end_date': _endDate!.toUtc().toIso8601String(),
                          };
                          await dbHelper.insert('accounts', row);
                          final newAccount =
                              await dbHelper.getRowByField<Account>(
                            'accounts',
                            'email',
                            _emailController.text,
                            (data) => Account.fromMap(data),
                          );
                          if (newAccount != null) {
                            await recognizer.registerFaceInDb(
                              recognition.embeddings,
                              newAccount,
                            );
                            await dbHelper.insert('employee_metrics', {
                              'account_id': newAccount.id,
                              'annual_leave_entitlement': 8
                            });
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Face Registered")),
                            );
                          }
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.push(
                            context,
                            widget.account != null &&
                                    widget.systemSettings != null
                                ? MaterialPageRoute(
                                    builder: (context) => AttendanceDashboard(
                                          account: widget.account!,
                                          systemSettings:
                                              widget.systemSettings!,
                                        ))
                                : MaterialPageRoute(
                                    builder: (context) => LoginPage()),
                          );
                        }
                      } catch (e) {
                        debugPrint("Registration error: $e");
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Registration failed. Try again later."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      "Register",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                    width: 10.0,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitAndProceedToFaceRegistration() {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      account = Account(
        null,
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _emailController.text.trim(),
        _selectedRole!,
        null,
        null,
        _startDate!,
        _endDate!,
      );

      debugPrint('Registered Account:');
      debugPrint('Phone: ${account.phone}');
      debugPrint('Email: ${account.email}');
      debugPrint('Role: ${account.role}');
      debugPrint("dates: first - $_startDate and last $_endDate");

      _showFaceRegistrationDialog();
    }
  }

  void _showFaceRegistrationDialog() {
    final instructions = [
      "Hold the phone at a comfortable distance from your face.",
      "Ensure good lighting and remove any face coverings.",
      "Make sure all the information entered is correct.",
      "Click below when you are ready.",
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Before Face Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: instructions
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key + 1}. '),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FaceRegistration(
                    account: account,
                    systemSettings: widget.systemSettings,
                  ),
                ),
              );
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isGuest ? 'Guest Registration' : 'Register Attendance'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_nameController, "Full Name", Icons.person),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, "Phone Number", Icons.phone,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(_emailController, "Email Address", Icons.email,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Role",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedRole,
                  items: _roleMap.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a role' : null,
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
                if (_selectedRole == 'intern') ...[
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
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(
                          Icons.upload_file,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Upload Face",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submitAndProceedToFaceRegistration,
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Camera",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: (value) => value == null || value.trim().isEmpty
          ? 'This field is required'
          : null,
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
