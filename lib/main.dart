import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'views/main_view.dart' show MainView;
import 'theme.dart';
import 'views/settings_view.dart';

void main() {
  runApp(ModManagerApp());
}

/// URL where the latest version info is stored
const String latestVersionUrl =
    "https://raw.githubusercontent.com/xMcacutt/ty1_mod_manager/main/latest.json";

/// Check for updates and trigger download if needed
Future<void> checkForUpdate() async {
  try {
    final response = await http.get(Uri.parse(latestVersionUrl));
    if (response.statusCode != 200) return;

    final latestData = json.decode(response.body);
    final latestVersion = latestData["version"];
    final downloadUrl = latestData["download_url"];

    final currentVersion = await getCurrentVersion();
    if (currentVersion == latestVersion) {
      print("Already up-to-date (v$currentVersion).");
      return;
    }

    print("New version available: $latestVersion. Downloading...");
    await downloadAndPrepareUpdate(downloadUrl, latestVersion);
  } catch (e) {
    print("Update check failed: $e");
  }
}

/// Get the currently installed version
Future<String> getCurrentVersion() async {
  final appDir = getAppDirectory();
  final versionFile = File("$appDir/version.txt");

  if (!versionFile.existsSync()) {
    versionFile.writeAsStringSync("1.0.0");
  }

  return versionFile.readAsStringSync().trim();
}

/// Get the directory where the app is running
String getAppDirectory() {
  return File(Platform.resolvedExecutable).parent.path;
}

/// Download and prepare the update
Future<void> downloadAndPrepareUpdate(String url, String newVersion) async {
  final tempDir = await getTemporaryDirectory();
  final updateFolder = "${tempDir.path}/update";
  final zipFilePath = "${tempDir.path}/update.zip";
  final batchFilePath = "${tempDir.path}/update.bat";
  final appDir = getAppDirectory();

  // Ensure update directory is clean
  Directory(updateFolder).createSync(recursive: true);

  // Download the ZIP file
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    print("Download failed.");
    return;
  }
  File(zipFilePath).writeAsBytesSync(response.bodyBytes);
  print("Download complete.");

  // Extract ZIP to temp folder
  final bytes = File(zipFilePath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  for (final file in archive) {
    final filePath = "$updateFolder/${file.name}";
    if (file.isFile) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(filePath).createSync(recursive: true);
    }
  }
  print("Update extracted.");

  // Create a batch file to replace files and restart app
  final exeName =
      Platform.resolvedExecutable.split(Platform.pathSeparator).last;
  final batchContent = '''
    @echo off
    taskkill /IM "$exeName" /F
    timeout /t 2
    xcopy /E /Y "$updateFolder\\*" "$appDir\\"
    start "" "$appDir\\$exeName"
    exit
  ''';

  File(batchFilePath).writeAsStringSync(batchContent);
  print("Update script created.");

  // Run batch script and exit app
  Process.run("cmd.exe", ["/c", batchFilePath]);
  exit(0);
}

class ModManagerApp extends StatelessWidget {
  const ModManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    checkForUpdate();
    return MaterialApp(
      title: 'Ty the Tasmanian Tiger - Mod Manager',
      theme: appTheme,
      initialRoute: '/mods',
      routes: {
        '/mods': (context) => MainView(),
        //'/codes': (context) => CodesView(),
        //'/mod_directory': (context) => ModDirectoryView(),
        '/settings': (context) => SettingsView(),
        //'/about': (context) => AboutView(),
      },
    );
  }
}
