import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ty1_mod_manager/main.dart';
import '../providers/settings_provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text("Ty Directory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: TextEditingController(text: settingsProvider.tyDirectoryPath),
                        onChanged: settingsProvider.updateTyDirectoryPath,
                        decoration: InputDecoration(
                          labelText: "Enter Ty Directory Path",
                          border: OutlineInputBorder(),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: ElevatedButton(
                              onPressed: () => settingsProvider.selectDirectory(),
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
                SwitchListTile(
                  title: Text("Auto Update On Launch?"),
                  value: settingsProvider.autoUpdateModManager,
                  onChanged: settingsProvider.toggleAutoUpdate,
                  secondary: Icon(Icons.update),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed:
                      settingsProvider.isUpdating
                          ? null
                          : () async {
                            final success = await settingsProvider.checkForUpdates(context);
                            if (!success) {
                              await dialogService.showError(
                                "Update Failed",
                                "Could not update TygerFramework.\nMake sure you have a valid Ty directory path and internet connection.",
                              );
                            }
                          },
                  child: Text("Check For Updates", style: TextStyle(fontFamily: 'SF Slapstick Comic', fontSize: 24)),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: TextEditingController(text: settingsProvider.launchArgs),
                  onChanged: settingsProvider.updateLaunchArgs,
                  decoration: InputDecoration(labelText: "Launch Arguments", border: OutlineInputBorder()),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      settingsProvider.isLoading
                          ? null
                          : () async {
                            final success = await settingsProvider.saveSettings(context);
                            if (success) {
                              await dialogService.showInfo(
                                'Settings Saved',
                                'Your settings have been saved successfully!',
                              );
                            }
                          },
                  child: Text("Save Settings", style: TextStyle(fontFamily: 'SF Slapstick Comic', fontSize: 24)),
                ),
              ],
            ),
          ),
          if (settingsProvider.isLoading || settingsProvider.isUpdating)
            Center(
              child: AlertDialog(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text(settingsProvider.isUpdating ? "Updating..." : "Processing..."),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
