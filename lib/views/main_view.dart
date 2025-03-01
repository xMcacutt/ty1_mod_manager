import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:ty1_mod_manager/models/mm_app_bar.dart';
import 'package:ty1_mod_manager/services/ffi_win32.dart';
import 'package:ty1_mod_manager/services/update_manager_service.dart';
import 'package:ty1_mod_manager/theme.dart';
import 'package:ty1_mod_manager/views/codes_view.dart';
import 'package:win32/win32.dart';
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
  late Future<List<Mod>> modListFuture;

  @override
  void initState() {
    super.initState();
    modListFuture = loadMods();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    Settings? settings = await Settings.loadSettings();
    if (settings == null) {
      return;
    }
    if (!settings.updateManager) return;
    String? batPath = await checkForUpdate();
    if (batPath == null) {
      return;
    }
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Available"),
          content: Text(
            "A new update is available. Would you like to update now?",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Later"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                updateApp(batPath);
              },
              child: Text("Update Now"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add Scaffold here
      appBar: MMAppBar(title: "My Mods"),
      body: Stack(
        children: [
          FutureBuilder<List<Mod>>(
            future: modListFuture, // Loads the mods
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
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () => onLaunchButtonPressed(context, selectedMods),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        "Launch Game",
                        style: TextStyle(
                          fontFamily: 'SF Slapstick Comic', // Custom font name
                          fontSize: 24, // Optional: Adjust the font size,)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton(
                onPressed: () => onAddButtonPressed(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        "Add Custom",
                        style: TextStyle(
                          fontFamily: 'SF Slapstick Comic', // Custom font name
                          fontSize: 24, // Optional: Adjust the font size,)
                        ),
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
                  image: AssetImage('resource/fe_041.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
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

void onLaunchButtonPressed(BuildContext context, List<Mod> selectedMods) async {
  Settings? settings = await Settings.loadSettings();
  if (settings == null) {
    return;
  }

  var conflicts = await findConflicts(selectedMods);
  String conflictMessages = conflicts.join("\n");

  bool? shouldLaunch = true;
  if (conflicts.isNotEmpty) {
    shouldLaunch = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Conflicts Detected"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("The following conflicts were found:"),
              SizedBox(height: 10),
              Text(conflictMessages),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User chose to cancel
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User chose to launch anyway
              },
              child: Text("Launch Anyway"),
            ),
          ],
        );
      },
    );
  }

  if (!shouldLaunch!) return;

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
    if (mod.dllFile == null) {
      return;
    }
    await mod.dllFile!.copy(
      '${settings.tyDirectoryPath}/Plugins/${path.basename(mod.dllFile!.path)}',
    );
  }

  var argsString = settings.launchArgs;
  var launchArgs = argsString.split(' ');
  for (var arg in launchArgs) {
    print(arg);
  }
  Process result = await Process.start(
    '${settings.tyDirectoryPath}/Ty.exe',
    launchArgs,
    workingDirectory: settings.tyDirectoryPath,
  );

  MemoryEditor.init(result.pid);
  await MemoryEditor.waitForProcessToStart(result.pid);
  CodesView.applyActiveCodes();
  result.exitCode.then((exitCode) {
    // Clean up after the process has exited
    MemoryEditor.deinit();
    print('Process exited with code: $exitCode');
  });
}

void onAddButtonPressed(BuildContext context) async {
  FilePicker filePicker = FilePickerIO();
  var result = await filePicker.pickFiles(
    allowMultiple: false,
    allowedExtensions: ['zip'],
    dialogTitle: 'Select Mod Zip...',
  );

  if (result == null || !await addCustomMod(result)) {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Invalid File"),
          content: Text("Please select a valid mod zip file."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Ok"),
            ),
          ],
        );
      },
    );
  }
}

class ModListing extends StatefulWidget {
  final Mod mod;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const ModListing({
    required this.mod,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  _ModListing createState() => _ModListing();
}

class _ModListing extends State<ModListing> {
  late Future<bool> _iconExistFuture;

  @override
  void initState() {
    super.initState();
    _iconExistFuture = widget.mod.iconFile?.exists() ?? Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<bool>(
        future: _iconExistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!) {
            return Image.asset('resource/unknown.ico');
          } else {
            return Image.file(widget.mod.iconFile!);
          }
        },
      ), // Display mod icon
      title: Text(widget.mod.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.mod.description),
          SizedBox(height: 4), // Add space
          Row(
            children: [
              Text(
                'Version: ${widget.mod.version}',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(width: 10),
              Text(
                'Author: ${widget.mod.author}',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(width: 10),
              Text(
                'Last Update: ${widget.mod.lastUpdated}',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      trailing: Switch(
        value: widget.isSelected,
        onChanged: (bool? value) {
          if (value != null) {
            widget.onSelected(value);
          }
        },
      ),
      onTap: () {
        widget.onSelected(!widget.isSelected);
      },
    );
  }
}
