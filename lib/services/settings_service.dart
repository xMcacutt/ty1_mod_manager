import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ty1_mod_manager/services/utils.dart';
import '../models/settings.dart';

class SettingsService {
  Future<bool> downloadAndUpdateTygerFramework(String tyDirectoryPath) async {
    try {
      // Placeholder: Implement actual download logic, possibly using GitHubService
      final response = await http.get(Uri.parse('https://api.github.com/repos/example/tygerframework/releases/latest'));
      if (response.statusCode == 200) {
        // Simulate downloading and updating in tyDirectoryPath
        print('Downloaded TygerFramework to $tyDirectoryPath');
        return true;
      }
      return false;
    } catch (e) {
      print('Update failed: $e');
      return false;
    }
  }

  // Save settings to shared_preferences
  Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings', settings.toJson());
  }

  // Load settings from shared_preferences
  Future<Settings?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('settings');
    if (jsonString != null) {
      return Settings.fromJson(jsonString);
    }
    return null; // Return null if no settings are saved yet
  }

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstRun') ?? true;
  }

  Future<void> completeSetup({required bool autoComplete, required String? tyDirectoryPath}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    if (autoComplete && tyDirectoryPath != null) {
      final source = Directory(tyDirectoryPath);
      final destination = Directory("${source.parent.path}/Ty the Tasmanian Tiger - Mod Managed");
      await recursiveCopyDirectory(source, destination);
      final settings = Settings(tyDirectoryPath: destination.path, launchArgs: '', updateManager: true);
      await isValidDirectory(destination.path);
      await saveSettings(settings);
    }
  }

  Future<String?> pickDirectory(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select vanilla Ty install folder...",
      lockParentWindow: true,
    );
    return result;
  }

  Future<bool> isValidDirectory(String directoryPath) async {
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
      final response = await http.get(
        Uri.parse("https://github.com/ElusiveFluffy/TygerFramework/releases/latest/download/XInput9_1_0.dll"),
      );
      if (response.statusCode != 200) {
        print("Download failed.");
        return false;
      }
      File(dll.path).writeAsBytesSync(response.bodyBytes);
    }
    return true;
  }
}
