import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ty1_mod_manager/main.dart';
import 'package:ty1_mod_manager/providers/game_provider.dart';
import 'package:ty1_mod_manager/services/dialog_service.dart';
import 'package:ty1_mod_manager/services/version_service.dart';
import 'package:ty1_mod_manager/services/settings_service.dart';

class UpdateManagerService {
  final SettingsService settingsService;
  final GameProvider gameProvider;

  UpdateManagerService(this.settingsService, this.gameProvider);

  Future<String?> checkForUpdate({bool updateFramework = true, bool showUpToDate = true}) async {
    try {
      String latestVersionUrl =
          "https://raw.githubusercontent.com/xMcacutt/ty1_mod_manager/refs/heads/master/latest.json?${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.get(Uri.parse(latestVersionUrl));
      if (response.statusCode != 200) {
        print("Could not access file at url");
        return null;
      }

      final latestData = json.decode(response.body);
      final latestVersion = latestData["version"];
      final downloadUrl = latestData["download_url"];

      final currentVersion = getAppVersion();
      if (currentVersion == latestVersion) {
        print("Already up-to-date (v$currentVersion).");
        if (showUpToDate) await dialogService.showInfo("Already up-to-date", "Nothing new to update.");
        return null;
      }

      print("New version available: $latestVersion. Downloading...");
      final settings = await settingsService.loadSettings(gameProvider.selectedGame);
      if (settings == null) return null;
      if (updateFramework && await downloadAndUpdateTygerFramework(settings.tyDirectoryPath) == false) return null;
      return await downloadAndPrepareUpdate(downloadUrl, latestVersion);
    } catch (e) {
      print("Update check failed: $e");
      return null;
    }
  }

  Future<bool> downloadAndUpdateTygerFramework(String tyDirectoryPath) async {
    try {
      final dll = File('$tyDirectoryPath/XInput9_1_0.dll');
      if (await dll.exists()) await dll.delete();
      final response = await http.get(
        Uri.parse("https://github.com/ElusiveFluffy/TygerFramework/releases/latest/download/XInput9_1_0.dll"),
      );
      if (response.statusCode != 200) {
        print("Download failed.");
        return false;
      }
      await File(dll.path).writeAsBytes(response.bodyBytes);
      return true;
    } catch (e) {
      print("Download failed: $e");
      return false;
    }
  }

  Future<String?> downloadAndPrepareUpdate(String url, String newVersion) async {
    final tempDir = await getTemporaryDirectory();
    final updateFolder = "${tempDir.path}\\update";
    final zipFilePath = "${tempDir.path}\\update.zip";
    final batchFilePath = "${tempDir.path}\\update.bat";
    final appDir = Directory.current.path;

    // Ensure update directory is clean
    Directory(updateFolder).createSync(recursive: true);

    // Download the ZIP file
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print("Download failed.");
      return null;
    }
    File(zipFilePath).writeAsBytesSync(response.bodyBytes);
    print("Download complete.");

    // Extract ZIP to temp folder
    final bytes = File(zipFilePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filePath = "$updateFolder/${file.name}";
      if (file.isFile) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(filePath).createSync(recursive: true);
      }
    }
    print("Update extracted.");

    // Create a batch file to replace files and restart app
    final exeName = Platform.resolvedExecutable.split(Platform.pathSeparator).last;
    final batchContent = '''
    @echo off
    set "EXE_NAME=$exeName"
    set "APP_DIR=$appDir"
    set "UPDATE_FOLDER=$updateFolder"

    echo Killing the old process...
    taskkill /IM "%EXE_NAME%" /F
    if %ERRORLEVEL% neq 0 echo Failed to terminate process & pause

    echo Waiting for 2 seconds...
    timeout /t 2

    echo Copying files...
    xcopy /E /Y "%UPDATE_FOLDER%\\*" "%APP_DIR%\\"
    if %ERRORLEVEL% neq 0 echo Failed to copy files & pause

    echo Starting the new application...
    start "" "%APP_DIR%\\%EXE_NAME%"
    pause
    exit
    ''';

    File(batchFilePath).writeAsStringSync(batchContent);
    print("Update script created.");
    print(batchFilePath);
    return batchFilePath;
  }

  void updateApp(String batchFilePath) {
    Process.start("cmd.exe", ["/c", batchFilePath], mode: ProcessStartMode.detached);
  }
}
