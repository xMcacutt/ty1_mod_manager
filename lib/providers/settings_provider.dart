import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ty_mod_manager/main.dart';
import 'package:ty_mod_manager/models/settings.dart';
import 'package:ty_mod_manager/providers/game_provider.dart';
import 'package:ty_mod_manager/services/update_manager_service.dart';
import 'package:ty_mod_manager/services/utils.dart';
import '../services/settings_service.dart';

class SettingsProvider with ChangeNotifier {
  late SettingsService _settingsService;
  late UpdateManagerService _updateManagerService;
  late GameProvider _gameProvider;

  void initialize(
    SettingsService settingsService,
    UpdateManagerService updateManagerService,
    GameProvider gameProvider,
  ) {
    _settingsService = settingsService;
    _updateManagerService = updateManagerService;
    _gameProvider = gameProvider;
  }

  String _tyDirectoryPath = '';
  bool _autoUpdateModManager = false;
  String _launchArgs = '';
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;

  String get tyDirectoryPath => _tyDirectoryPath;
  bool get autoUpdateModManager => _autoUpdateModManager;
  String get launchArgs => _launchArgs;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get error => _error;

  Future<Settings?> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    final settings = await _settingsService.loadSettings(_gameProvider.selectedGame);
    if (settings != null) {
      _tyDirectoryPath = settings.tyDirectoryPath;
      _autoUpdateModManager = settings.updateManager;
      _launchArgs = settings.launchArgs;
    } else {
      _tyDirectoryPath = '';
      _autoUpdateModManager = false;
      _launchArgs = '';
    }
    _isLoading = false;
    notifyListeners();
    return settings;
  }

  Future<bool> checkForUpdates(BuildContext context) async {
    _isUpdating = true;
    notifyListeners();

    bool updateSuccessful = await _updateManagerService.downloadAndUpdateTygerFramework(_tyDirectoryPath);

    if (!updateSuccessful) {
      await dialogService.showError(
        "Update Failed",
        "Could not update TygerFramework.\nMake sure you have a valid Ty directory path and internet connection.",
      );
      _isUpdating = false;
      notifyListeners();
      return false;
    }

    String? batchFilePath = await _updateManagerService.checkForUpdate(updateFramework: false);

    _isUpdating = false;
    notifyListeners();

    if (batchFilePath != null) {
      _updateManagerService.updateApp(batchFilePath);
    }

    return true;
  }

  void updateTyDirectoryPath(String path) {
    _tyDirectoryPath = path;
    notifyListeners();
  }

  Future<void> selectDirectory() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      updateTyDirectoryPath(selectedDirectory);
    }
  }

  void toggleAutoUpdate(bool value) {
    _autoUpdateModManager = value;
    notifyListeners();
  }

  void updateLaunchArgs(String args) {
    _launchArgs = args;
    notifyListeners();
  }

  Future<String?> pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select vanilla Ty install folder...",
      lockParentWindow: true,
    );
    return result;
  }

  Future<bool> saveSettings(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    if (!await _settingsService.isValidDirectory(_gameProvider.selectedGame, _tyDirectoryPath)) {
      _isLoading = false;
      notifyListeners();
      dialogService.showError("Invalid Directory", "Please select a valid Ty directory path.");
      return false;
    }
    final settings = Settings(
      tyDirectoryPath: _tyDirectoryPath,
      updateManager: _autoUpdateModManager,
      launchArgs: _launchArgs,
    );
    await _settingsService.saveSettings(_gameProvider.selectedGame, settings);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> checkFirstRun() async {
    if (!await _settingsService.isFirstRun()) return;
    var game = await dialogService.showGameSelection();
    if (game == null) return;
    _gameProvider.setGame(game);
  }

  void runSetup() {
    dialogService.showSetup(_gameProvider.selectedGame, this);
  }

  Future<void> completeSetup({
    required String game,
    required bool autoComplete,
    required String? tyDirectoryPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    if (autoComplete && tyDirectoryPath != null) {
      final source = Directory(tyDirectoryPath);
      var gameString = "";
      if (game == "Ty 2") gameString = "2 ";
      if (game == "Ty 3") gameString = "3 ";
      final destination = Directory("${source.parent.path}/Ty the Tasmanian Tiger ${gameString}- Mod Managed");
      await recursiveCopyDirectory(source, destination);
      final settings = Settings(tyDirectoryPath: destination.path, launchArgs: '', updateManager: true);
      await _settingsService.isValidDirectory(game, destination.path);
      await _settingsService.saveSettings(game, settings);
      tyDirectoryPath = destination.path;
      await loadSettings();
    }
  }
}
