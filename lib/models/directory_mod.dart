import 'dart:convert';
import 'dart:io';

import 'package:ty1_mod_manager/models/mod.dart';

class DirectoryMod {
  final String name;
  final String version;
  final String description;
  final List<String> dependencies;
  final List<String> conflicts;
  final File icon;
  final bool containsPatch;
  final String lastUpdated;
  final String dllName;
  final String author;

  DirectoryMod({
    required this.name,
    required this.version,
    required this.description,
    required this.dependencies,
    required this.conflicts,
    required this.icon,
    required this.dllName,
    required this.lastUpdated,
    required this.author,
    required this.containsPatch,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is DirectoryMod) {
      return other.name == name;
    }
    if (other is Mod) {
      return other.name == name;
    }
    return false;
  }

  @override
  int get hashCode => name.hashCode;

  static DirectoryMod fromJson(modInfo) {
    final version = modInfo['version'] ?? '';
    final name = modInfo['name'] ?? '';
    final author = modInfo['author'] ?? '';
    final lastUpdated = modInfo['last_updated'] ?? '';
    final description = modInfo['description'] ?? '';
    final containsPatch = modInfo['contains_patch'] ?? false;
    final dllName = modInfo['dll_name'] ?? '';
    final dependencies = List<String>.from(modInfo['dependencies'] ?? []);
    final conflicts = List<String>.from(modInfo['conflicts'] ?? []);
    final iconFile = File(modInfo['icon_url']);
    return DirectoryMod(
      name: name,
      version: version,
      description: description,
      dependencies: dependencies,
      conflicts: conflicts,
      icon: iconFile,
      author: author,
      containsPatch: containsPatch,
      lastUpdated: lastUpdated,
      dllName: dllName,
    );
  }
}
