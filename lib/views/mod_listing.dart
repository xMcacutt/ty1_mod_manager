import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../models/mod.dart';
import '../services/mod_service.dart' as modService;

class ModListing extends StatefulWidget {
  final Mod mod;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const ModListing({super.key, required this.mod, required this.isSelected, required this.onSelected});

  @override
  _ModListing createState() => _ModListing();
}

class _ModListing extends State<ModListing> {
  late Future<File?> _iconFileFuture;

  @override
  void initState() {
    super.initState();
    final modServiceInstance = modService.ModService();
    _iconFileFuture = modServiceInstance.getModIconFile(widget.mod);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: ListTile(
        leading: FutureBuilder<File?>(
          future: _iconFileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError || snapshot.data == null) {
              return Image.asset('resource/unknown.ico');
            } else {
              return Image.file(snapshot.data!);
            }
          },
        ),
        title: Text(widget.mod.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.mod.description),
            SizedBox(height: 4),
            Row(
              children: [
                Text('Version: ${widget.mod.version}', style: TextStyle(fontSize: 12)),
                SizedBox(width: 10),
                Text('Author: ${widget.mod.author}', style: TextStyle(fontSize: 12)),
                SizedBox(width: 10),
                Text('Last Update: ${widget.mod.lastUpdated}', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Switch(
          value: widget.isSelected,
          onChanged: (bool? value) {
            if (value != null) {
              widget.onSelected(value);
            }
          },
        ),
        onTap: () {
          widget.onSelected(!widget.isSelected);
        },
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(position & const Size(40, 40), Offset.zero & overlay.size),
      items: [
        PopupMenuItem(enabled: !widget.mod.website.isEmpty, child: Text("Mod Website"), value: 'website'),
        PopupMenuItem(child: Text("Uninstall"), value: 'uninstall'),
      ],
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(value);
      }
    });
  }

  void _handleMenuSelection(String value) async {
    final modServiceInstance = modService.ModService();
    switch (value) {
      case 'website':
        final Uri url = Uri.parse(widget.mod.website);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
        break;
      case 'uninstall':
        await modServiceInstance.uninstallMod(widget.mod);
        if (mounted) {
          setState(() {});
        }
        if (context.findAncestorStateOfType<State<StatefulWidget>>() != null) {
          context.findAncestorStateOfType<State<StatefulWidget>>()!.setState(() {});
        }
        break;
    }
  }
}
