import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  String tyDirectoryPath;
  bool updateManager;
  String launchArgs;

  Settings({
    required this.tyDirectoryPath,
    required this.updateManager,
    required this.launchArgs,
  });

  // Convert Settings object to a Map (for JSON encoding)
  Map<String, dynamic> toMap() {
    return {
      'tyDirectoryPath': tyDirectoryPath,
      'updateManager': updateManager,
      'launchArgs': launchArgs,
    };
  }

  // Convert Map to Settings object (for decoding)
  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      tyDirectoryPath: map['tyDirectoryPath'] ?? '',
      updateManager: map['updateManager'] ?? true,
      launchArgs: map['launchArgs'] ?? '',
    );
  }

  // Convert the Settings object to JSON string
  String toJson() {
    final jsonMap = toMap();
    return jsonEncode(jsonMap);
  }

  // Convert JSON string to Settings object
  factory Settings.fromJson(String json) {
    final jsonMap = jsonDecode(json);
    return Settings.fromMap(jsonMap);
  }

  // Save settings to shared_preferences
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings', toJson());
  }

  // Load settings from shared_preferences
  static Future<Settings?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('settings');
    if (jsonString != null) {
      return Settings.fromJson(jsonString);
    }
    return null; // Return null if no settings are saved yet
  }
}

Future<void> copyDirectory(Directory source, Directory destination) async {
  // Check if the source directory exists
  if (!await source.exists()) {
    print('Source directory does not exist');
    return;
  }

  // Create the destination directory if it doesn't exist
  if (!await destination.exists()) {
    await destination.create(recursive: true);
  }

  // List all files and directories in the source directory
  await for (var entity in source.list(recursive: false)) {
    if (entity is File) {
      // Copy the files to the destination directory
      await entity.copy('${destination.path}/${entity.uri.pathSegments.last}');
    } else if (entity is Directory) {
      // Recursively copy the subdirectories
      await copyDirectory(
        entity,
        Directory('${destination.path}/${entity.uri.pathSegments.last}'),
      );
    }
  }
}
