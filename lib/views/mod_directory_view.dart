import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ty1_mod_manager/models/directory_mod.dart';
import 'dart:convert'; // For JSON parsing
import '../services/mod_service.dart'; // For loading local mods
import '../models/mod.dart'; // For the Mod model

class ModDirectoryView extends StatefulWidget {
  @override
  _ModDirectoryViewState createState() => _ModDirectoryViewState();
}

class _ModDirectoryViewState extends State<ModDirectoryView> {
  List<DirectoryMod> allMods = []; // List of all mods (from GitHub and local)
  List<DirectoryMod> displayedMods =
      []; // List of mods to display (filtered with search)
  List<DirectoryMod> installedMods = []; // List of mods already installed
  List<DirectoryMod> availableMods = []; // List of mods available to install
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
      List<DirectoryMod> remoteMods =
          modData.map((modJson) => DirectoryMod.fromJson(modJson)).toList();

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

  // Action to install or update a mod
  void installOrUpdateMod(DirectoryMod mod) {
    // Call the appropriate function to install or update mod
    if (installedMods.contains(mod)) {
      // Update mod if already installed
      // Logic for updating mod goes here
    } else {
      // Install mod if not already installed
      // Logic for installing mod goes here
    }
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
                delegate: ModSearchDelegate(allMods),
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
                        return ListTile(
                          leading: Image.file(mod.icon), // Display mod icon
                          title: Text(mod.name),
                          subtitle: Text(mod.version),
                          trailing: IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () => installOrUpdateMod(mod),
                          ),
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
  final List<DirectoryMod> mods;

  ModSearchDelegate(this.mods);

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
        return ListTile(
          leading: Image.file(mod.icon), // Display mod icon
          title: Text(mod.name),
          subtitle: Text(mod.version),
          trailing: IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              // Logic to install or update mod goes here
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // Optional: Show suggestions based on the query
  }
}
