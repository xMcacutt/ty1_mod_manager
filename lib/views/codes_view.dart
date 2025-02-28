import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ty1_mod_manager/models/code.dart';
import 'dart:convert';

import 'package:ty1_mod_manager/models/mm_app_bar.dart'; // For JSON parsing

class CodeListing extends StatelessWidget {
  final Code code;
  final ValueChanged<bool> onChanged; // Callback for the switch change

  CodeListing({required this.code, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(code.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(code.description)],
      ),
      value: code.isActive,
      onChanged: onChanged,
    );
  }
}

class CodesView extends StatefulWidget {
  @override
  _CodesViewState createState() => _CodesViewState();

  static void applyActiveCodes() => _CodesViewState.applyActiveCodes();
}

class _CodesViewState extends State<CodesView> {
  static List<Code> codes = [];

  @override
  void initState() {
    super.initState();
    loadCodeData();
  }

  Future<void> loadCodeData() async {
    // Fetch mods from GitHub
    final codeJson = File("resource/codes.json");
    List<dynamic> codeData = jsonDecode(await codeJson.readAsString());

    // Convert mod data into Mod objects
    setState(() {
      codes = codeData.map((codeJson) => Code.fromJson(codeJson)).toList();
    });
  }

  void onSwitchChanged(bool value, int index) {
    setState(() {
      codes[index].isActive = value;
    });
  }

  static void applyActiveCodes() {
    List<Code> activeCodes = getActiveCodes();
    for (var code in activeCodes) {
      print("Applying code");
      code.applyCode(); // Apply the code if it's active
    }
  }

  // Collect active codes
  static List<Code> getActiveCodes() {
    return codes.where((code) => code.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MMAppBar(title: "Codes"),
      body: ListView.builder(
        itemCount: codes.length,
        itemBuilder: (context, index) {
          return CodeListing(
            code: codes[index],
            onChanged: (value) => onSwitchChanged(value, index),
          );
        },
      ),
    );
  }
}
