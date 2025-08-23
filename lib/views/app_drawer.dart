import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ty1_mod_manager/services/version_service.dart';

class AppDrawer extends StatelessWidget {
  final void Function(int index) onSelectPage;

  const AppDrawer({super.key, required this.onSelectPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('resource/fe_041.png'), fit: BoxFit.cover),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Mod Manager',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text('Version ${getAppVersion()}', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.boxArchive),
            title: const Text("My Mods"),
            subtitle: const Text("View and manage your mods."),
            onTap: () {
              Navigator.pop(context);
              onSelectPage(0);
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.code),
            title: const Text("Codes"),
            subtitle: const Text("View and manage codes."),
            onTap: () {
              Navigator.pop(context);
              onSelectPage(1);
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.book),
            title: const Text("Mod Directory"),
            subtitle: const Text("Browse officially supported mods."),
            onTap: () {
              Navigator.pop(context);
              onSelectPage(2);
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.gear),
            title: const Text("Settings"),
            subtitle: const Text("Edit the mod manager settings."),
            onTap: () {
              Navigator.pop(context);
              onSelectPage(3);
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.circleInfo),
            title: const Text("About"),
            subtitle: const Text("About the mod manager."),
            onTap: () {
              Navigator.pop(context);
              onSelectPage(4);
            },
          ),
        ],
      ),
    );
  }
}
