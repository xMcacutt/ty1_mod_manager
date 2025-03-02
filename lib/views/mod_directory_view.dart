import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ty1_mod_manager/models/mm_app_bar.dart';
import 'dart:convert'; // For JSON parsing
import '../services/mod_service.dart'; // For loading local mods
import '../models/mod.dart'; // For the Mod model

class ModDirectoryListing extends StatelessWidget {
  final Mod mod;
  final Mod? installedMod;
  final bool isInstalling;
  final VoidCallback onDownload;

  ModDirectoryListing({
    required this.mod,
    this.installedMod,
    required this.isInstalling,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    bool isUpToDate =
        installedMod != null && installedMod!.version == mod.version;

    return ListTile(
      leading: Image.network(
        mod.directoryIconPath as String,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('resource/unknown.ico');
        },
      ),
      title: Text(mod.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mod.description),
          Row(
            children: [
              Text('Author: ${mod.author}'),
              SizedBox(width: 10),
              Text('Version: ${mod.version}'),
              SizedBox(width: 10),
              Text('Date: ${mod.lastUpdated}'),
            ],
          ),
        ],
      ),
      trailing:
          isUpToDate
              ? null // Hide button if mod is up to date
              : isInstalling
              ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ) // Show loading wheel if installing
              : IconButton(icon: Icon(Icons.download), onPressed: onDownload),
    );
  }
}

class ModDirectoryView extends StatefulWidget {
  @override
  _ModDirectoryViewState createState() => _ModDirectoryViewState();
}

class _ModDirectoryViewState extends State<ModDirectoryView> {
  List<Mod> allMods = []; // List of all mods (from GitHub and local)
  List<Mod> displayedMods = []; // List of mods to display
  List<Mod> installedMods = []; // List of mods already installed
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  Set<String> modsInstalling = {};

  @override
  void initState() {
    super.initState();
    loadModData();
    searchController.addListener(onSearchChanged);
  }

  Future<void> installMod(Mod mod) async {
    setState(() {
      modsInstalling.add(mod.name); // Show loading indicator
    });
    await mod.install(); // Perform async installation

    setState(() {
      modsInstalling.remove(mod.name); // Remove loading indicator
      installedMods.add(mod); // Add mod to installed list
    });
  }

  Future<void> loadModData() async {
    setState(() {
      isLoading = true;
    });

    // Fetch mods from GitHub
    final modDirectoryJsonUrl =
        "https://raw.githubusercontent.com/xMcacutt/ty1_mod_manager/refs/heads/master/mod_directory.json";
    final response = await http.get(Uri.parse(modDirectoryJsonUrl));

    if (response.statusCode == 200) {
      List<dynamic> modData = jsonDecode(response.body);
      List<Mod> remoteMods = [];
      // Convert mod data into Mod objects
      for (var modListing in modData) {
        String modInfoUrl =
            modListing['mod_info_url'] +
            '?${DateTime.now().millisecondsSinceEpoch}';
        print(modInfoUrl);
        final response = await http.get(Uri.parse(modInfoUrl));
        if (response.statusCode == 200) {
          remoteMods.add(Mod.fromJson(await jsonDecode(response.body)));
        }
      }

      // Load local mods
      List<Mod> localMods = await loadMods(); // Load mods already installed
      var updatableMods =
          remoteMods.where((remoteMod) {
            var localMod =
                localMods
                    .where((localMod) => localMod.name == remoteMod.name)
                    .firstOrNull;
            return localMod == null ||
                compareVersions(localMod.version, remoteMod.version) != 1;
          }).toList();

      installedMods =
          remoteMods.where((remoteMod) {
            // Find the corresponding local mod by name
            var localMod =
                localMods
                    .where((localMod) => localMod.name == remoteMod.name)
                    .firstOrNull;

            return localMod != null &&
                compareVersions(localMod.version, remoteMod.version) != -1;
          }).toList();

      allMods = [...installedMods, ...updatableMods]; // All mods to display
      displayedMods = updatableMods; // Initially, show all mods
    }

    setState(() {
      isLoading = false;
    });
  }

  // Filter mods by search input
  void onSearchChanged() {
    String query = searchController.text.toLowerCase();
    setState(() {
      displayedMods =
          allMods.where((mod) {
            return mod.name.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MMAppBar(title: "Mod Directory"),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search mods...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: displayedMods.length,
                      itemBuilder: (context, index) {
                        final mod = displayedMods[index];
                        bool modInstalled = installedMods.any(
                          (x) => x.name == mod.name,
                        );
                        return ModDirectoryListing(
                          mod: mod,
                          installedMod:
                              modInstalled
                                  ? installedMods.firstWhere(
                                    (x) => x.name == mod.name,
                                  )
                                  : null,
                          isInstalling: modsInstalling.contains(mod.name),
                          onDownload: () => installMod(mod),
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
  final Set<String> installingMods; // Track installing mods
  final Future<void> Function(Mod mod) installMod; // Async install function

  ModSearchDelegate(
    this.mods,
    this.installedMods,
    this.installingMods,
    this.installMod,
  );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context); // Refresh suggestions
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildModList(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildModList(context, query);
  }

  /// **Helper method to filter and display mods**
  Widget _buildModList(BuildContext context, String query) {
    final filteredMods =
        mods
            .where(
              (mod) => mod.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return ListView.builder(
      itemCount: filteredMods.length,
      itemBuilder: (context, index) {
        final mod = filteredMods[index];
        bool modInstalled = installedMods.any((x) => x.name == mod.name);
        final installedMod =
            modInstalled
                ? installedMods.firstWhere((x) => x.name == mod.name)
                : null;

        return ModDirectoryListing(
          mod: mod,
          installedMod: installedMod,
          isInstalling: installingMods.contains(
            mod.name,
          ), // Track install state
          onDownload: () => installMod(mod),
        );
      },
    );
  }
}
