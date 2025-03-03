import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ty1_mod_manager/models/code.dart';
import 'dart:convert';

import 'package:ty1_mod_manager/models/mm_app_bar.dart'; // For JSON parsing

class CodeListing extends StatefulWidget {
  final Code code;
  final ValueChanged<bool> onChanged; // Callback for the switch change
  final ValueChanged<double>? onValueChanged;

  CodeListing({
    required this.code,
    required this.onChanged,
    this.onValueChanged,
  });

  @override
  _CodeListingState createState() => _CodeListingState();
}

class _CodeListingState extends State<CodeListing> {
  TextEditingController valueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(widget.code.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(widget.code.description)],
          ),
          value: widget.code.isActive,
          onChanged: widget.onChanged,
        ),
        if (widget.code.isValue && widget.code.isActive)
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 100.0, bottom: 15),
            child: Slider(
              value: widget.code.value.toDouble(),
              onChanged: widget.onValueChanged!,
              max: widget.code.valueMax!.toDouble(),
              divisions: widget.code.valueDiv,
              min: widget.code.valueMin!.toDouble(),
              label: widget.code.value.toString(),
            ),
          ),
      ],
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
    setCodes();
  }

  Future<void> setCodes() async {
    final loadedCodes = await loadCodeData();
    setState(() {
      codes = loadedCodes;
    });
  }

  static Future<List<Code>> loadCodeData() async {
    final codeJson = await rootBundle.loadString('resource/codes.json');
    List<dynamic> codeData = jsonDecode(codeJson);

    final prefs = await SharedPreferences.getInstance();
    List<String> activeCodeDataString =
        prefs.getStringList('active_codes') ?? [];

    return codeData.map((codeJson) {
      Code code = Code.fromJson(codeJson);

      // Find corresponding saved data for this code
      String? savedCodeData = activeCodeDataString.firstWhere(
        (data) => jsonDecode(data)['name'] == code.name,
        orElse: () => '{}',
      );

      if (savedCodeData.isNotEmpty) {
        Map<String, dynamic> savedData = jsonDecode(savedCodeData);
        code.isActive = savedData['isActive'] ?? false;
        if (code.isValue && savedData.containsKey('value')) {
          code.value = savedData['value']; // Restore the saved value
        }
      }

      return code;
    }).toList();
  }

  void onSwitchChanged(bool value, int index) async {
    setState(() {
      codes[index].isActive = value;
    });
    await saveActiveCodes();
  }

  void onValueChanged(double value, int index) async {
    setState(() {
      codes[index].value = value.round();
    });
    await saveActiveCodes();
  }

  static void applyActiveCodes() async {
    var loadedCodes = await loadCodeData();
    List<Code> activeCodes =
        loadedCodes.where((code) => code.isActive).toList();
    for (var code in activeCodes) {
      print("Applying code");
      code.applyCode(); // Apply the code if it's active
    }
  }

  Future<void> saveActiveCodes() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> activeCodeData =
        codes.map((code) {
          return {
            'name': code.name,
            'isActive': code.isActive,
            'value':
                code.isValue
                    ? code.value
                    : null, // Save value if it's a value-based code
          };
        }).toList();

    List<String> activeCodeDataString =
        activeCodeData.map((data) => jsonEncode(data)).toList();
    await prefs.setStringList('active_codes', activeCodeDataString);
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
            onValueChanged: (value) => onValueChanged(value, index),
          );
        },
      ),
    );
  }
}
