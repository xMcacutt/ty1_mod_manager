import 'package:flutter/material.dart';
import 'package:ty1_mod_manager/services/version_service.dart';
import 'package:ty1_mod_manager/views/about_view.dart';
import 'package:ty1_mod_manager/views/codes_view.dart';
import 'package:ty1_mod_manager/views/mod_directory_view.dart';
import 'views/main_view.dart' show MainView;
import 'theme.dart';
import 'views/settings_view.dart';

void main() {
  initAppVersion();
  runApp(ModManagerApp());
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class ModManagerApp extends StatelessWidget {
  const ModManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      title: 'Ty the Tasmanian Tiger - Mod Manager',
      theme: appTheme,
      initialRoute: '/mods',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/mods':
            page = MainView();
            break;
          case '/codes':
            page = CodesView();
            break;
          case '/mod_directory':
            page = ModDirectoryView();
            break;
          case '/settings':
            page = SettingsView();
            break;
          case '/about':
            page = AboutView();
          default:
            return null; // Prevents errors for undefined routes
        }

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 300), // Adjust speed
        );
      },
    );
  }
}
