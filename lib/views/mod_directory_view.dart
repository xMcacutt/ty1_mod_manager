import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ty1_mod_manager/views/mod_directory_listing.dart';
import '../models/mod.dart';
import '../providers/mod_directory_provider.dart';
import '../views/mm_app_bar.dart';

class ModDirectoryView extends StatelessWidget {
  const ModDirectoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final modDirectoryProvider = Provider.of<ModDirectoryProvider>(context);

    return Scaffold(
      appBar: MMAppBar(
        title: "Mod Directory",
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ModSearchDelegate(
                  modDirectoryProvider.allMods,
                  modDirectoryProvider.installedMods,
                  modDirectoryProvider.modsInstalling,
                  modDirectoryProvider.installMod,
                ),
              );
            },
          ),
        ],
      ),
      body:
          modDirectoryProvider.isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: modDirectoryProvider.displayedMods.length,
                      itemBuilder: (context, index) {
                        final mod = modDirectoryProvider.displayedMods[index];
                        final installedMod = modDirectoryProvider.installedMods.firstWhere(
                          (x) => x.name == mod.name,
                          orElse:
                              () => Mod(
                                name: '',
                                version: '',
                                description: '',
                                author: '',
                                lastUpdated: '',
                                dllName: '',
                                dependencies: [],
                                conflicts: [],
                                downloadUrl: '',
                                website: '',
                                games: [],
                              ),
                        );
                        return ModDirectoryListing(
                          mod: mod,
                          installedMod: installedMod.name.isNotEmpty ? installedMod : null,
                          isInstalling: modDirectoryProvider.modsInstalling.contains(mod.name),
                          onDownload: () => modDirectoryProvider.installMod(mod),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class ModSearchDelegate extends SearchDelegate {
  final List<Mod> mods;
  final List<Mod> installedMods;
  final Set<String> installingMods;
  final Future<void> Function(Mod mod) installMod;

  ModSearchDelegate(this.mods, this.installedMods, this.installingMods, this.installMod);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => _buildModList(context, query);

  @override
  Widget buildSuggestions(BuildContext context) => _buildModList(context, query);

  Widget _buildModList(BuildContext context, String query) {
    final filteredMods = mods.where((mod) => mod.name.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: filteredMods.length,
      itemBuilder: (context, index) {
        final mod = filteredMods[index];
        final installedMod = installedMods.firstWhere(
          (x) => x.name == mod.name,
          orElse:
              () => Mod(
                name: '',
                version: '',
                description: '',
                author: '',
                lastUpdated: '',
                dllName: '',
                dependencies: [],
                conflicts: [],
                downloadUrl: '',
                website: '',
                games: [],
              ),
        );
        return ModDirectoryListing(
          mod: mod,
          installedMod: installedMod.name.isNotEmpty ? installedMod : null,
          isInstalling: installingMods.contains(mod.name),
          onDownload: () => installMod(mod),
        );
      },
    );
  }
}
