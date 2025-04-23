import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
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
  SupabaseDbHelper dbHelper = SupabaseDbHelper();
  ManageAccountsLogic managementLogic = ManageAccountsLogic();
  File? _imageFile;

  final Map<String, String> _roles = {
    'super_admin': 'Super Admin',
    'admin': 'Admin',
    'security': 'Security',
    'viewer': 'Viewer',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _emailController = TextEditingController(text: widget.account.email);
    _phoneController = TextEditingController(text: widget.account.phone);
    _selectedRole = widget.account.role;
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

  void _updateAccount() async {
    Map<String, dynamic> row = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'phone': _phoneController.text.trim(),
    };
    if (_imageFile != null) {
      dbHelper.updateFromBucket(_imageFile!, widget.account);
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
      });
    } catch (e) {
      debugPrint('Update error: $e');
    } finally {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Account updated. Updated photo will take time to process and take effect')),
      );

      Navigator.pop(context, widget.account);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
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
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateAccount,
              child: const Text('Update Account'),
            ),
          ],
        ),
      ),
    );
  }
}
