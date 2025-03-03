import 'package:package_info_plus/package_info_plus.dart';

String? _cachedAppVersion;

void initAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  _cachedAppVersion = packageInfo.version;
}

String getAppVersion() {
  return _cachedAppVersion ?? '?.?.?';
}
