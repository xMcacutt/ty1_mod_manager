import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON parsing
import '../services/mod_service.dart'; // For loading local mods
import '../models/mod.dart'; // For the Mod model

class ModDirectoryListing extends StatelessWidget {
  final Mod mod;
  final VoidCallback onDownload;

  ModDirectoryListing({required this.mod, required this.onDownload});

  @override
  Widget build(BuildContext context) {
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
      trailing: IconButton(icon: Icon(Icons.download), onPressed: onDownload),
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
  List<Mod> availableMods = []; // List of mods available to install
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadModData();
    searchController.addListener(onSearchChanged);
  }

  Future<void> loadModData() async {
    setState(() {
      isLoading = true;
    });

    // Fetch mods from GitHub
    final modDirectoryJsonUrl =
        "https://raw.githubusercontent.com/xMcacutt/ty1_mod_manager/master/mod_directory.json";
    final response = await http.get(Uri.parse(modDirectoryJsonUrl));

    if (response.statusCode == 200) {
      List<dynamic> modData = jsonDecode(response.body);

      // Convert mod data into Mod objects
      List<Mod> remoteMods =
          modData.map((modJson) => Mod.fromJson(modJson)).toList();

      // Load local mods
      List<Mod> localMods = await loadMods(); // Load mods already installed

      // Categorize mods into installed and available
      availableMods =
          remoteMods
              .where(
                (mod) =>
                    !localMods.any(
                      (installedMod) => installedMod.name == mod.name,
                    ),
              )
              .toList();

      allMods = [...installedMods, ...availableMods]; // All mods to display
      displayedMods = List.from(allMods); // Initially, show all mods
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
      appBar: AppBar(
        title: Text("Mod Directory"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ModSearchDelegate(allMods, installedMods),
              );
            },
          ),
        ],
      ),
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
                        return ModDirectoryListing(
                          mod: mod,
                          onDownload: () {
                            mod.install();
                          },
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

  ModSearchDelegate(this.mods, this.installedMods);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
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
    final filteredMods =
        mods.where((mod) {
          return mod.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

    return ListView.builder(
      itemCount: filteredMods.length,
      itemBuilder: (context, index) {
        final mod = filteredMods[index];
        return ModDirectoryListing(
          mod: mod,
          onDownload: () {
            mod.install();
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // Optional: Show suggestions based on the query
  }
}
