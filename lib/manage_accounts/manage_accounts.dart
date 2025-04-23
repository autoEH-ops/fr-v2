import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '../model/activity.dart';
import '../model/setting.dart';
import '../registration/register_attendance.dart';
import 'manage_account.dart';
import 'manage_accounts_logic.dart';

class ManageAccounts extends StatefulWidget {
  final Account account;
  final List<Setting> systemSettings;
  const ManageAccounts(
      {super.key, required this.account, required this.systemSettings});

  @override
  State<ManageAccounts> createState() => _ManageAccountsState();
}

class _ManageAccountsState extends State<ManageAccounts> {
  List<Account> accounts = [];
  Map<int, Activity> latestActivities = {};
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final ManageAccountsLogic managementLogic = ManageAccountsLogic();
  bool _isLoading = true;
  final Set<Account> selectedAccounts = {};

  @override
  void initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadAccounts =
        await managementLogic.getAllAccounts(dbHelper: dbHelper);

    final loadActivitiesMap = await managementLogic.getActivitiesMap(
        accounts: loadAccounts, dbHelper: dbHelper);

    setState(() {
      accounts = loadAccounts;
      latestActivities = loadActivitiesMap;
      _isLoading = false;
    });
  }

  void _navigateToAccountDetail(Account account) async {
    final updatedAccount = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageAccount(account: account),
      ),
    );

    if (updatedAccount != null) {
      setState(() {
        // Update your local UI / list / view model etc.
        account.name = updatedAccount.name;
        account.email = updatedAccount.email;
        account.phone = updatedAccount.phone;
        account.role = updatedAccount.role;
      });
    }
  }

  void _deleteSelectedAccounts() async {
    final selectedIds = selectedAccounts.map((a) => a.id!).toList();

    final imagePaths =
        selectedAccounts.where((a) => a.imageUrl != null).map((a) {
      final result = a.imageUrl!.split('public/').last;
      final publicPath = 'public/$result';
      return publicPath; // Assumes path is like /storage/v1/object/public/images/<filename>
    }).toList();

    try {
      setState(() {
        _isLoading = true;
      });

      // Delete related data first
      await dbHelper.deleteMultiple(
          table: 'accounts', ids: selectedIds, fieldName: 'id');

      // Delete images from Supabase Storage
      await dbHelper.deleteFromBucket(imagePaths);

      // Update UI
      await loadLatestData();
      selectedAccounts.clear();
    } catch (e) {
      debugPrint('Deletion error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : accounts.isEmpty
              ? const Center(
                  child: Text("No accounts found."),
                )
              : Column(
                  children: [
                    // Add Account Button
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterAttendance(
                                  account: widget.account,
                                  systemSettings: widget.systemSettings,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text("Add New Account"),
                        ),
                      ),
                    ),

                    // Deletion prompt
                    if (selectedAccounts.isNotEmpty)
                      Card(
                        color: Colors.red[100],
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.warning, color: Colors.red),
                          title: const Text(
                            'Delete selected account(s)?',
                            style: TextStyle(color: Colors.red),
                          ),
                          trailing: TextButton(
                            onPressed: _deleteSelectedAccounts,
                            child: const Text("Delete",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ),

                    // Account list
                    Expanded(
                      child: ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          final isSelected = selectedAccounts.contains(account);

                          return Card(
                            color: isSelected ? Colors.red[50] : Colors.white,
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                  ? const BorderSide(
                                      color: Colors.redAccent, width: 1.5)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedAccounts.add(account);
                                    } else {
                                      selectedAccounts.remove(account);
                                    }
                                  });
                                },
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blueAccent,
                                        backgroundImage: account.imageUrl !=
                                                null
                                            ? NetworkImage(account.imageUrl!)
                                            : null,
                                        child: account.imageUrl == null
                                            ? Text(
                                                account.name[0].toUpperCase(),
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          account.name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.email,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          account.email,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(account.phone,
                                          style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Role: ${managementLogic.formatReadableRole(account.role)}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: latestActivities[account.id]
                                                      ?.activity !=
                                                  null
                                              ? managementLogic
                                                  .getActivityColor(
                                                      latestActivities[
                                                              account.id]!
                                                          .activity)
                                              : Colors
                                                  .red, // define role-based colors
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        latestActivities[account.id]
                                                    ?.activity !=
                                                null
                                            ? managementLogic
                                                .formatReadableActivity(
                                                    latestActivities[
                                                            account.id]!
                                                        .activity)
                                            : "Check Out",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                "Please tap to update information.",
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic),
                              ),
                              onTap: () => _navigateToAccountDetail(account),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
