import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import '../models/mod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class ModService {
  Future<bool> createModDir(Mod mod, Directory modDir) async {
    if (await modDir.exists()) {
      final modInfoFile = File('${modDir.path}/mod_info.json');
      if (await modInfoFile.exists()) {
        final modInfoJson = await modInfoFile.readAsString();
        final modInfo = jsonDecode(modInfoJson);
        final existingVersion = modInfo['version'] as String?;
        if (existingVersion == mod.version) {
          return false;
        }
      }
    }
    await modDir.create(recursive: true);
    return true;
  }

  Future<File?> getModIconFile(Mod mod) async {
    try {
      final modDir = Directory('${(await getModsDirectory()).path}/${mod.name}');
      final iconFile = File('${modDir.path}/favico.ico');
      if (await iconFile.exists()) {
        return iconFile;
      }
      if (mod.iconUrl != null && mod.iconUrl!.isNotEmpty) {
        final response = await http.get(Uri.parse(mod.iconUrl!));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${mod.name}_icon.ico');
          await tempFile.writeAsBytes(response.bodyBytes);
          return tempFile;
        }
      }
    } catch (e) {
      print("Error fetching icon: $e");
    }
    return null;
  }

  Future<bool> uninstallMod(Mod mod) async {
    final modDir = Directory('${(await getModsDirectory()).path}/${mod.name}');
    if (await modDir.exists()) {
      await modDir.delete(recursive: true);
      return true;
    }
    return false;
  }

  Future<void> prepareGameDirectory(String tyDirectoryPath) async {
    final pluginsDir = Directory('$tyDirectoryPath/Plugins');
    if (await pluginsDir.exists()) {
      for (var file in await pluginsDir.list().toList()) {
        if (file is! Directory) {
          await file.delete();
        }
      }
    } else {
      await pluginsDir.create();
    }

    final depsDir = Directory('$tyDirectoryPath/Plugins/Dependencies');
    if (await depsDir.exists()) {
      for (var file in await depsDir.list().toList()) {
        await file.delete();
      }
    } else {
      await depsDir.create();
    }

    final patchFile = File('$tyDirectoryPath/Patch_PC.rkv');
    if (await patchFile.exists()) {
      await patchFile.delete();
    }
  }

  Future<bool> installDeps(Mod mod) async {
    final depsDir = await getDepsDirectory();
    for (final dep in mod.dependencies) {
      final depDir = Directory('${depsDir.path}/${dep.name}');
      final depVerDir = Directory('${depsDir.path}/${dep.name}/${dep.version}');
      if (await depVerDir.exists()) continue;
      if (!await depDir.exists()) await depDir.create();
      await depVerDir.create();
      final response = await http.get(Uri.parse(dep.url));
      if (response.statusCode != 200) {
        print('Could not access file at url ${dep.url}');
        if ((await depDir.list().toList()).isEmpty) await depDir.delete();
        continue;
      }
      final depFilePath = '${depVerDir.path}/${dep.name}.dll';
      await File(depFilePath).writeAsBytes(response.bodyBytes);
    }
    return true;
  }

  Future<bool> install(Mod mod) async {
    final modsDir = await getModsDirectory();
    final modDir = Directory('${modsDir.path}/${mod.name}');
    if (!await createModDir(mod, modDir)) return false;

    final response = await http.get(Uri.parse(mod.downloadUrl));
    if (response.statusCode != 200) {
      print('Could not access file at url ${mod.downloadUrl}');
      if ((await modDir.list().toList()).isEmpty) await modDir.delete();
      return false;
    }

    final tempDir = await getTemporaryDirectory();
    final zipFilePath = '${tempDir.path}/${mod.name}.zip';
    await File(zipFilePath).writeAsBytes(response.bodyBytes);
    final bytes = await File(zipFilePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filePath = '${modDir.path}/${file.name}';
      if (file.isFile) {
        final fileObj = File(filePath);
        await fileObj.create(recursive: true);
        await fileObj.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }

    final internalDepsDir = Directory('${modDir.path}/Dependencies');
    if (!(await internalDepsDir.exists())) {
      await internalDepsDir.create();
    }

    await installDeps(mod);

    final modInfoFile = File('${modDir.path}/mod_info.json');
    await modInfoFile.writeAsString(jsonEncode(mod.toJson()));

    return true;
  }

  Future<Mod> fromDirectory(Directory modDir) async {
    final modInfoFile = File('${modDir.path}/mod_info.json');
    final modInfoJson = await modInfoFile.readAsString();
    final modInfo = jsonDecode(modInfoJson);
    return Mod.fromJson(modInfo);
  }

  Future<Directory> getModsDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final modsDirectory = Directory('${directory.path}/mods');
    if (!modsDirectory.existsSync()) {
      await modsDirectory.create(recursive: true);
    }
    return modsDirectory;
  }

  Future<void> copyDependency(String depName, String depVersion, String tyDirectoryPath) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final depDir = Directory('${appSupportDir.path}/deps/$depName/$depVersion');
    if (await depDir.exists()) {
      for (var file in await depDir.list().toList()) {
        if (file is File) {
          final destFilePath = '$tyDirectoryPath/Plugins/Dependencies/${path.basename(file.path)}';
          if (!await File(destFilePath).exists()) {
            await file.copy(destFilePath);
          }
        }
      }
    }
  }

  Future<void> copyInternalDependencies(Mod mod, String tyDirectoryPath) async {
    final modDir = Directory('${(await getModsDirectory()).path}/${mod.name}');
    final internalDepsDir = Directory('${modDir.path}/Dependencies');

    if (await internalDepsDir.exists()) {
      for (var file in await internalDepsDir.list().toList()) {
        if (file is File) {
          final destFilePath = '$tyDirectoryPath/Plugins/Dependencies/${path.basename(file.path)}';
          if (!await File(destFilePath).exists()) {
            await file.copy(destFilePath);
          }
        }
      }
    }
  }

  Future<void> copyModFiles(Mod mod, String tyDirectoryPath) async {
    final modDir = Directory('${(await getModsDirectory()).path}/${mod.name}');
    final dllFile = File('${modDir.path}/${mod.dllName}.dll');
    final patchFile = File('${modDir.path}/Patch_PC.rkv');

    if (await dllFile.exists()) {
      await dllFile.copy('$tyDirectoryPath/Plugins/${mod.dllName}.dll');
    }
    if (await patchFile.exists()) {
      await patchFile.copy('$tyDirectoryPath/Patch_PC.rkv');
    }

    await copyInternalDependencies(mod, tyDirectoryPath);
  }

  Future<Directory> getDepsDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final depsDirectory = Directory('${directory.path}/deps');
    if (!depsDirectory.existsSync()) {
      await depsDirectory.create(recursive: true);
    }
    return depsDirectory;
  }

  Future<List<Mod>> loadMods(String game) async {
    final modsDir = await getModsDirectory();
    if (!modsDir.existsSync()) {
      return [];
    }

    final modDirs = modsDir.listSync().whereType<Directory>();

    final mods = <Mod>[];
    for (var modDir in modDirs) {
      final mod = await fromDirectory(modDir);
      if (mod.games.contains(game)) {
        mods.add(mod);
      }
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
    Mod mod = await fromDirectory(tempCopyDir);
    var modsDir = await getModsDirectory();
    var modDir = Directory('${modsDir.path}/${mod.name}');
    if (!await createModDir(mod, modDir)) {
      await tempCopyDir.delete(recursive: true);
      return false;
    }
    for (var entry in tempCopyDir.listSync(recursive: true)) {
      if (entry is File) {
        final relativePath = entry.path.substring(tempCopyDir.path.length + 1);
        final destFile = File('${modDir.path}/$relativePath');
        await destFile.create(recursive: true);
        await entry.copy(destFile.path);
      }
    }
    if (!await installDeps(mod)) {
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

  Future<List<Mod>> fetchRemoteMods(String game) async {
    final modDirectoryJsonUrl =
        "https://raw.githubusercontent.com/xMcacutt/ty1_mod_manager/refs/heads/master/mod_directory.json?${DateTime.now().millisecondsSinceEpoch}";
    final response = await http.get(Uri.parse(modDirectoryJsonUrl));

    if (response.statusCode != 200) {
      print("Failed to fetch mod directory");
      return [];
    }

    final modData = jsonDecode(response.body) as List<dynamic>;
    final remoteMods = <Mod>[];
    for (var modListing in modData) {
      final modInfoUrl = "${modListing['mod_info_url']}?${DateTime.now().millisecondsSinceEpoch}";
      final modResponse = await http.get(Uri.parse(modInfoUrl));
      if (modResponse.statusCode == 200) {
        var mod = Mod.fromJson(jsonDecode(modResponse.body));
        if (mod.games.contains(game)) {
          remoteMods.add(mod);
        }
      } else {
        print("Failed to fetch mod info: $modInfoUrl");
      }
    }
    return remoteMods;
  }
}
