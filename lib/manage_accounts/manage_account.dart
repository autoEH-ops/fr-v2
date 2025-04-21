import 'package:flutter/material.dart';

import '../model/account.dart';

class ManageAccount extends StatefulWidget {
  final Account account;
  const ManageAccount({super.key, required this.account});

  @override
  State<ManageAccount> createState() => _ManageAccountState();
}

class _ManageAccountState extends State<ManageAccount> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _emailController = TextEditingController(
        text: widget.account.email); // Assuming Account has email
    _roleController = TextEditingController(text: widget.account.role);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _updateAccount() {
    setState(() {
      widget.account.name = _nameController.text;
      widget.account.email = _emailController.text;
      widget.account.role = _roleController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account updated')),
    );

    Navigator.pop(context, widget.account); // Send updated account back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueAccent,
              child: Text(
                widget.account.name.isNotEmpty
                    ? widget.account.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 24),
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
              controller: _roleController,
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
