import 'package:flutter/material.dart';
import 'package:ty1_mod_manager/views/mod_directory_view.dart';
import 'views/main_view.dart' show MainView;
import 'theme.dart';
import 'views/settings_view.dart';

void main() {
  runApp(ModManagerApp());
}

class ModManagerApp extends StatelessWidget {
  const ModManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ty the Tasmanian Tiger - Mod Manager',
      theme: appTheme,
      initialRoute: '/mods',
      routes: {
        '/mods': (context) => MainView(),
        //'/codes': (context) => CodesView(),
        '/mod_directory': (context) => ModDirectoryView(),
        '/settings': (context) => SettingsView(),
        //'/about': (context) => AboutView(),
      },
    );
  }
}
