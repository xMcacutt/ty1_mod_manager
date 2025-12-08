import 'package:flutter/material.dart';
import 'package:ty_mod_manager/providers/code_provider.dart';
import 'package:ty_mod_manager/providers/game_provider.dart';
import 'package:ty_mod_manager/providers/settings_provider.dart';
import 'package:ty_mod_manager/services/dialog_service.dart';
import 'package:ty_mod_manager/services/ffi_win32.dart';
import 'dart:io';

import 'package:ty_mod_manager/models/mod.dart';
import 'package:ty_mod_manager/services/mod_service.dart';

class LauncherService {
  final ModService modService;
  final CodeProvider codeProvider;
  final SettingsProvider settingsProvider;
  final DialogService dialogService;

  LauncherService(this.modService, this.codeProvider, this.settingsProvider, this.dialogService);

  Future<void> launchGame(List<Mod> selectedMods, String selectedGame) async {
    var settings = await settingsProvider.loadSettings();
    if (settings == null) {
      await dialogService.showError("Error", "Settings could not be loaded.");
      return;
    }

    final conflicts = await modService.findConflicts(selectedMods);
    if (conflicts.isNotEmpty) {
      final shouldLaunch = await dialogService.showConfirmation(
        "Conflicts Detected",
        "The following conflicts were found:\n\n${conflicts.join("\n")}",
        confirmText: "Launch Anyway",
        cancelText: "Cancel",
      );

      if (!shouldLaunch) return;
    }

    await modService.prepareGameDirectory(settings.tyDirectoryPath);

    final depVersions = <String, String>{};
    for (final mod in selectedMods) {
      for (final dep in mod.dependencies) {
        final depName = dep.name;
        final depVer = dep.version;

        if (depVersions.containsKey(depName)) {
          final existingVer = depVersions[depName]!;
          if (modService.compareVersions(depVer, existingVer) <= 0) {
            continue;
          }
        }

        depVersions[depName] = depVer;
        await modService.copyDependency(depName, depVer, settings.tyDirectoryPath);
      }
      await modService.copyModFiles(mod, settings.tyDirectoryPath);
    }

    final argsString = settings.launchArgs;
    final launchArgs = argsString.split(' ');
    final result = await Process.start(
      '${settings.tyDirectoryPath}/${GameProvider.getExecutableName(selectedGame)}',
      launchArgs,
      workingDirectory: settings.tyDirectoryPath,
    );

    MemoryEditor.init(result.pid);
    await MemoryEditor.waitForProcessToStart(result.pid);
    await codeProvider.applyActiveCodes();
    result.exitCode.then((exitCode) {
      MemoryEditor.deinit();
      print('Process exited with code: $exitCode');
    });
  }
}
