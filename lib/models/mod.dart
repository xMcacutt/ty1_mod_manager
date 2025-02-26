import 'dart:convert';
import 'dart:io';

class Mod {
  final String name;
  final String version;
  final String description;
  final List<String> dependencies;
  final List<String> conflicts;
  final File icon;
  final File patchFile;
  final File dllFile;
  final String author;
  final String lastUpdated;

  Mod({
    required this.name,
    required this.version,
    required this.description,
    required this.dependencies,
    required this.conflicts,
    required this.icon,
    required this.patchFile,
    required this.dllFile,
    required this.lastUpdated,
    required this.author,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mod && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

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
    final iconFile = File('${modDir.path}/favico.ico');
    final patchFile = File('${modDir.path}/Patch_PC.rkv');
    final dllFile = File('${modDir.path}/${modInfo['dll_name'] ?? ''}');

    return Mod(
      name: name,
      version: version,
      description: description,
      dependencies: dependencies,
      conflicts: conflicts,
      icon: iconFile,
      dllFile: dllFile,
      patchFile: patchFile,
      author: author,
      lastUpdated: lastUpdated,
    );
  }
}
