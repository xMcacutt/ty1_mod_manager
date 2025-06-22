import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ty1_mod_manager/providers/mod_provider.dart';
import 'package:ty1_mod_manager/providers/settings_provider.dart';
import 'package:ty1_mod_manager/services/settings_service.dart';
import 'package:ty1_mod_manager/services/update_manager_service.dart';
import 'package:ty1_mod_manager/services/version_service.dart';
import 'package:ty1_mod_manager/views/mm_app_bar.dart';
import 'package:ty1_mod_manager/views/mod_listing.dart';
import 'package:ty1_mod_manager/services/launcher_service.dart';

import '../main.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final modProvider = Provider.of<ModProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final updateManager = Provider.of<UpdateManagerService>(context, listen: false);

      modProvider.checkFirstRun();
      modProvider.loadMods();
      settingsProvider.loadSettings();
      updateManager.checkForUpdate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    Provider.of<ModProvider>(context, listen: false).loadMods();
  }

  @override
  Widget build(BuildContext context) {
    final modProvider = Provider.of<ModProvider>(context);
    final settingsService = Provider.of<SettingsService>(context);
    final launcherService = Provider.of<LauncherService>(context);

    return Scaffold(
      appBar: MMAppBar(title: "My Mods"),
      body: Stack(
        children: [
          modProvider.isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: modProvider.mods.length,
                itemBuilder: (context, index) {
                  final mod = modProvider.mods[index];
                  final isSelected = modProvider.selectedMods.contains(mod);
                  return ModListing(
                    mod: mod,
                    isSelected: isSelected,
                    onSelected: (_) => modProvider.toggleModSelection(mod),
                  );
                },
              ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () => launcherService.launchGame(context, modProvider.selectedMods),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Text("Launch Game", style: TextStyle(fontFamily: 'SF Slapstick Comic', fontSize: 24)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await settingsService.pickDirectory(context);
                  if (result != null) {
                    await modProvider.completeSetup(autoComplete: true, tyDirectoryPath: result);
                    await modProvider.loadMods();
                  } else {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("No Directory Selected"),
                          content: Text("Please select a valid directory."),
                          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Ok"))],
                        );
                      },
                    );
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Text("Add Custom", style: TextStyle(fontFamily: 'SF Slapstick Comic', fontSize: 24)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (modProvider.isFirstRun)
            AlertDialog(
              title: Text('Welcome!'),
              content: Text('Do you want me to automatically set up your modded Ty directory?'),
              actions: [
                TextButton(
                  onPressed: () => modProvider.completeSetup(autoComplete: false, tyDirectoryPath: null),
                  child: Text('No'),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await settingsService.pickDirectory(context);
                    if (result != null) {
                      await modProvider.completeSetup(autoComplete: true, tyDirectoryPath: result);
                    }
                  },
                  child: Text('Yes'),
                ),
              ],
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage('resource/fe_041.png'), fit: BoxFit.cover),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text('Mod Manager', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Version ${getAppVersion()}', style: TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.boxArchive),
              title: Text("My Mods"),
              subtitle: Text("View and manage your mods."),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.code),
              title: Text("Codes"),
              subtitle: Text("View and manage codes."),
              onTap: () => Navigator.pushNamed(context, '/codes'),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.book),
              title: Text("Mod Directory"),
              subtitle: Text("Browse officially supported mods."),
              onTap: () => Navigator.pushNamed(context, '/mod_directory'),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.gear),
              title: Text("Settings"),
              subtitle: Text("Edit the mod manager settings."),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.circleInfo),
              title: Text("About"),
              subtitle: Text("About the mod manager."),
              onTap: () => Navigator.pushNamed(context, '/about'),
            ),
          ],
        ),
      ),
    );
  }
}
