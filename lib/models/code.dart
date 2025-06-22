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
    final codes = (codeInfo['codes'] as List<dynamic>).map((codeJson) => CodeData.fromJson(codeJson)).toList();

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
}

class CodeData {
  final String address;
  final String bytes;

  CodeData({required this.address, required this.bytes});

  static CodeData fromJson(Map<String, dynamic> codeInfo) {
    return CodeData(address: codeInfo['address'] ?? '', bytes: codeInfo['bytes'] ?? '');
  }
}
