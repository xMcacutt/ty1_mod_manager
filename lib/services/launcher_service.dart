import 'dart:typed_data';

import 'package:ty_mod_manager/main.dart';
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

  Future<void> ensureLargeAddressAware(String exePath) async {
    final file = File(exePath);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    final data = Uint8List.fromList(bytes);
    if (data.length < 0x40) return;
    final peHeaderOffset = data[0x3C] | (data[0x3D] << 8) | (data[0x3E] << 16) | (data[0x3F] << 24);
    if (data[peHeaderOffset] != 0x50 || data[peHeaderOffset + 1] != 0x45) {
      throw Exception("File is not a valid PE executable.");
    }
    final charOffset = peHeaderOffset + 4 + 18;
    if (data.length < charOffset + 2) return;
    int currentCharacteristics = data[charOffset] | (data[charOffset + 1] << 8);
    const int imageFileLargeAddressAware = 0x0020;
    if ((currentCharacteristics & imageFileLargeAddressAware) == 0) {
      currentCharacteristics |= imageFileLargeAddressAware;
      data[charOffset] = currentCharacteristics & 0xFF;
      data[charOffset + 1] = (currentCharacteristics >> 8) & 0xFF;
      await file.writeAsBytes(data);
    }
  }

  Future<void> launchGame(
    List<Mod> selectedMods,
    String selectedGame, {
    bool injectCodes = true,
    bool headless = false,
  }) async {
    var settings = await settingsProvider.loadSettings();
    if (settings == null) {
      await dialogService.showError("Error", "Settings could not be loaded.");
      return;
    }

    if (!headless) {
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
    }

    await modService.prepareGameDirectory(settings.tyDirectoryPath);
    final exeName = GameProvider.getExecutableName(selectedGame);
    final fullExePath = '${settings.tyDirectoryPath}/$exeName';
    try {
      await ensureLargeAddressAware(fullExePath);
    } catch (e) {
      log("Failed to apply LAA patch: $e");
    }

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
    final result = await Process.start(fullExePath, launchArgs, workingDirectory: settings.tyDirectoryPath);

    MemoryEditor.init(result.pid);
    await MemoryEditor.waitForProcessToStart(result.pid);
    if (injectCodes) await codeProvider.applyActiveCodes();
    result.exitCode.then((exitCode) {
      MemoryEditor.deinit();
      log('Process exited with code: $exitCode');
    });
  }
}
