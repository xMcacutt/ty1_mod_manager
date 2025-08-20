import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ty1_mod_manager/providers/code_provider.dart';
import 'package:ty1_mod_manager/providers/game_provider.dart';
import 'package:ty1_mod_manager/providers/mod_directory_provider.dart';
import 'package:ty1_mod_manager/providers/mod_provider.dart';
import 'package:ty1_mod_manager/providers/settings_provider.dart';
import 'package:ty1_mod_manager/services/code_service.dart';
import 'package:ty1_mod_manager/services/launcher_service.dart';
import 'package:ty1_mod_manager/services/mod_service.dart';
import 'package:ty1_mod_manager/services/settings_service.dart';
import 'package:ty1_mod_manager/services/update_manager_service.dart';
import 'package:ty1_mod_manager/services/version_service.dart';
import 'package:ty1_mod_manager/views/about_view.dart';
import 'package:ty1_mod_manager/views/codes_view.dart';
import 'package:ty1_mod_manager/views/mod_directory_view.dart';
import 'package:ty1_mod_manager/views/main_view.dart';
import 'package:ty1_mod_manager/views/settings_view.dart';
import 'theme.dart';

void main() {
  initAppVersion();
  runApp(const ModManagerApp());
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class ModManagerApp extends StatelessWidget {
  const ModManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => SettingsService()),
        Provider(create: (_) => ModService()),
        Provider(create: (_) => CodeService()),

        ProxyProvider<SettingsService, UpdateManagerService>(
          update: (_, settingsService, __) => UpdateManagerService(settingsService),
        ),

        ChangeNotifierProxyProvider<CodeService, CodeProvider>(
          create: (_) => CodeProvider(),
          update: (_, codeService, provider) {
            provider ??= CodeProvider();
            provider.initialize(codeService);
            return provider;
          },
        ),

        ChangeNotifierProxyProvider<CodeProvider, GameProvider>(
          create: (_) => GameProvider(null),
          update: (_, codeProvider, gameProvider) {
            gameProvider ??= GameProvider(codeProvider);
            gameProvider.setCodeProvider(codeProvider);
            return gameProvider;
          },
        ),

        ChangeNotifierProxyProvider2<SettingsService, UpdateManagerService, SettingsProvider>(
          create: (_) => SettingsProvider(),
          update: (_, settingsService, updateManagerService, provider) {
            provider ??= SettingsProvider();
            provider.initialize(settingsService, updateManagerService);
            return provider;
          },
        ),

        ChangeNotifierProxyProvider3<ModService, SettingsService, GameProvider, ModProvider>(
          create: (_) => ModProvider(),
          update: (_, modService, settingsService, gameProvider, provider) {
            provider ??= ModProvider();
            provider.initialize(modService, settingsService, gameProvider);
            return provider;
          },
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
                  LauncherService(modService, codeProvider, settingsProvider),
        ),
      ],
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        title: 'Ty the Tasmanian Tiger - Mod Manager',
        theme: appTheme,
        initialRoute: '/mods',
        onGenerateRoute: (settings) {
          late final Widget page;

          switch (settings.name) {
            case '/mods':
              page = const MainView();
              break;
            case '/codes':
              page = const CodesView();
              break;
            case '/mod_directory':
              page = const ModDirectoryView();
              break;
            case '/settings':
              page = const SettingsView();
              break;
            case '/about':
              page = const AboutView();
              break;
            default:
              return null;
          }

          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: page),
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
    );
  }
}
