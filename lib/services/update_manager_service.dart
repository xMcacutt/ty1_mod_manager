import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ty_mod_manager/main.dart';
import 'package:ty_mod_manager/providers/game_provider.dart';
import 'package:ty_mod_manager/services/version_service.dart';
import 'package:ty_mod_manager/services/settings_service.dart';

class UpdateManagerService {
  final SettingsService settingsService;
  final GameProvider gameProvider;

  UpdateManagerService(this.settingsService, this.gameProvider);

  Future<String?> checkForUpdate({bool updateFramework = true, bool showUpToDate = true}) async {
    try {
      Map<String, dynamic>? latestData;
      String? metadataSource;

      final localMetadataPath = "${Directory.current.path}${Platform.pathSeparator}latest_v2.json";
      final localMetadataFile = File(localMetadataPath);
      if (await localMetadataFile.exists()) {
        try {
          latestData = json.decode(await localMetadataFile.readAsString()) as Map<String, dynamic>;
          metadataSource = localMetadataPath;
        } catch (_) {}
      }

      if (latestData == null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final metadataUrls = [
          "https://raw.githubusercontent.com/xMcacutt/ty_mod_manager/refs/heads/master/latest_v2.json?$timestamp",
          "https://raw.githubusercontent.com/xMcacutt/ty_mod_manager/refs/heads/master/latest.json?$timestamp",
        ];

        http.Response? response;
        for (final url in metadataUrls) {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            response = res;
            metadataSource = url;
            break;
          }
        }
        if (response == null || metadataSource == null) {
          print("Could not access update metadata.");
          return null;
        }

        latestData = json.decode(response.body) as Map<String, dynamic>?;
      }
      if (latestData == null) {
        print("Update metadata is empty or invalid.");
        return null;
      }

      final latestVersion = latestData["version"];
      final downloadUrl = latestData["download_url"];
      final exeNameOverride = (latestData["exe_name"] as String?)?.trim();

      final currentVersion = getAppVersion();
      if (currentVersion == latestVersion) {
        print("Already up-to-date (v$currentVersion).");
        if (showUpToDate) await dialogService.showInfo("Already up-to-date", "Nothing new to update.");
        return null;
      }

      print("New version available: $latestVersion (metadata: ${metadataSource ?? 'unknown'}). Downloading...");
      final settings = await settingsService.loadSettings(gameProvider.selectedGame);
      if (settings == null) return null;
      if (updateFramework && await downloadAndUpdateTygerFramework(settings.tyDirectoryPath) == false) return null;
      return await downloadAndPrepareUpdate(downloadUrl, latestVersion, exeName: exeNameOverride);
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

  Future<String?> downloadAndPrepareUpdate(String url, String newVersion, {String? exeName}) async {
    final tempDir = await getTemporaryDirectory();
    final updateFolder = "${tempDir.path}\\update";
    final zipFilePath = "${tempDir.path}\\update.zip";
    final batchFilePath = "${tempDir.path}\\update.bat";
    final appDir = Directory.current.path;

    Directory(updateFolder).createSync(recursive: true);

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print("Download failed.");
      return null;
    }
    File(zipFilePath).writeAsBytesSync(response.bodyBytes);
    print("Download complete.");

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

    final targetExeName =
        (exeName != null && exeName.isNotEmpty)
            ? exeName
            : Platform.resolvedExecutable.split(Platform.pathSeparator).last;
    final currentExeName = Platform.resolvedExecutable.split(Platform.pathSeparator).last;
    final batchContent = '''
    @echo off
    set "TARGET_EXE_NAME=$targetExeName"
    set "CURRENT_EXE_NAME=$currentExeName"
    set "APP_DIR=$appDir"
    set "UPDATE_FOLDER=$updateFolder"

    echo Killing the old process...
    taskkill /IM "%CURRENT_EXE_NAME%" /F
    taskkill /IM "%TARGET_EXE_NAME%" /F
    if %ERRORLEVEL% neq 0 echo Failed to terminate process & pause

    echo Waiting for 2 seconds...
    timeout /t 2

    echo Copying files...
    xcopy /E /Y "%UPDATE_FOLDER%\\*" "%APP_DIR%\\"
    if %ERRORLEVEL% neq 0 echo Failed to copy files & pause

    if /I not "%CURRENT_EXE_NAME%"=="%TARGET_EXE_NAME%" (
      if exist "%APP_DIR%\\%CURRENT_EXE_NAME%" del /F /Q "%APP_DIR%\\%CURRENT_EXE_NAME%"
    )

    echo Starting the new application...
    start "" "%APP_DIR%\\%TARGET_EXE_NAME%"
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
