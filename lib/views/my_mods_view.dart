import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ty1_mod_manager/providers/game_provider.dart';
import 'package:ty1_mod_manager/providers/mod_provider.dart';
import 'package:ty1_mod_manager/providers/settings_provider.dart';
import 'package:ty1_mod_manager/services/settings_service.dart';
import 'package:ty1_mod_manager/services/update_manager_service.dart';
import 'package:ty1_mod_manager/views/mod_listing.dart';
import 'package:ty1_mod_manager/services/launcher_service.dart';

import '../main.dart';

class MyModsView extends StatefulWidget {
  const MyModsView({super.key});

  @override
  _MyModsViewState createState() => _MyModsViewState();
}

class _MyModsViewState extends State<MyModsView> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final modProvider = Provider.of<ModProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

      settingsProvider.loadSettings();
      settingsProvider.checkFirstRun();
      modProvider.loadMods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modProvider = Provider.of<ModProvider>(context);
    final settingsService = Provider.of<SettingsService>(context);
    final gameProvider = Provider.of<GameProvider>(context);

    return Stack(
      children: [
        modProvider.isLoading
            ? Center(child: CircularProgressIndicator())
            : modProvider.mods.isEmpty
            ? Center(child: Text('No mods found'))
            : ListView.builder(
              itemCount: modProvider.mods.length,
              itemBuilder: (context, index) {
                final mod = modProvider.mods[index];
                final isSelected = modProvider.selectedMods.contains(mod);
                return ModListing(
                  key: UniqueKey(),
                  mod: mod,
                  isSelected: isSelected,
                  onSelected: (_) => modProvider.toggleModSelection(mod),
                );
              },
            ),
      ],
    );
  }
}
