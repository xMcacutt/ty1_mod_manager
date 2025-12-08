import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ty_mod_manager/main.dart';

Future<bool> download(BuildContext context, String fileUrl, String savePath) async {
  try {
    // Send a GET request to fetch the file
    final response = await http.get(Uri.parse(fileUrl));

    if (response.statusCode == 200) {
      // If the request is successful, write the file to disk
      File file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return true;
    } else {
      dialogService.showError('Error', 'Failed to download file. Status code: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    dialogService.showError('Error', 'Error occurred while downloading the file: $e');
    return false;
  }
}
