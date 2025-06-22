import 'dart:convert';

class Settings {
  String tyDirectoryPath;
  bool updateManager;
  String launchArgs;

  Settings({required this.tyDirectoryPath, required this.updateManager, required this.launchArgs});

  Map<String, dynamic> toMap() {
    return {'tyDirectoryPath': tyDirectoryPath, 'updateManager': updateManager, 'launchArgs': launchArgs};
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      tyDirectoryPath: map['tyDirectoryPath'] ?? '',
      updateManager: map['updateManager'] ?? true,
      launchArgs: map['launchArgs'] ?? '',
    );
  }

  String toJson() {
    final jsonMap = toMap();
    return jsonEncode(jsonMap);
  }

  factory Settings.fromJson(String json) {
    final jsonMap = jsonDecode(json);
    return Settings.fromMap(jsonMap);
  }
}
