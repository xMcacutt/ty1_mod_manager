import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ty1_mod_manager/providers/code_provider.dart';
import 'package:ty1_mod_manager/views/code_listing.dart';
import '../views/mm_app_bar.dart';

class CodesView extends StatelessWidget {
  const CodesView({super.key});

  @override
  Widget build(BuildContext context) {
    final codeProvider = Provider.of<CodeProvider>(context);

    return Scaffold(
      appBar: MMAppBar(title: "Codes"),
      body:
          codeProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: codeProvider.codes.length,
                itemBuilder: (context, index) {
                  final code = codeProvider.codes[index];
                  return CodeListing(
                    code: code,
                    onChanged: (value) => codeProvider.toggleCodeActive(index, value),
                    onValueChanged: code.isValue ? (value) => codeProvider.updateCodeValue(index, value) : null,
                  );
                },
              ),
    );
  }
}
