import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:ty1_mod_manager/services/ffi_win32.dart';
import 'package:win32/win32.dart';

class Code {
  final String name;
  final String description;
  final bool isValue;
  final int? valueMax;
  final int? valueMin;
  final int? valueDiv;
  final List<CodeData> codes;
  int value;
  bool isActive;

  Code({
    required this.name,
    required this.description,
    required this.codes,
    this.isValue = false,
    this.isActive = false,
    this.value = 0,
    this.valueMax,
    this.valueMin,
    this.valueDiv,
  });

  static Code fromJson(dynamic codeInfo) {
    final name = codeInfo['name'] ?? '';
    final isValue = codeInfo['is_value'] ?? false;
    final valueMax = codeInfo['value_max'];
    final valueMin = codeInfo['value_min'];
    final valueDiv = codeInfo['value_div'];
    final description = codeInfo['description'] ?? '';
    final codes =
        (codeInfo['codes'] as List<dynamic>)
            .map((codeJson) => CodeData.fromJson(codeJson))
            .toList();

    return Code(
      name: name,
      description: description,
      codes: codes,
      isValue: isValue,
      valueMax: valueMax,
      valueMin: valueMin,
      valueDiv: valueDiv,
    );
  }

  void applyCode() {
    for (var code in codes) {
      code.applyCodeChange(value);
    }
  }
}

class CodeData {
  final String address;
  final String bytes;

  CodeData({required this.address, required this.bytes});

  static CodeData fromJson(Map<String, dynamic> codeInfo) {
    return CodeData(
      address: codeInfo['address'] ?? '',
      bytes: codeInfo['bytes'] ?? '',
    );
  }

  int getAddressAsInt() {
    return int.parse(address, radix: 16);
  }

  List<int> intToByteList(int value, int byteSize) {
    List<int> bytes = [];
    for (int i = 0; i < byteSize; i++) {
      bytes.add((value >> (8 * i)) & 0xFF);
    }
    return bytes;
  }

  void applyCodeChange(int? value) {
    print('Applying code at address: $address with bytes: $bytes');

    List<int> byteList;

    if (bytes.startsWith("X")) {
      int byteSize = int.parse(bytes.substring(1)); // Extract number from "X4"
      if (value == null) {
        print('Error: No value provided for value-based code.');
        return;
      }
      byteList = intToByteList(value, byteSize);
    } else {
      byteList = bytes.split(' ').map((e) => int.parse(e, radix: 16)).toList();
    }

    final buffer = malloc<Uint8>(byteList.length);
    for (int i = 0; i < byteList.length; i++) {
      buffer[i] = byteList[i];
    }

    var addr = MemoryEditor.moduleBase + int.parse(address, radix: 16);
    MemoryEditor.virtualProtect(
      Pointer<Uint32>.fromAddress(addr),
      byteList.length,
    );

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
