import 'dependency.dart';

class Mod {
  final String name;
  final String version;
  final String description;
  final List<Dependency> dependencies;
  final List<String> conflicts;
  final String? iconUrl;
  final String author;
  final String lastUpdated;
  final String dllName;
  final String downloadUrl;
  final String website;
  final List<String> games;

  Mod({
    required this.name,
    required this.version,
    required this.description,
    required this.dependencies,
    required this.conflicts,
    this.iconUrl,
    required this.author,
    required this.lastUpdated,
    required this.dllName,
    required this.downloadUrl,
    required this.website,
    required this.games,
  });

  factory Mod.fromJson(Map<String, dynamic> json) {
    return Mod(
      name: json['name'] ?? '',
      version: json['version'] ?? '',
      description: json['description'] ?? '',
      dependencies:
          (json['dependencies'] as List<dynamic>?)
              ?.map((dep) => Dependency.fromJson(dep as Map<String, dynamic>))
              .toList() ??
          [],
      conflicts: List<String>.from(json['conflicts'] ?? []),
      iconUrl: json['icon_url'] as String?,
      author: json['author'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
      dllName: json['dll_name'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      website: json['website'] ?? '',
      games: json['games'] ?? ['Ty 1'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'version': version,
    'description': description,
    'dependencies': dependencies.map((dep) => dep.toJson()).toList(),
    'conflicts': conflicts,
    'icon_url': iconUrl,
    'author': author,
    'last_updated': lastUpdated,
    'dll_name': dllName,
    'download_url': downloadUrl,
    'website': website,
    'games': games,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Mod) return false;
    return other.name == name && other.version == version;
  }

  @override
  int get hashCode => Object.hash(name, version);

  static Mod get none => Mod(
    name: '',
    version: '',
    description: '',
    dependencies: [],
    conflicts: [],
    author: '',
    lastUpdated: '',
    dllName: '',
    downloadUrl: '',
    website: '',
    games: [],
  );
}
