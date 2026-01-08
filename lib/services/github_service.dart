import 'dart:io';
import 'package:ty_mod_manager/main.dart';
import 'package:rhttp/rhttp.dart';

Future<bool> download(String fileUrl, String savePath) async {
  try {
    final response = await Rhttp.getBytes(fileUrl);

    if (response.statusCode == 200) {
      File file = File(savePath);
      await file.writeAsBytes(response.body);
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
