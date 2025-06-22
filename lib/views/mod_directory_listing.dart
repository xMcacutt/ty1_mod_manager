import 'package:flutter/material.dart';
import '../models/mod.dart';

class ModDirectoryListing extends StatelessWidget {
  final Mod mod;
  final Mod? installedMod;
  final bool isInstalling;
  final VoidCallback onDownload;

  const ModDirectoryListing({
    super.key,
    required this.mod,
    this.installedMod,
    required this.isInstalling,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    bool isUpToDate = installedMod != null && installedMod!.version == mod.version;

    return ListTile(
      leading: Image.network(
        mod.iconUrl as String,
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
              ? null
              : isInstalling
              ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(icon: Icon(Icons.download), onPressed: onDownload),
    );
  }
}
