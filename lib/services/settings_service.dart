import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  String tyDirectoryPath;
  bool autoUpdateMods;
  bool autoUpdateManager;

  Settings({
    required this.tyDirectoryPath,
    required this.autoUpdateMods,
    required this.autoUpdateManager,
  });

  // Convert Settings object to a Map (for JSON encoding)
  Map<String, dynamic> toMap() {
    return {
      'tyDirectoryPath': tyDirectoryPath,
      'autoUpdateMods': autoUpdateMods,
      'autoUpdateManager': autoUpdateManager,
    };
  }

  // Convert Map to Settings object (for decoding)
  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      tyDirectoryPath: map['tyDirectoryPath'] ?? '',
      autoUpdateMods: map['autoUpdateMods'] ?? false,
      autoUpdateManager: map['autoUpdateManager'] ?? false,
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
