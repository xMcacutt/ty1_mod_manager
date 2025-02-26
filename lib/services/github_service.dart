import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';

Future<bool> download(
  BuildContext context,
  String fileUrl,
  String savePath,
) async {
  try {
    // Send a GET request to fetch the file
    final response = await http.get(Uri.parse(fileUrl));

    if (response.statusCode == 200) {
      // If the request is successful, write the file to disk
      File file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return true;
    } else {
      _showErrorDialog(
        context,
        'Failed to download file. Status code: ${response.statusCode}',
      );
      return false;
    }
  } catch (e) {
    _showErrorDialog(context, 'Error occurred while downloading the file: $e');
    return false;
  }
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
