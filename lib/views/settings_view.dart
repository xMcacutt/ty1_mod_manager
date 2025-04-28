import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:ty1_mod_manager/models/mm_app_bar.dart';
import 'package:ty1_mod_manager/services/settings_service.dart';
import 'dart:io';
import 'package:ty1_mod_manager/services/github_service.dart';
import 'package:ty1_mod_manager/services/update_manager_service.dart';

class SettingsView extends StatefulWidget {
  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _autoUpdateModManager = false;
  TextEditingController _tyDirectoryController = TextEditingController();
  TextEditingController _launchArgsController = TextEditingController();

  // Function to open file picker to select directory
  Future<void> _selectDirectory() async {
    // Use FilePicker to select a directory
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      setState(() {
        _tyDirectoryController.text = selectedDirectory; // Set the selected directory path in the text controller
      });
    }
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
        _autoUpdateModManager = settings.updateManager;
        _launchArgsController.text = settings.launchArgs;
      });
    }
  }

  Future<void> _update() async {
    // Show a loading indicator while updating
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(), // Show loading indicator
        );
      },
    );

    // Perform the update check in the background
    bool updateSuccessful = await downloadAndUpdateTygerFramework();

    Navigator.of(context, rootNavigator: true).pop();
    if (!updateSuccessful) {
      // Show failure dialog if the update failed
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Update Failed"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Could not update TygerFramework.\nMake sure you have a valid Ty directory path and internet connection.",
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // User chose to cancel
                },
                child: Text("Okay"),
              ),
            ],
          );
        },
      );
    }

    // Show a loading indicator while updating
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(), // Show loading indicator
        );
      },
    );

    // Proceed with additional checks after the update
    await checkForUpdate(updateFramework: false);
    Navigator.of(context, rootNavigator: true).pop();
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
            children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Processing...")],
          ),
        );
      },
    );

    await Future.delayed(Duration(milliseconds: 500));

    if (!await isValidDirectory(_tyDirectoryController.text)) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    Settings settings = Settings(
      tyDirectoryPath: _tyDirectoryController.text,
      updateManager: _autoUpdateModManager,
      launchArgs: _launchArgsController.text,
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
      appBar: MMAppBar(title: "Settings"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // TY Directory Section
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text("Ty Directory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Auto Update Mod Manager Switc
            SwitchListTile(
              title: Text("Auto Update On Launch?"),
              value: _autoUpdateModManager,
              onChanged: (bool value) {
                setState(() {
                  _autoUpdateModManager = value;
                });
              },
              secondary: Icon(Icons.update),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _update,
              child: Text(
                "Check For Updates",
                style: TextStyle(
                  fontFamily: 'SF Slapstick Comic', // Custom font name
                  fontSize: 24, // Optional: Adjust the font size
                ),
              ),
            ),

            SizedBox(height: 20),

            TextFormField(
              controller: _launchArgsController,
              decoration: InputDecoration(labelText: "Launch Arguments", border: OutlineInputBorder()),
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
