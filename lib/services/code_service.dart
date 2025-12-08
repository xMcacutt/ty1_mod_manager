import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ty_mod_manager/services/ffi_win32.dart';
import 'package:ty_mod_manager/services/utils.dart';
import 'package:win32/win32.dart';
import '../models/code.dart';

class CodeService {
  Future<List<Code>> loadCodeData(String game) async {
    late String codeJson;

    final Map<String, String> codeFiles = {'Ty 1': 'codes.json', 'Ty 2': 'codes Ty2.json', 'Ty 3': 'codes Ty3.json'};

    final fileName = codeFiles[game] ?? 'codes.json';

    final response = await http.get(
      Uri.parse(
        "https://raw.githubusercontent.com/xMcacutt/ty_mod_manager/refs/heads/master/resource/$fileName?${DateTime.now().millisecondsSinceEpoch}",
      ),
    );
    if (response.statusCode != 200) {
      codeJson = await rootBundle.loadString('resource/$fileName');
      print("Download failed.");
    } else {
      codeJson = response.body;
    }

    List<dynamic> codeData = jsonDecode(codeJson);
    final prefs = await SharedPreferences.getInstance();
    List<String> activeCodeDataString = prefs.getStringList('active_codes') ?? [];

    return codeData.map((codeJson) {
      Code code = Code.fromJson(codeJson);
      String? savedCodeData = activeCodeDataString.firstWhere(
        (data) => jsonDecode(data)['name'] == code.name,
        orElse: () => '{}',
      );

      if (savedCodeData.isNotEmpty) {
        Map<String, dynamic> savedData = jsonDecode(savedCodeData);
        code.isActive = savedData['isActive'] ?? false;
        if (code.isValue && savedData.containsKey('value')) {
          code.value = savedData['value'];
        }
      }
      return code;
    }).toList();
  }

  Future<void> saveActiveCodes(List<Code> codes) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> activeCodeData =
        codes.map((code) {
          return {'name': code.name, 'isActive': code.isActive, 'value': code.isValue ? code.value : null};
        }).toList();

    List<String> activeCodeDataString = activeCodeData.map((data) => jsonEncode(data)).toList();
    await prefs.setStringList('active_codes', activeCodeDataString);
  }

  Future<void> applyActiveCodes(List<Code> codes) async {
    final activeCodes = codes.where((code) => code.isActive).toList();
    for (var code in activeCodes) {
      print("Applying code");
      applyCode(code);
    }
  }

  void applyCode(Code code) {
    for (var codeDatum in code.codes) {
      applyCodeChange(codeDatum, code.value);
    }
  }

  void applyCodeChange(CodeData code, int? value) {
    print('Applying code at address: ${code.address} with bytes: ${code.bytes}');

    List<int> byteList;

    if (code.bytes.startsWith("X")) {
      int byteSize = int.parse(code.bytes.substring(1)); // Extract number from "X4"
      if (value == null) {
        print('Error: No value provided for value-based code.');
        return;
      }
      byteList = intToByteList(value, byteSize);
    } else {
      byteList = code.bytes.split(' ').map((e) => int.parse(e, radix: 16)).toList();
    }

    final buffer = malloc<Uint8>(byteList.length);
    for (int i = 0; i < byteList.length; i++) {
      buffer[i] = byteList[i];
    }

    var addr = MemoryEditor.moduleBase + int.parse(code.address, radix: 16);
    MemoryEditor.virtualProtect(Pointer<Uint32>.fromAddress(addr), byteList.length);

    final bytesWritten = calloc<IntPtr>();
    final writeSuccess = WriteProcessMemory(
      MemoryEditor.hProcess,
      Pointer<Uint32>.fromAddress(addr),
      buffer,
      byteList.length,
      bytesWritten,
    );

    if (writeSuccess == 0) {
      print('Failed to apply code.');
    } else {
      print('Successfully applied code!');
    }

    calloc.free(bytesWritten);
    calloc.free(buffer);
  }
}
