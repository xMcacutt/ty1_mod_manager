import 'package:flutter/material.dart';
import '../models/code.dart';

class CodeListing extends StatelessWidget {
  final Code code;
  final ValueChanged<bool> onChanged;
  final ValueChanged<double>? onValueChanged;

  const CodeListing({super.key, required this.code, required this.onChanged, this.onValueChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(code.name),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(code.description)]),
          value: code.isActive,
          onChanged: onChanged,
        ),
        if (code.isValue && code.isActive)
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 100.0, bottom: 15),
            child: Slider(
              value: code.value.toDouble(),
              onChanged: onValueChanged!,
              max: code.valueMax!.toDouble(),
              divisions: code.valueDiv,
              min: code.valueMin!.toDouble(),
              label: code.value.toString(),
            ),
          ),
      ],
    );
  }
}
