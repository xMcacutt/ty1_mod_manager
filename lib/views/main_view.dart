import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ty1_mod_manager/main.dart';
import 'package:ty1_mod_manager/models/mm_app_bar.dart';
import 'package:ty1_mod_manager/services/ffi_win32.dart';
import 'package:ty1_mod_manager/services/update_manager_service.dart';
import 'package:ty1_mod_manager/services/version_service.dart';
import 'package:ty1_mod_manager/views/codes_view.dart';
import '../models/mod.dart';
import '../services/mod_service.dart' as modService;
import 'dart:io';
import '../services/settings_service.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with RouteAware {
  List<Mod> selectedMods = [];
  late Future<List<Mod>> modListFuture;
  bool? isFirstRun;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
    modListFuture = modService.loadMods();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    modListFuture = modService.loadMods();
  }

  Future<void> _checkFirstRun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? firstRun = prefs.getBool('isFirstRun');
    if (firstRun == null || firstRun) {
      // First time setup, show the setup screen
      setState(() {
        isFirstRun = true;
      });
    } else {
      // Not the first time, proceed with the regular home screen
      setState(() {
        isFirstRun = false;
      });
    }
    if (isFirstRun != null && !isFirstRun!) {
      print(isFirstRun);
      _checkForUpdate();
    }
  }

  _completeSetup(bool autoComplete) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false); // Mark the setup as completed
    if (!autoComplete) {
      setState(() {
        isFirstRun = false;
      });
      return;
    }
    var result = await _openDirectoryPicker();
    if (result) {
      if (mounted) {
        setState(() {
          isFirstRun = false; // Update UI to show the regular home screen
        });
      }
    }
  }

  Future<bool> _openDirectoryPicker() async {
    String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select vanilla Ty install folder...",
      lockParentWindow: true,
    );

    if (result != null) {
      var source = Directory(result);
      var destination = Directory(
        "${source.parent.path}/Ty the Tasmanian Tiger - Mod Managed",
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Copying files, please wait...'),
                ],
              ),
            ),
          );
        },
      );
      await copyDirectory(source, destination);
      Navigator.of(context, rootNavigator: true).pop();
      var settings = Settings(
        tyDirectoryPath: destination.path,
        launchArgs: '',
        updateManager: true,
      );
      await settings.saveSettings();
      if (mounted) {
        setState(() {
          isFirstRun = false; // Update UI to show the regular home screen
        });
      }
      return true;
    }
    return false;
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
          if (isFirstRun == true || isFirstRun == null)
            AlertDialog(
              title: Text('Welcome!'),
              content: Text(
                'Do you want me to automatically set up your modded Ty directory?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    _completeSetup(false);
                  },
                  child: Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    _completeSetup(true);
                  },
                  child: Text('Yes'),
                ),
              ],
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
                      'Version ${getAppVersion()}',
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

  var conflicts = await modService.findConflicts(selectedMods);
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
  if (!dir.existsSync()) {
    dir.createSync();
  }
  var files = dir.listSync();
  for (var file in files) {
    if (file is Directory) {
      continue;
    }
    await file.delete();
  }

  dir = Directory('${settings.tyDirectoryPath}/Plugins/Dependencies');
  if (!dir.existsSync()) {
    dir.createSync();
  }
  files = dir.listSync();
  for (var file in files) {
    await file.delete();
  }

  final appSupportDir = await getApplicationSupportDirectory();
  Map<String, String> depVersions = {};
  for (Mod mod in selectedMods) {
    for (var dep in mod.dependencies) {
      var parts = dep.split(' ');
      var depName = parts[0];
      var depVer = parts[1];
      if (depVersions.containsKey(depName)) {
        var existingVer = depVersions[depName]!;
        if (modService.compareVersions(depVer, existingVer) <= 0) {
          continue;
        }
      }

      depVersions[depName] = depVer;
      var depDir = Directory('${appSupportDir.path}/deps/$depName/$depVer');
      for (var file in depDir.listSync()) {
        if (file is File) {
          var destFilePath =
              '${settings.tyDirectoryPath}/Plugins/Dependencies/${path.basename(file.path)}';
          if (!File(destFilePath).existsSync()) {
            await file.copy(destFilePath);
          }
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
  var result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: ['zip'],
    dialogTitle: 'Select Mod Zip...',
  );

  if (result == null || !await modService.addCustomMod(result)) {
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
