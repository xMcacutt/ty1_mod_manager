import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ty1_mod_manager/services/settings_service.dart';
import 'dart:io';
import 'package:ty1_mod_manager/services/github_service.dart';
import 'package:archive/archive.dart';

class SettingsView extends StatefulWidget {
  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _autoUpdateModManager = false;
  bool _autoUpdateMods = false;
  TextEditingController _tyDirectoryController = TextEditingController();

  // Function to open file picker to select directory
  Future<void> _selectDirectory() async {
    // Use FilePicker to select a directory
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      setState(() {
        _tyDirectoryController.text =
            selectedDirectory; // Set the selected directory path in the text controller
      });
    }
  }

  Future<bool> _isValidDirectory(String directoryPath) async {
    final baseDirectory = Directory(directoryPath);
    final exe = File('${baseDirectory.path}/TY.exe');
    if (!await exe.exists()) {
      return false;
    }
    final pluginDirectory = Directory("$directoryPath/Plugins");
    if (!await pluginDirectory.exists()) {
      pluginDirectory.create();
    }
    final depsDirectory = Directory("$directoryPath/Plugins/Dependencies");
    if (!await depsDirectory.exists()) {
      depsDirectory.create();
    }
    final dll = File('${baseDirectory.path}/XInput9_1_0.dll');
    if (!await dll.exists()) {
      if (!await download(
        context,
        "https://github.com/ElusiveFluffy/TygerFramework/releases/latest/download/XInput9_1_0.dll",
        "${baseDirectory.path}/XInput9_1_0.dll",
      )) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load settings when the view is pushed
  }

  // Load settings when the view is pushed
  Future<void> _loadSettings() async {
    Settings? settings = await Settings.loadSettings();

    if (settings != null) {
      setState(() {
        _tyDirectoryController.text = settings.tyDirectoryPath;
        _autoUpdateMods = settings.autoUpdateMods;
        _autoUpdateModManager = settings.autoUpdateManager;
      });
    }
  }

  // Save settings when the save button is pressed
  Future<void> _saveSettings() async {
    // Show the loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing..."),
            ],
          ),
        );
      },
    );

    await Future.delayed(Duration(milliseconds: 500));

    if (!await _isValidDirectory(_tyDirectoryController.text)) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    Settings settings = Settings(
      tyDirectoryPath: _tyDirectoryController.text,
      autoUpdateMods: _autoUpdateMods,
      autoUpdateManager: _autoUpdateModManager,
    );

    await settings.saveSettings(); // Save the settings

    // Dismiss the loading dialog after saving
    Navigator.of(context, rootNavigator: true).pop();

    // Show a confirmation dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings Saved'),
          content: Text('Your settings have been saved successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // TY Directory Section
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                "Ty Directory",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                Expanded(
                  // Makes the TextFormField take available space
                  child: TextFormField(
                    controller: _tyDirectoryController,
                    decoration: InputDecoration(
                      labelText: "Enter Ty Directory Path",
                      border: OutlineInputBorder(),
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: ElevatedButton(
                          onPressed: _selectDirectory,
                          child: FaIcon(FontAwesomeIcons.folderOpen),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Auto Update Mod Manager Switch
            SwitchListTile(
              title: Text("Auto Update Mod Manager"),
              value: _autoUpdateModManager,
              onChanged: (bool value) {
                setState(() {
                  _autoUpdateModManager = value;
                });
              },
              secondary: Icon(Icons.update),
            ),
            SizedBox(height: 10),

            // Auto Update Mods Switch
            SwitchListTile(
              title: Text("Auto Update Mods"),
              value: _autoUpdateMods,
              onChanged: (bool value) {
                setState(() {
                  _autoUpdateMods = value;
                });
              },
              secondary: Icon(Icons.update),
            ),
            SizedBox(height: 20),

            // Save Settings Button
            ElevatedButton(
              onPressed: _saveSettings,
              child: Text(
                "Save Settings",
                style: TextStyle(
                  fontFamily: 'SF Slapstick Comic', // Custom font name
                  fontSize: 24, // Optional: Adjust the font size
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
