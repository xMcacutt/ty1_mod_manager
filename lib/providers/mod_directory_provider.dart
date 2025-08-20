import 'package:flutter/foundation.dart';
import 'package:ty1_mod_manager/models/mod.dart';
import 'package:ty1_mod_manager/providers/game_provider.dart';
import 'package:ty1_mod_manager/services/mod_service.dart';

class ModDirectoryProvider with ChangeNotifier {
  late ModService _modService;
  late GameProvider _gameProvider;

  void initialize(ModService modService, GameProvider gameProvider) {
    _modService = modService;
    _gameProvider = gameProvider;
    loadModData();
  }

  List<Mod> _allMods = [];
  List<Mod> _displayedMods = [];
  List<Mod> _installedMods = [];
  bool _isLoading = false;
  Set<String> _modsInstalling = {};

  List<Mod> get allMods => _allMods;
  List<Mod> get displayedMods => _displayedMods;
  List<Mod> get installedMods => _installedMods;
  bool get isLoading => _isLoading;
  Set<String> get modsInstalling => _modsInstalling;

  Future<void> loadModData() async {
    _isLoading = true;
    notifyListeners();

    final remoteMods = await _modService.fetchRemoteMods(_gameProvider.selectedGame);
    final localMods = await _modService.loadMods(_gameProvider.selectedGame);

    _installedMods =
        remoteMods.where((remoteMod) {
          final localMod = localMods.firstWhere(
            (localMod) => localMod.name == remoteMod.name,
            orElse:
                () => Mod(
                  name: '',
                  version: '',
                  description: '',
                  author: '',
                  lastUpdated: '',
                  dllName: '',
                  dependencies: [],
                  conflicts: [],
                  downloadUrl: '',
                  website: '',
                  games: [],
                ),
          );
          return localMod.name.isNotEmpty && _modService.compareVersions(localMod.version, remoteMod.version) != -1;
        }).toList();

    final updatableMods =
        remoteMods.where((remoteMod) {
          final localMod = localMods.firstWhere(
            (localMod) => localMod.name == remoteMod.name,
            orElse:
                () => Mod(
                  name: '',
                  version: '',
                  description: '',
                  author: '',
                  lastUpdated: '',
                  dllName: '',
                  dependencies: [],
                  conflicts: [],
                  downloadUrl: '',
                  website: '',
                  games: [],
                ),
          );
          return localMod.name.isEmpty || _modService.compareVersions(localMod.version, remoteMod.version) != 1;
        }).toList();

    _allMods = [..._installedMods, ...updatableMods];
    _displayedMods = updatableMods;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> installMod(Mod mod) async {
    _modsInstalling.add(mod.name);
    notifyListeners();
    await _modService.install(mod);
    _modsInstalling.remove(mod.name);

    final localMods = await _modService.loadMods(_gameProvider.selectedGame);
    _installedMods =
        _allMods.where((remoteMod) {
          final localMod = localMods.firstWhere(
            (localMod) => localMod.name == remoteMod.name,
            orElse:
                () => Mod(
                  name: '',
                  version: '',
                  description: '',
                  author: '',
                  lastUpdated: '',
                  dllName: '',
                  dependencies: [],
                  conflicts: [],
                  downloadUrl: '',
                  website: '',
                  games: [],
                ),
          );
          return localMod.name.isNotEmpty && _modService.compareVersions(localMod.version, remoteMod.version) != -1;
        }).toList();

    notifyListeners();
  }

  void searchMods(String query) {
    _displayedMods = _allMods.where((mod) => mod.name.toLowerCase().contains(query.toLowerCase())).toList();
    notifyListeners();
  }
}
