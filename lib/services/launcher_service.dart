import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ty1_mod_manager/providers/code_provider.dart';
import 'package:ty1_mod_manager/providers/settings_provider.dart';
import 'package:ty1_mod_manager/services/code_service.dart';
import 'package:ty1_mod_manager/services/ffi_win32.dart';
import 'dart:io';

import 'package:ty1_mod_manager/models/mod.dart';
import 'package:ty1_mod_manager/services/mod_service.dart';

class LauncherService {
  final ModService modService;
  final CodeProvider codeProvider;
  final SettingsProvider settingsProvider;

  LauncherService(this.modService, this.codeProvider, this.settingsProvider);

  Future<void> launchGame(BuildContext context, List<Mod> selectedMods) async {
    var settings = await settingsProvider.loadSettings();
    if (settings == null) {
      await showErrorBox(context, "Settings could not be loaded.");
      return;
    }

    final conflicts = await modService.findConflicts(selectedMods);
    final conflictMessages = conflicts.join("\n");

    bool shouldLaunch = true;
    if (conflicts.isNotEmpty) {
      shouldLaunch =
          await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Conflicts Detected"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text("The following conflicts were found:"), SizedBox(height: 10), Text(conflictMessages)],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Cancel")),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Launch Anyway")),
                ],
              );
            },
          ) ??
          false;
    }

    if (!shouldLaunch) return;

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
      '${settings.tyDirectoryPath}/Ty.exe',
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

  Future<void> showErrorBox(BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Okay"))],
        );
      },
    );
  }
}
