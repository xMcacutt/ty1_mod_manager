class Dependency {
  final String name;
  final String url;
  final String version;

  Dependency({required this.name, required this.url, required this.version});

  factory Dependency.fromJson(Map<String, dynamic> json) {
    return Dependency(name: json['dep_name'] ?? '', url: json['dep_url'] ?? '', version: json['dep_version'] ?? '');
  }

  Map<String, dynamic> toJson() => {'dep_name': name, 'dep_url': url, 'dep_version': version};
}
