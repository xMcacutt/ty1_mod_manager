import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ty1_mod_manager/providers/code_provider.dart';
import 'package:ty1_mod_manager/providers/mod_provider.dart';
import 'package:ty1_mod_manager/providers/settings_provider.dart';

class GameProvider extends ChangeNotifier {
  String _selectedGame = 'Ty 1';
  String get selectedGame => _selectedGame;

  final Map<String, String> _bannerImages = {
    'Ty 1': 'resource/Ty1_Env.png',
    'Ty 2': 'resource/Ty2_Env.png',
    'Ty 3': 'resource/Ty3_Env.png',
  };

  String get bannerImage => _bannerImages[_selectedGame] ?? 'resource/Ty1_Env.png';

  CodeProvider? _codeProvider;
  SettingsProvider? _settingsProvider;
  ModProvider? _modProvider;

  GameProvider(this._codeProvider) {
    _loadSelectedGame();
  }

  void setCodeProvider(CodeProvider provider, SettingsProvider settingsProvider, ModProvider modProvider) {
    _codeProvider = provider;
    _settingsProvider = settingsProvider;
    _modProvider = modProvider;
  }

  Future<void> _loadSelectedGame() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedGame = prefs.getString('selected_game') ?? 'Ty 1';
    await setGame(_selectedGame);
    notifyListeners();
  }

  Future<void> setGame(String game) async {
    _selectedGame = game;
    _modProvider?.loadMods();
    _codeProvider?.loadCodes(game);
    var settings = await _settingsProvider?.loadSettings();

    if (_settingsProvider != null) {
      if (settings == null || !await Directory(settings.tyDirectoryPath).exists()) {
        _settingsProvider?.runSetup();
      }
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_game', game);
  }

  static String getExecutableName(String game) {
    switch (game) {
      case 'Ty 1':
        return 'TY.exe';
      case 'Ty 2':
        return 'TY2.exe';
      case 'Ty 3':
        return 'TY3.exe';
      default:
        return 'TY.exe';
    }
  }
}
