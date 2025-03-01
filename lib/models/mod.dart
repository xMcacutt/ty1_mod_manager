import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ty1_mod_manager/services/mod_service.dart';

class Mod {
  final String name;
  final String version;
  final String description;
  final List<dynamic> dependencies;
  final List<String> conflicts;
  final String? directoryIconPath;
  final File? iconFile;
  final File? patchFile;
  final File? dllFile;
  final String author;
  final String lastUpdated;
  final String dllName;
  final String downloadUrl;

  Mod({
    required this.name,
    required this.version,
    required this.description,
    required this.dependencies,
    required this.conflicts,
    this.iconFile,
    this.patchFile,
    this.dllFile,
    required this.lastUpdated,
    required this.author,
    required this.directoryIconPath,
    required this.dllName,
    required this.downloadUrl,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Mod) {
      return other.name == name;
    }
    return false;
  }

  @override
  int get hashCode => name.hashCode;

  static Mod? none() {
    return null;
  }

  Future<bool> install() async {
    // Replace button with load wheel
    var modsDir = await getModsDirectory();
    var modDir = Directory('${modsDir.path}/$name');
    if (await modDir.exists()) {
      var modInfoFile = File('${modDir.path}/mod_info.json');
      final modInfoJson = await modInfoFile.readAsString();
      final modInfo = jsonDecode(modInfoJson);
      var myVersion = modInfo['version'];
      if (myVersion == null || myVersion == version) {
        return false;
      }
    } else {
      modDir.create();
    }
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      print("Could not access file at url $downloadUrl");
      if (await modDir.list().isEmpty) modDir.delete();
      return false;
    }
    final tempDir = await getTemporaryDirectory();
    final zipFilePath = "${tempDir.path}/$name.zip";
    await File(zipFilePath).writeAsBytes(response.bodyBytes);
    final bytes = await File(zipFilePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filePath = "${modDir.path}/${file.name}";
      if (file.isFile) {
        await File(filePath).create(recursive: true);
        await File(filePath).writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
    for (final dep in dependencies) {
      final depName = dep['dep_name'];
      final depUrl = dep['dep_url'];
      final depVersion = dep['dep_version'];
      if (depName == null || depUrl == null || depVersion == null) continue;
      var depsDir = await getDepsDirectory();
      var depDir = Directory('${depsDir.path}/$depName');
      var depVerDir = Directory('${depsDir.path}/$depName/$depVersion');
      if (await depVerDir.exists()) continue;
      if (!await depDir.exists()) await depDir.create();
      await depVerDir.create();
      final response = await http.get(Uri.parse(depUrl));
      if (response.statusCode != 200) {
        print("Could not access file at url $depUrl");
        if (await depDir.list().isEmpty) depDir.delete();
        continue;
      }
      final depFilePath = "${depVerDir.path}/$depName.dll";
      await File(depFilePath).writeAsBytes(response.bodyBytes);
    }
    return true;
  }

  // Factory method to create a Mod instance from mod_info.json and other files
  static Future<Mod> fromDirectory(Directory modDir) async {
    final modInfoFile = File('${modDir.path}/mod_info.json');
    final modInfoJson = await modInfoFile.readAsString();
    final modInfo = jsonDecode(modInfoJson);

    final version = modInfo['version'] ?? '';
    final name = modInfo['name'] ?? '';
    final author = modInfo['author'] ?? '';
    final lastUpdated = modInfo['last_updated'] ?? '';
    final description = modInfo['description'] ?? '';
    final dependencies = List<String>.from(modInfo['dependencies'] ?? []);
    final conflicts = List<String>.from(modInfo['conflicts'] ?? []);
    final directoryIconPath = modInfo['icon_url'] ?? '';
    final iconFile = File('${modDir.path}/favico.ico');
    final patchFile = File('${modDir.path}/Patch_PC.rkv');
    final dllName = modInfo['dll_name'] ?? '';
    final dllFile = File('${modDir.path}/$dllName.dll');
    final downloadUrl = modInfo['download_url'] ?? '';

    return Mod(
      name: name,
      version: version,
      description: description,
      dependencies: dependencies,
      conflicts: conflicts,
      iconFile: iconFile,
      dllFile: dllFile,
      patchFile: patchFile,
      author: author,
      lastUpdated: lastUpdated,
      directoryIconPath: directoryIconPath,
      dllName: dllName,
      downloadUrl: downloadUrl,
    );
  }

  static Mod fromJson(dynamic modInfo) {
    final version = modInfo['version'] ?? '';
    final name = modInfo['name'] ?? '';
    final author = modInfo['author'] ?? '';
    final lastUpdated = modInfo['last_updated'] ?? '';
    final description = modInfo['description'] ?? '';
    final dependencies = List<dynamic>.from(modInfo['dependencies'] ?? []);
    final conflicts = List<String>.from(modInfo['conflicts'] ?? []);
    final directoryIconPath = modInfo['icon_url'] ?? '';
    final dllName = modInfo['dll_name'] ?? '';
    final downloadUrl = modInfo['download_url'] ?? '';

    return Mod(
      version: version,
      name: name,
      author: author,
      lastUpdated: lastUpdated,
      description: description,
      dependencies: dependencies,
      conflicts: conflicts,
      directoryIconPath: directoryIconPath,
      dllName: dllName,
      downloadUrl: downloadUrl,
    );
  }
}
