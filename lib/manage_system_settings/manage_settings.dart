import 'package:flutter/material.dart';

import '../db/supabase_db_helper.dart';
import '../geolocator/geolocator_service.dart';
import '../model/account.dart';
import '../model/setting.dart';
import 'manage_settings_logic.dart';

class ManageSettings extends StatefulWidget {
  final Account account;
  const ManageSettings({super.key, required this.account});

  @override
  State<ManageSettings> createState() => _ManageSettingsState();
}

class _ManageSettingsState extends State<ManageSettings> {
  List<Setting> systemSettings = [];
  final SupabaseDbHelper dbHelper = SupabaseDbHelper();
  final ManageSettingsLogic settingsLogic = ManageSettingsLogic();
  final GeolocatorService geolocatorService = GeolocatorService();
  bool _isLoading = true;
  final List<TextEditingController> _controllers = [];
  String location = 'Not set';

  @override
  void initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadSettings =
        await settingsLogic.getAllSystemSettings(dbHelper: dbHelper);

    setState(() {
      systemSettings = loadSettings;
      _controllers.addAll(
          systemSettings.map((s) => TextEditingController(text: s.value)));
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Map<String, double> location = await settingsLogic.getCurrentLatAndLong(
          geolocatorService: geolocatorService);
      setState(() {
        _isLoading = true;
        _controllers[0].text = location['lat'].toString();
        _controllers[1].text = location['long'].toString();
      });
    } catch (e) {
      debugPrint("Failed to get location.");
    } finally {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Updated related fields with current location latitude and longitude.\n'
                'Please click on Update to confirm changes')),
      );
    }
  }

  Future<void> _updateSystemSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      settingsLogic.updateSystemSettings(
          dbHelper: dbHelper,
          systemSettings: systemSettings,
          controllers: _controllers,
          account: widget.account);
    } catch (e) {
      debugPrint('Failed to update sytem settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All settings saved to Supabase')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Settings')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSettingBottomSheet(context),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : systemSettings.isEmpty
              ? const Center(
                  child: Text("No settings found."),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                        child: ListView.builder(
                          itemCount: systemSettings.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                        "${settingsLogic.formatReadableSetting(systemSettings[index].setting)} : "),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _controllers[index],
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Get Location'),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: _updateSystemSettings,
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  void _showAddSettingBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Add New System Setting"),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _addNewSetting(nameController.text, valueController.text);
                      Navigator.pop(context);
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _addNewSetting(String name, String value) {
    if (name.isNotEmpty && value.isNotEmpty) {
      // Add your logic to add the new setting
      setState(() {
        // systemSettings.add(SystemSetting(setting: name, value: value));
        // _controllers.add(TextEditingController(text: value));
      });
    }
  }
}
