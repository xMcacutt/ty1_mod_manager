// lib/services/mod_service.dart
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

import '../models/mod.dart'; // Import the Mod model
import 'package:path_provider/path_provider.dart';

Future<Directory> getModsDirectory() async {
  // Get the appropriate directory for persistent storage (based on platform)
  final directory = await getApplicationSupportDirectory(); // Cross-platform solution

  final modsDirectory = Directory('${directory.path}/mods'); // Subdirectory for mods
  if (!modsDirectory.existsSync()) {
    await modsDirectory.create(recursive: true); // Create the directory if it doesn't exist
  }
  return modsDirectory;
}

Future<Directory> getDepsDirectory() async {
  // Get the appropriate directory for persistent storage (based on platform)
  final directory = await getApplicationSupportDirectory(); // Cross-platform solution

  final depsDirectory = Directory('${directory.path}/deps'); // Subdirectory for mods
  if (!depsDirectory.existsSync()) {
    await depsDirectory.create(recursive: true); // Create the directory if it doesn't exist
  }
  return depsDirectory;
}

Future<List<Mod>> loadMods() async {
  final modsDir = await getModsDirectory();
  if (!modsDir.existsSync()) {
    return [];
  }

  final modDirs = modsDir.listSync().whereType<Directory>();

  final mods = <Mod>[];
  for (var modDir in modDirs) {
    final mod = await Mod.fromDirectory(modDir);
    mods.add(mod);
  }

  return mods;
}

Future<bool> addCustomMod(FilePickerResult result) async {
  if (result.files.isEmpty) return false;
  var zip = File(result.files.single.path!);
  var tempDir = await getTemporaryDirectory();
  final zipFilePath = "${tempDir.path}/${result.files.single.name}";
  await zip.copy(zipFilePath);
  final bytes = await File(zipFilePath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  if (archive.files.length > 4) return false;
  if (archive.files.length < 3) return false;
  if (!archive.files.any((x) => x.name == "mod_info.json")) return false;
  var tempCopyDir = await Directory('${tempDir.path}/tyMMmod').create();
  for (final file in archive.files) {
    final filePath = "${tempCopyDir.path}/${file.name}";
    await File(filePath).create(recursive: true);
    await File(filePath).writeAsBytes(file.content as List<int>);
  }
  Mod mod = await Mod.fromDirectory(tempCopyDir);
  var modsDir = await getModsDirectory();
  var modDir = Directory('${modsDir.path}/${mod.name}');
  if (!await mod.createModDir(modDir)) {
    await tempCopyDir.delete(recursive: true);
    return false;
  }
  for (var entry in tempCopyDir.listSync()) {
    if (entry is File) await entry.copy('${modDir.path}/${entry.uri.pathSegments.last}');
  }
  if (!await mod.installDeps()) {
    await tempCopyDir.delete(recursive: true);
    return false;
  }
  await tempCopyDir.delete(recursive: true);
  return true;
}

Future<List<String>> findConflicts(List<Mod> mods) async {
  Set<String> allConflicts = {};
  for (var mod in mods) {
    allConflicts.addAll(mod.conflicts.where((x) => mods.any((y) => y.name == x)));
  }
  return allConflicts.toList();
}

int compareVersions(String version1, String version2) {
  var v1Parts = version1.split('.').map(int.parse).toList();
  var v2Parts = version2.split('.').map(int.parse).toList();

  var length = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
  for (int i = 0; i < length; i++) {
    int v1 = i < v1Parts.length ? v1Parts[i] : 0;
    int v2 = i < v2Parts.length ? v2Parts[i] : 0;

    if (v1 > v2) {
      return 1; // version1 is newer
    } else if (v1 < v2) {
      return -1; // version2 is newer
    }
  }

  return 0; // versions are the same
}
