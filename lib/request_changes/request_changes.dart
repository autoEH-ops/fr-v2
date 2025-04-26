import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import 'request_changes_logic.dart';

class RequestChanges extends StatefulWidget {
  final Account account;
  const RequestChanges({super.key, required this.account});

  @override
  State<RequestChanges> createState() => _RequestChangesState();
}

class _RequestChangesState extends State<RequestChanges> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  SupabaseDbHelper dbHelper = SupabaseDbHelper();
  RequestChangesLogic requestLogic = RequestChangesLogic();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _emailController = TextEditingController(text: widget.account.email);
    _phoneController = TextEditingController(text: widget.account.phone);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _insertRequest() async {
    String imageUrl = '';
    Map<String, dynamic> accountRow = {};
    Map<String, dynamic> row = {};

    try {
      if (_imageFile != null) {
        Uint8List imageBytes = await _imageFile!.readAsBytes();
        final String uniqueUrl =
            '${_emailController.text.trim()}_${widget.account.role}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        debugPrint("This is the unique url: $uniqueUrl");
        final String filePath = 'public/$uniqueUrl';
        await dbHelper.insertIntoBucket(filePath, imageBytes);
        imageUrl =
            '${dotenv.env['SUPABASE_URL']}/storage/v1/object/public/images/public/$uniqueUrl';
        debugPrint("This is the $imageUrl");
      }
      accountRow = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (_imageFile != null) ...{'image_url': imageUrl}
      };
      row = {
        'account_id': widget.account.id,
        'request_status': 'pending',
        'requested_changes': accountRow,
        'request_category': 'account_edit'
      };

      debugPrint("Get here: ${row['requested_changes']}");
      await dbHelper.insert('requests', row);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Request has been made. Please wait for admin approval.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Failed to create request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request Profile Change"),
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
                      radius: 45,
                      backgroundColor: Colors.indigo.shade600,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : widget.account.imageUrl != null
                              ? NetworkImage(widget.account.imageUrl!)
                              : null,
                      child:
                          widget.account.imageUrl == null && _imageFile == null
                              ? Text(
                                  widget.account.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _insertRequest,
              child: const Text('Request Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
