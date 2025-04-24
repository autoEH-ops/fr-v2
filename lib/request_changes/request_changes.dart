import 'dart:io';

import 'package:flutter/material.dart';
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
    Map<String, dynamic> accountRow = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    };
    final row = {
      'account_id': widget.account.id,
      'request_status': 'pending',
      'requested_changes': accountRow,
    };

    await dbHelper.insert('account_edit_requests', row);
    debugPrint("Get here: ${row['requested_changes']}");

    // if (_imageFile != null) {
    //   await dbHelper.updateFromBucket(_imageFile!, widget.account);
    //   debugPrint("Sucessful in replacing image");
    // }
    // try {
    //   await requestLogic.updateAccountInformation(
    //       account: widget.account, dbHelper: dbHelper, row: row);
    //   setState(() {
    //     widget.account.name = _nameController.text.trim();
    //     widget.account.email = _emailController.text.trim();
    //     widget.account.phone = _phoneController.text.trim();
    //   });
    // } catch (e) {
    //   debugPrint('Update error: $e');
    // } finally {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //         content: Text(
    //             'Account updated. Updated photo will take time to process and take effect')),
    //   );

    //   Navigator.pop(context, widget.account);
    // }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Profile Change')),
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
