import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ty_mod_manager/providers/game_provider.dart';
import 'package:ty_mod_manager/providers/mod_directory_provider.dart';
import 'package:ty_mod_manager/services/settings_service.dart';
import 'package:ty_mod_manager/models/mod.dart';
import 'package:ty_mod_manager/services/mod_service.dart';

class ModProvider with ChangeNotifier {
  late ModService _modService;
  late SettingsService _settingsService;
  late GameProvider _gameProvider;
  String? _currentGame;

  void initialize(ModService modService, SettingsService settingsService, GameProvider gameProvider) {
    _modService = modService;
    _settingsService = settingsService;
    _gameProvider = gameProvider;
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

    _mods = await _modService.loadMods(_gameProvider.selectedGame);

    await _loadSelectedMods();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveSelectedMods() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'selected_mods_${_gameProvider.selectedGame.replaceAll(' ', '_').toLowerCase()}';

    await prefs.setStringList(key, _selectedMods.map((m) => m.name).toList());
  }

  Future<void> _loadSelectedMods() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'selected_mods_${_gameProvider.selectedGame.replaceAll(' ', '_').toLowerCase()}';
    final names = prefs.getStringList(key) ?? [];
    _selectedMods = _mods.where((mod) => names.contains(mod.name)).toList();
  }

  void toggleModSelection(Mod mod) {
    if (_selectedMods.contains(mod)) {
      _selectedMods.remove(mod);
    } else {
      _selectedMods.add(mod);
    }

    _saveSelectedMods();
    notifyListeners();
  }

  Future<bool> addCustomMod(FilePickerResult result) async {
    final success = await _modService.addCustomMod(result);
    if (success) {
      if (_currentGame != null) {
        await loadMods();
      }
    }
    return success;
  }

  Future<void> uninstallMod(Mod mod, {ModDirectoryProvider? dirProvider}) async {
    final success = await _modService.uninstallMod(mod);
    if (success) {
      _mods.removeWhere((m) => m.name == mod.name);
      _selectedMods.removeWhere((m) => m.name == mod.name);
      _saveSelectedMods();
      notifyListeners();
      await dirProvider?.loadModData();
    }
  }
}
