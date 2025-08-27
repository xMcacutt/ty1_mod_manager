import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ty1_mod_manager/providers/game_provider.dart';
import 'package:ty1_mod_manager/services/utils.dart';
import '../models/settings.dart';

class SettingsService {
  Future<void> saveSettings(String game, Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings${getSettingsName(game)}', settings.toJson());
  }

  Future<Settings?> loadSettings(String game) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('settings${getSettingsName(game)}');
    if (jsonString != null) {
      return Settings.fromJson(jsonString);
    }
    print("No settings found");
    return null;
  }

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstRun') ?? true;
  }

  Future<bool> isValidDirectory(String game, String directoryPath) async {
    final baseDirectory = Directory(directoryPath);
    final exe = File('${baseDirectory.path}/${GameProvider.getExecutableName(game)}');
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

  static String getSettingsName(String game) {
    switch (game) {
      case 'Ty 1':
        return '';
      case 'Ty 2':
        return '_ty_2';
      case 'Ty 3':
        return '_ty_3';
      default:
        return '';
    }
  }
}
