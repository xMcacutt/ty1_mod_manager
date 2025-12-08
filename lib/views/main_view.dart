import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ty_mod_manager/providers/code_provider.dart';
import 'package:ty_mod_manager/providers/game_provider.dart';
import 'package:ty_mod_manager/providers/settings_provider.dart';
import 'package:ty_mod_manager/services/update_manager_service.dart';
import 'package:ty_mod_manager/views/about_view.dart';
import 'package:ty_mod_manager/views/codes_view.dart';
import 'package:ty_mod_manager/views/mod_directory_view.dart';
import 'package:ty_mod_manager/views/mv_bottom_app_bar.dart';
import 'package:ty_mod_manager/views/my_mods_view.dart';
import 'package:ty_mod_manager/views/settings_view.dart';
import '../views/mm_app_bar.dart';
import '../views/app_drawer.dart';
import '../providers/mod_provider.dart';
import '../services/launcher_service.dart';
import '../services/settings_service.dart';

class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  _RootViewState createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [MyModsView(), CodesView(), ModDirectoryView(), SettingsView(), AboutView()];

  final List<String> _titles = ["My Mods", "Codes", "Mod Directory", "Settings", "About"];

  @override
  void initState() {
    super.initState();
    final updateManager = Provider.of<UpdateManagerService>(context, listen: false);
    updateManager.checkForUpdate(showUpToDate: false);
  }

  void _setPage(int index) {
    setState(() {
      _currentIndex = index;
      var gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (index == 0) {
        var modProvider = Provider.of<ModProvider>(context, listen: false);
        modProvider.loadMods();
      }
      if (index == 1) {
        var codeProvider = Provider.of<CodeProvider>(context, listen: false);
        codeProvider.loadCodes(gameProvider.selectedGame);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modProvider = Provider.of<ModProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final launcherService = Provider.of<LauncherService>(context, listen: false);
    final settingsService = Provider.of<SettingsService>(context, listen: false);

    return Scaffold(
      appBar: MMAppBar(title: _titles[_currentIndex]),
      drawer: AppDrawer(onSelectPage: _setPage),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _pages[_currentIndex],
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      bottomNavigationBar: BottomNavBar(
        modProvider: modProvider,
        settingsProvider: settingsProvider,
        launcherService: launcherService,
        settingsService: settingsService,
      ),
    );
  }
}
