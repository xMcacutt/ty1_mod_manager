import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhttp/rhttp.dart';
import 'package:ty_mod_manager/providers/code_provider.dart';
import 'package:ty_mod_manager/providers/game_provider.dart';
import 'package:ty_mod_manager/providers/mod_directory_provider.dart';
import 'package:ty_mod_manager/providers/mod_provider.dart';
import 'package:ty_mod_manager/providers/settings_provider.dart';
import 'package:ty_mod_manager/services/code_service.dart';
import 'package:ty_mod_manager/services/dialog_service.dart';
import 'package:ty_mod_manager/services/direct_launcher.dart';
import 'package:ty_mod_manager/services/launcher_service.dart';
import 'package:ty_mod_manager/services/mod_service.dart';
import 'package:ty_mod_manager/services/settings_service.dart';
import 'package:ty_mod_manager/services/update_manager_service.dart';
import 'package:ty_mod_manager/services/version_service.dart';
import 'package:ty_mod_manager/views/main_view.dart';
import 'package:path/path.dart' as path;
import 'services/app_data_migration.dart';
import 'launch_args.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final dialogService = DialogService(navigatorKey);

void log(String message) {
  final file = File('${Directory.systemTemp.path}/ty_mod_manager.log');
  print(message);
  file.writeAsStringSync('[${DateTime.now().toIso8601String()}] $message\n', mode: FileMode.append);
}

Future<void> main(List<String> args) async {
  final file = File('${Directory.systemTemp.path}/ty_mod_manager.log');
  if (await file.exists()) await file.delete();
  Rhttp.init();

  late final LaunchOptions options;

  try {
    options = parseArgs(args);
  } catch (e) {
    log(e.toString());
    exit(0);
  }

  if (options.direct) {
    await runDirectLaunch(options);
    exit(0);
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log("${details.exception}\n${details.stack}");
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log("$error\n$stack");
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
  await AppDataMigration.migrate();
  await _removeLegacyExeIfPresent();

  initAppVersion();

  runApp(const ModManagerApp());
}

Future<void> runDirectLaunch(LaunchOptions options) async {
  log("Running direct launch");

  final settingsService = SettingsService();
  final modService = ModService();
  final codeService = CodeService();

  final codeProvider = CodeProvider()..initialize(codeService);
  final gameProvider = GameProvider(null);
  final settingsProvider = SettingsProvider();
  final modProvider = ModProvider();

  final updateManager = UpdateManagerService(settingsService, gameProvider);

  gameProvider.setCodeProvider(codeProvider, settingsProvider, modProvider);

  settingsProvider.initialize(settingsService, updateManager, gameProvider);

  modProvider.initialize(modService, settingsService, gameProvider);

  final gameName = switch (options.game!) {
    Game.ty1 => 'Ty 1',
    Game.ty2 => 'Ty 2',
    Game.ty3 => 'Ty 3',
  };

  final launcher = LauncherService(modService, codeProvider, settingsProvider, NullDialogService());

  log("Preparing game: $gameName");
  await prepareGame(game: gameName, codeProvider: codeProvider, modService: modService);

  log("Resolving mods...");
  final mods = await resolveMods(modService: modService, game: gameName, overrideMods: options.modsOverride);

  log("Launching...");
  await launcher.launchGame(mods, gameName, injectCodes: options.injectCodes, headless: true);
}

class ModManagerApp extends StatelessWidget {
  const ModManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => SettingsService()),
        Provider(create: (_) => ModService()),
        Provider(create: (_) => CodeService()),

        ChangeNotifierProxyProvider<CodeService, CodeProvider>(
          create: (_) => CodeProvider(),
          update: (_, codeService, provider) {
            provider ??= CodeProvider();
            provider.initialize(codeService);
            return provider;
          },
        ),

        ChangeNotifierProvider<GameProvider>(create: (_) => GameProvider(null)),

        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),

        ChangeNotifierProvider<ModProvider>(create: (_) => ModProvider()),

        ProxyProvider2<SettingsService, GameProvider, UpdateManagerService>(
          update: (_, settingsService, gameProvider, __) => UpdateManagerService(settingsService, gameProvider),
        ),

        ChangeNotifierProxyProvider2<ModService, GameProvider, ModDirectoryProvider>(
          create: (_) => ModDirectoryProvider(),
          update: (_, modService, gameProvider, provider) {
            provider ??= ModDirectoryProvider();
            provider.initialize(modService, gameProvider);
            return provider;
          },
        ),

        ProxyProvider3<ModService, CodeProvider, SettingsProvider, LauncherService>(
          update:
              (_, modService, codeProvider, settingsProvider, __) =>
                  LauncherService(modService, codeProvider, settingsProvider, dialogService),
        ),
      ],
      child: Builder(
        builder: (context) {
          final gameProvider = context.read<GameProvider>();
          final codeProvider = context.read<CodeProvider>();
          final settingsProvider = context.read<SettingsProvider>();
          final modProvider = context.read<ModProvider>();

          gameProvider.setCodeProvider(codeProvider, settingsProvider, modProvider);
          settingsProvider.initialize(
            context.read<SettingsService>(),
            context.read<UpdateManagerService>(),
            gameProvider,
          );
          modProvider.initialize(context.read<ModService>(), context.read<SettingsService>(), gameProvider);

          return MaterialApp(
            title: 'Ty the Tasmanian Tiger - Mod Manager',
            theme: appTheme,
            home: const RootView(),
            navigatorKey: navigatorKey,
          );
        },
      ),
    );
  }
}

Future<void> _removeLegacyExeIfPresent() async {
  if (!Platform.isWindows) return;

  try {
    final appDir = Directory.current.path;
    final oldExe = File(path.join(appDir, 'ty1_mod_manager.exe'));
    final newExe = File(path.join(appDir, 'ty_mod_manager.exe'));
    if (await newExe.exists() && await oldExe.exists()) {
      await oldExe.delete();
      log("Removed legacy executable ty1_mod_manager.exe");
    }
  } catch (e) {
    log("Failed to remove legacy executable: $e");
  }
}
