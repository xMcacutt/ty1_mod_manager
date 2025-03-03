import 'package:flutter/material.dart';
import 'package:ty1_mod_manager/models/mm_app_bar.dart';
import 'package:ty1_mod_manager/services/version_service.dart';
import 'package:ty1_mod_manager/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  void _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MMAppBar(title: 'About'),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version ${getAppVersion()}',
                  style: TextStyle(
                    fontSize: 28,
                    color: AppColors.altText,
                    fontFamily: 'SF Slapstick Comic',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Slapstick Comic',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This application is designed to make installing, using, and managing mods for Ty the Tasmanian Tiger. Mods come in two forms, RKV patches and dll plugins. RKV patches are used to swap out or add extra game files to the game and dll plugins exist to modify the behaviour of the game. A mod for Ty is defined as a combination of the two with each being optional.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    final url = Uri.parse(
                      'https://github.com/xMcacutt/ty1_mod_manager/blob/master/README.md#Adding-Mods',
                    );
                    _launchURL(url);
                  },
                  child: const Text(
                    'For more information on the capabilities of this application, view the readme.',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Support',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Slapstick Comic',
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    final url = Uri.parse('https://discord.gg/2jRZZcknkM');
                    _launchURL(url);
                  },
                  child: const Text(
                    'For support on creating mods or help setting up and using mods, visit the discord.',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Adding Mods',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Slapstick Comic',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mods can be added to the mod directory by creating a pull request and modifying the mod_directory.json file. You\'ll also need to create a public repo for the mod and upload the release as a zip with a mod_info.json file, icon, and dll mod and/or rkv patch. For more information on adding a mod, see the guide.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    final url = Uri.parse(
                      'https://github.com/xMcacutt/ty1_mod_manager/blob/master/README.md#Adding-Mods',
                    );
                    _launchURL(url);
                  },
                  child: const Text(
                    'For more information on adding a mod, see adding a mod.',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bugs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Slapstick Comic',
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    final url = Uri.parse(
                      'https://github.com/xMcacutt/ty1_mod_manager/issues',
                    );
                    _launchURL(url);
                  },
                  child: const Text(
                    'Please report any bugs on the github as issues.',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Author',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Slapstick Comic',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mod manager created by xMcacutt. Special thanks to Kana (Elusive Fluffy) for the underlying framework, and Dashieswag92 for development support.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
