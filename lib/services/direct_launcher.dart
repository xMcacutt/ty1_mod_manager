import 'package:shared_preferences/shared_preferences.dart';

import '../models/mod.dart';
import '../providers/code_provider.dart';
import '../providers/settings_provider.dart';
import 'code_service.dart';
import 'settings_service.dart';

import 'mod_service.dart';

class DirectLaunchContext {
  late final SettingsService settingsService;
  late final ModService modService;
  late final CodeService codeService;

  late final SettingsProvider settingsProvider;
  late final CodeProvider codeProvider;

  DirectLaunchContext() {
    settingsService = SettingsService();
    modService = ModService();
    codeService = CodeService();

    settingsProvider = SettingsProvider();
    codeProvider = CodeProvider();

    codeProvider.initialize(codeService);
  }
}

Future<void> prepareGame({
  required String game,
  required CodeProvider codeProvider,
  required ModService modService,
}) async {
  await codeProvider.loadCodes(game);
  await modService.loadMods(game);
}

Future<List<Mod>> resolveMods({
  required ModService modService,
  required String game,
  List<String>? overrideMods,
}) async {
  final allMods = await modService.loadMods(game);

  if (overrideMods != null) {
    return allMods.where((m) => overrideMods.contains(m.name)).toList();
  }

  final prefs = await SharedPreferences.getInstance();
  final savedNames = prefs.getStringList('selected_mods_${game.toLowerCase().replaceAll(' ', '_')}') ?? [];

  return allMods.where((m) => savedNames.contains(m.name)).toList();
}
