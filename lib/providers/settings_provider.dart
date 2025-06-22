import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ty1_mod_manager/models/settings.dart';
import 'package:ty1_mod_manager/services/update_manager_service.dart';
import '../services/settings_service.dart';

class SettingsProvider with ChangeNotifier {
  late SettingsService _settingsService;
  late UpdateManagerService _updateManagerService;

  void initialize(SettingsService settingsService, UpdateManagerService updateManagerService) {
    _settingsService = settingsService;
    _updateManagerService = updateManagerService;
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
    final settings = await _settingsService.loadSettings();
    if (settings != null) {
      _tyDirectoryPath = settings.tyDirectoryPath;
      _autoUpdateModManager = settings.updateManager;
      _launchArgs = settings.launchArgs;
    }
    _isLoading = false;
    notifyListeners();
    return settings;
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

  Future<bool> saveSettings(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    if (!await _settingsService.isValidDirectory(_tyDirectoryPath)) {
      _isLoading = false;
      notifyListeners();
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Invalid Directory"),
              content: Text("Please select a valid Ty directory path."),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Okay"))],
            ),
      );
      return false;
    }
    final settings = Settings(
      tyDirectoryPath: _tyDirectoryPath,
      updateManager: _autoUpdateModManager,
      launchArgs: _launchArgs,
    );
    await _settingsService.saveSettings(settings);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> checkForUpdates(BuildContext context) async {
    _isUpdating = true;
    notifyListeners();
    final updateSuccessful = await _settingsService.downloadAndUpdateTygerFramework(_tyDirectoryPath);
    if (!updateSuccessful) {
      _isUpdating = false;
      notifyListeners();
      return false;
    }
    await _updateManagerService.checkForUpdate(updateFramework: false);
    _isUpdating = false;
    notifyListeners();
    return true;
  }
}
