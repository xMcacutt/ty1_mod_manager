import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:ty1_mod_manager/theme.dart';
import '../models/mod.dart';
import '../services/mod_service.dart';
import 'dart:io';
import '../services/settings_service.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  List<Mod> selectedMods = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add Scaffold here
      appBar: AppBar(
        title: Text(
          'Ty the Tasmanian Tiger - Mod Manager',
          style: TextStyle(
            fontFamily: 'SF Slapstick Comic', // Custom font name
            fontSize: 27, // Optional: Adjust the font size
          ),
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Mod>>(
            future: loadMods(), // Loads the mods
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error loading mods'));
              }

              final mods = snapshot.data ?? [];
              return ListView.builder(
                itemCount: mods.length,
                itemBuilder: (context, index) {
                  final mod = mods[index];
                  final isSelected = selectedMods.contains(mod);
                  return ModListing(
                    mod: mod,
                    isSelected: isSelected,
                    onSelected: (isSelected) {
                      setState(() {
                        if (isSelected) {
                          selectedMods.add(mod);
                        } else {
                          selectedMods.remove(mod);
                        }
                      });
                    },
                  );
                },
              );
            },
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () => onLaunchButtonPressed(selectedMods),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Launch Game",
                      style: TextStyle(
                        fontFamily: 'SF Slapstick Comic', // Custom font name
                        fontSize: 20, // Optional: Adjust the font size,)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('resource/a4_env.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text(
                    'Mod Manager',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.boxArchive),
              title: Text("My Mods"),
              subtitle: Text("View and manage your mods."),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.code),
              title: Text("Codes"),
              subtitle: Text("View and manage codes."),
              onTap: () {
                Navigator.pushNamed(context, '/codes');
              },
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.book),
              title: Text("Mod Directory"),
              subtitle: Text("Browse officially supported mods."),
              onTap: () {
                Navigator.pushNamed(context, '/mod_directory');
              },
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.gear),
              title: Text("Settings"),
              subtitle: Text("Edit the mod manager settings."),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.circleInfo),
              title: Text("About"),
              subtitle: Text("About the mod manager."),
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
          ],
        ),
      ),
    );
  }
}

void onLaunchButtonPressed(List<Mod> selectedMods) async {
  Settings? settings = await Settings.loadSettings();
  if (settings == null) {
    return;
  }

  Directory dir = Directory('${settings.tyDirectoryPath}/Plugins');
  var files = dir.listSync();
  for (var file in files) {
    if (file is Directory) {
      continue;
    }
    await file.delete();
  }

  dir = Directory('${settings.tyDirectoryPath}/Plugins/Dependencies');
  files = dir.listSync();
  for (var file in files) {
    await file.delete();
  }

  final appSupportDir = await getApplicationSupportDirectory();
  for (Mod mod in selectedMods) {
    for (var dep in mod.dependencies) {
      var parts = dep.split(' ');
      var depName = parts[0];
      var depVer = parts[1];
      var depDir = Directory('${appSupportDir.path}/deps/$depName/$depVer');
      for (var file in depDir.listSync()) {
        if (file is File) {
          await file.copy(
            '${settings.tyDirectoryPath}/Plugins/Dependencies/${path.basename(file.path)}',
          );
        }
      }
    }
    await mod.dllFile.copy(
      '${settings.tyDirectoryPath}/Plugins/${path.basename(mod.dllFile.path)}',
    );
  }

  ProcessResult result = await Process.run(
    '${settings.tyDirectoryPath}/Ty.exe',
    [], // Command and arguments
    workingDirectory: settings.tyDirectoryPath,
  );
}

class ModListing extends StatelessWidget {
  const ModListing({
    super.key,
    required this.mod,
    required this.isSelected,
    required this.onSelected,
  });

  final Mod mod;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<bool>(
        future: mod.icon.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!) {
            return Image.asset('resource/unknown.ico');
          } else {
            return Image.file(mod.icon);
          }
        },
      ), // Display mod icon
      title: Text(mod.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mod.description),
          SizedBox(height: 4), // Add space
          Row(
            children: [
              Text('Version: ${mod.version}', style: TextStyle(fontSize: 12)),
              SizedBox(width: 10),
              Text('Author: ${mod.author}', style: TextStyle(fontSize: 12)),
              SizedBox(width: 10),
              Text(
                'Last Update: ${mod.lastUpdated}',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isSelected, // Reflect selection state
            onChanged: (bool? value) {
              if (value != null) {
                onSelected(value); // Notify parent to update the selection
              }
            },
          ),
        ],
      ),
      onTap: () {
        // Handle tap event (if needed)
      },
    );
  }
}
