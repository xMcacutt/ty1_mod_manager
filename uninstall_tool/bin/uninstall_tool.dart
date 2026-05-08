import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:win32_registry/win32_registry.dart';

Future<Directory?> getManagerAppDataDirectory() async {
  final appData = Platform.environment['APPDATA'];
  final managerDirectory = Directory('$appData/io.mcacutt/ty_mod_manager');
  if (!await managerDirectory.exists()) return null;
  return managerDirectory;
}

Future<String?> findSteamGamePath(int appId) async {
  final steamPath = _getSteamPath();

  if (steamPath == null) return null;

  final libraryFile = File(path.join(steamPath, 'steamapps', 'libraryfolders.vdf'));

  if (!await libraryFile.exists()) return null;

  final libraryContents = await libraryFile.readAsString();
  final libraries = _parseLibraryFolders(libraryContents);

  for (final library in libraries) {
    final manifestPath = path.join(library, 'steamapps', 'appmanifest_$appId.acf');
    final manifestFile = File(manifestPath);

    if (!await manifestFile.exists()) continue;

    final manifestContents = await manifestFile.readAsString();
    final installDir = _parseInstallDir(manifestContents);

    if (installDir == null) continue;

    final gamePath = path.join(library, 'steamapps', 'common', installDir);

    if (await Directory(gamePath).exists()) return gamePath;
  }
  return null;
}

String? _getSteamPath() {
  try {
    final key = Registry.openPath(RegistryHive.currentUser, path: r'Software\Valve\Steam');
    return key.getStringValue('SteamPath');
  } catch (_) {
    return null;
  }
}

List<String> _parseLibraryFolders(String contents) {
  final regex = RegExp(r'"path"\s+"(.+?)"');
  final matches = regex.allMatches(contents);
  return matches.map((m) {
    final raw = m.group(1)!;
    return raw.replaceAll(r'\\', r'\');
  }).toList();
}

String? _parseInstallDir(String contents) {
  final regex = RegExp(r'"installdir"\s+"(.+?)"');
  final match = regex.firstMatch(contents);
  if (match == null) return null;
  return match.group(1);
}

void _addPathFromPrefs(Map<String, dynamic> prefs, String key, Set<String> targets) {
  final rawSettings = prefs[key];

  if (rawSettings == null) {
    return;
  }

  try {
    final settings = jsonDecode(rawSettings);

    final tyDirectoryPath = settings['tyDirectoryPath'];

    if (tyDirectoryPath is String && tyDirectoryPath.isNotEmpty) {
      targets.add(path.normalize(tyDirectoryPath));
    }
  } catch (_) {}
}

Future<void> _tryAddSteamFallback({
  required int appId,
  required String folderName,
  required Set<String> targets,
}) async {
  final steamGamePath = await findSteamGamePath(appId);
  print("Steam Path: $steamGamePath");
  if (steamGamePath == null) return;
  final modManagedDir = path.join(Directory(steamGamePath).parent.path, folderName);
  print("Mod Managed: $modManagedDir");
  final dir = Directory(modManagedDir);
  if (await dir.exists()) targets.add(path.normalize(modManagedDir));
}

Future<void> delete() async {
  final deletionTargets = <String>{};
  final managerAppDataDir = await getManagerAppDataDirectory();
  if (managerAppDataDir != null) {
    print("AppData dir for mod manager found");
    final prefsFile = File(path.join(managerAppDataDir.path, "shared_preferences.json"));
    if (await prefsFile.exists()) {
      print("Prefs file for mod manager found");
      final prefsJson = jsonDecode(await prefsFile.readAsString());
      _addPathFromPrefs(prefsJson, 'flutter.settings', deletionTargets);
      _addPathFromPrefs(prefsJson, 'flutter.settings_ty_2', deletionTargets);
      _addPathFromPrefs(prefsJson, 'flutter.settings_ty_3', deletionTargets);
    }
  }

  print("Looking for steam installs");

  print("Ty1:");
  await _tryAddSteamFallback(
    appId: 411960,
    folderName: 'Ty the Tasmanian Tiger - Mod Managed',
    targets: deletionTargets,
  );

  print("Ty2:");
  await _tryAddSteamFallback(
    appId: 411970,
    folderName: 'Ty the Tasmanian Tiger 2 - Mod Managed',
    targets: deletionTargets,
  );

  print("Ty3:");
  await _tryAddSteamFallback(
    appId: 411980,
    folderName: 'Ty the Tasmanian Tiger 3 - Mod Managed',
    targets: deletionTargets,
  );

  for (final target in deletionTargets) {
    final dir = Directory(target);
    if (await dir.exists()) {
      print('Deleting: $target');
      await dir.delete(recursive: true);
    }
  }

  if (managerAppDataDir != null && await managerAppDataDir.exists()) {
    print("Deleting manager AppData dir at ${managerAppDataDir.path}");
    await managerAppDataDir.delete(recursive: true);
  }

  print("Deleting self... Goodbye :)");
  final thisExePath = Platform.resolvedExecutable;
  final cwd = Directory(path.dirname(thisExePath));
  final mmExePath = File(path.join(cwd.path, "ty_mod_manager.exe"));
  if (await mmExePath.exists()) {
    await Process.start('cmd', [
      '/c',
      'timeout /t 2 /nobreak > nul && rmdir /s /q "${cwd.path}"',
    ], mode: ProcessStartMode.detached);
  }
  exit(0);
}

Future<void> main(List<String> arguments) async {
  delete();
}
