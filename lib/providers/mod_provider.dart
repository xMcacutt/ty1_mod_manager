import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:ty1_mod_manager/services/settings_service.dart';
import 'package:ty1_mod_manager/models/mod.dart';
import 'package:ty1_mod_manager/services/mod_service.dart';

class ModProvider with ChangeNotifier {
  late ModService _modService;
  late SettingsService _settingsService;

  void initialize(ModService modService, SettingsService settingsService) {
    _modService = modService;
    _settingsService = settingsService;
  }

  List<Mod> _selectedMods = [];
  List<Mod> _mods = [];
  bool _isFirstRun = true;
  bool _isLoading = false;

  List<Mod> get selectedMods => _selectedMods;
  List<Mod> get mods => _mods;
  bool get isFirstRun => _isFirstRun;
  bool get isLoading => _isLoading;

  Future<void> loadMods() async {
    _isLoading = true;
    notifyListeners();
    _mods = await _modService.loadMods();
    _isLoading = false;
    notifyListeners();
  }

  void toggleModSelection(Mod mod) {
    if (_selectedMods.contains(mod)) {
      _selectedMods.remove(mod);
    } else {
      _selectedMods.add(mod);
    }
    notifyListeners();
  }

  Future<void> checkFirstRun() async {
    _isFirstRun = await _settingsService.isFirstRun();
    notifyListeners();
  }

  Future<void> completeSetup({required bool autoComplete, required String? tyDirectoryPath}) async {
    await _settingsService.completeSetup(autoComplete: autoComplete, tyDirectoryPath: tyDirectoryPath);
    _isFirstRun = false;
    notifyListeners();
  }

  Future<bool> addCustomMod(FilePickerResult result) async {
    final success = await _modService.addCustomMod(result);
    if (success) {
      await loadMods();
    }
    return success;
  }
}
