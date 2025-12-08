import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
      notifyListeners();
      await dirProvider?.loadModData();
    }
  }
}
