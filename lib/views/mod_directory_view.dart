import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ty1_mod_manager/views/mod_directory_listing.dart';
import '../models/mod.dart';
import '../providers/mod_directory_provider.dart';

class ModDirectoryView extends StatefulWidget {
  const ModDirectoryView({super.key});

  @override
  State<ModDirectoryView> createState() => _ModDirectoryViewState();
}

class _ModDirectoryViewState extends State<ModDirectoryView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final modDirectoryProvider = Provider.of<ModDirectoryProvider>(context);

    final mods =
        modDirectoryProvider.displayedMods
            .where((mod) => mod.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toSet()
            .toList();

    return modDirectoryProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search mods...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child:
                  mods.isEmpty
                      ? const Center(child: Text('No mods found'))
                      : ListView.builder(
                        itemCount: mods.length,
                        itemBuilder: (context, index) {
                          final mod = mods[index];
                          final installedMod = modDirectoryProvider.installedMods.firstWhere(
                            (x) => x.name == mod.name,
                            orElse: () => Mod.none,
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
        );
  }
}
