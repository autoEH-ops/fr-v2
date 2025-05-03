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
  List<String> ocrTerms = [];
  Setting? ocrSetting;

  @override
  void initState() {
    super.initState();
    loadLatestData();
  }

  Future<void> loadLatestData() async {
    final loadSettings =
        await settingsLogic.getAllSystemSettings(dbHelper: dbHelper);

    List<String> loadOcrTerms = [];
    Setting? loadOcrSetting;

    for (int i = 0; i < loadSettings.length; i++) {
      if (loadSettings[i].setting == 'ocr_dictionary') {
        loadOcrSetting = loadSettings[i];
        loadOcrTerms =
            loadSettings[i].value.split('|').map((s) => s.trim()).toList();
        break;
      }
    }

    setState(() {
      systemSettings = loadSettings;
      ocrSetting = loadOcrSetting;
      ocrTerms = loadOcrTerms;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Updated related fields with current location latitude and longitude.\n'
                  'Please click on Update to confirm changes')),
        );
      }
    }
  }

  Future<void> _updateSystemSettings() async {
    setState(() {
      _isLoading = true;
    });
    for (var entry in systemSettings.asMap().entries) {
      final setting = entry.value;

      if (setting.setting != 'ocr_dictionary') {
        settingsLogic.updateSystemSettings(
          dbHelper: dbHelper,
          systemSettings: systemSettings,
          controllers: _controllers,
          account: widget.account,
        );
      } else {
        final updatedOcrValue = ocrTerms
            .map((term) => term.trim())
            .where((term) => term.isNotEmpty)
            .join('|');

        try {
          debugPrint("updatedOcrValue");
          await dbHelper.updateWhere('system_settings', 'id', ocrSetting!.id, {
            'value': updatedOcrValue,
            'last_updated': DateTime.now().toUtc().toIso8601String(),
            'updated_by': widget.account.id
          });
        } catch (e) {
          debugPrint("Failed to update OCR Dictionary: $e ");
        } finally {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All settings saved to Supabase')),
            );
          }
        }
      }
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
                      Expanded(
                        child: ListView.builder(
                          itemCount: systemSettings.length,
                          itemBuilder: (context, index) {
                            if (systemSettings[index].setting !=
                                'ocr_dictionary') {
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
                            } else {
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.text_snippet,
                                        color: Colors.blueAccent),
                                    title: const Text(
                                      "OCR Dictionary",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black),
                                    ),
                                    childrenPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    children: [
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: ocrTerms.length,
                                        itemBuilder: (context, i) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                    initialValue: ocrTerms[i],
                                                    onChanged: (val) =>
                                                        ocrTerms[i] = val,
                                                    decoration: InputDecoration(
                                                      hintText: 'Term ${i + 1}',
                                                      border:
                                                          const OutlineInputBorder(),
                                                      isDense: true,
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 12,
                                                              vertical: 8),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    setState(() =>
                                                        ocrTerms.removeAt(i));
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () {
                                            setState(() => ocrTerms.add(''));
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add New Term'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
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
              Text(
                "Add New System Settings",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
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

  void _addNewSetting(String name, String value) async {
    if (name.isNotEmpty && value.isNotEmpty) {
      try {
        setState(() {
          _isLoading = true;
        });
        Map<String, String> row = {
          'setting': name.toLowerCase().split(' ').join('_'),
          'value': value,
        };
        await dbHelper.insert('system_settings', row);

        setState(() {
          systemSettings.add(Setting(null, name, value, null, null, null));
          _controllers.add(TextEditingController(text: value));
        });
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully added new system settings."),
          ),
        );
      } catch (e) {
        debugPrint("Failed to add system settings: $e");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Please insert settings name and value before proceeding."),
        ),
      );
    }
  }
}
