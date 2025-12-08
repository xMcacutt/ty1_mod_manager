import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppDataMigration {
  static const _oldAppSupportDirName = "ty1_mod_manager";
  static bool _migrated = false;

  static Future<void> migrate() async {
    if (_migrated) return;

    final targetDir = await getApplicationSupportDirectory();
    final targetPath = targetDir.path;
    final parentDir = Directory(path.dirname(targetPath));
    final oldDir = Directory(path.join(parentDir.path, _oldAppSupportDirName));
    final targetDirectory = Directory(targetPath);

    if (oldDir.path == targetPath) {
      _migrated = true;
      return;
    }

    final oldExists = await oldDir.exists();
    if (!oldExists) {
      _migrated = true;
      return;
    }

    final targetExists = await targetDirectory.exists();
    final targetEmpty = targetExists ? await _isDirectoryEmpty(targetDirectory) : true;

    if (targetExists && targetEmpty) {
      try {
        await targetDirectory.delete(recursive: true);
      } catch (_) {}
    }

    if (await targetDirectory.exists() && !targetEmpty) {
      _migrated = true;
      return;
    }

    try {
      await oldDir.rename(targetPath);
      _migrated = true;
      return;
    } catch (_) {}

    await _copyDirectory(oldDir, targetDirectory);
    try {
      await oldDir.delete(recursive: true);
    } catch (_) {}

    _migrated = true;
  }

  static Future<bool> _isDirectoryEmpty(Directory directory) async {
    try {
      return (await directory.list().isEmpty);
    } catch (_) {
      return true;
    }
  }

  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final relativePath = path.relative(entity.path, from: source.path);
      final newPath = path.join(destination.path, relativePath);
      if (entity is File) {
        await File(newPath).create(recursive: true);
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
      }
    }
  }
}
