// lib/services/mod_service.dart
import 'dart:io';
import '../models/mod.dart'; // Import the Mod model
import 'package:path_provider/path_provider.dart';

Future<Directory> getModsDirectory() async {
  // Get the appropriate directory for persistent storage (based on platform)
  final directory =
      await getApplicationSupportDirectory(); // Cross-platform solution

  final modsDirectory = Directory(
    '${directory.path}/mods',
  ); // Subdirectory for mods
  if (!modsDirectory.existsSync()) {
    await modsDirectory.create(
      recursive: true,
    ); // Create the directory if it doesn't exist
  }
  return modsDirectory;
}

Future<Directory> getDepsDirectory() async {
  // Get the appropriate directory for persistent storage (based on platform)
  final directory =
      await getApplicationSupportDirectory(); // Cross-platform solution

  final depsDirectory = Directory(
    '${directory.path}/deps',
  ); // Subdirectory for mods
  if (!depsDirectory.existsSync()) {
    await depsDirectory.create(
      recursive: true,
    ); // Create the directory if it doesn't exist
  }
  return depsDirectory;
}

Future<List<Mod>> loadMods() async {
  final modsDir = await getModsDirectory();
  if (!modsDir.existsSync()) {
    return [];
  }

  final modDirs =
      modsDir.listSync().whereType<Directory>(); // List of mod folders

  final mods = <Mod>[];
  for (var modDir in modDirs) {
    final mod = await Mod.fromDirectory(
      modDir,
    ); // Load the mod from the directory
    mods.add(mod);
  }

  return mods;
}
