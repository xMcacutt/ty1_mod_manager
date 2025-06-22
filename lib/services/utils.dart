import 'dart:io';

Future<void> recursiveCopyDirectory(Directory source, Directory destination) async {
  // Check if the source directory exists
  if (!await source.exists()) {
    print('Source directory does not exist');
    return;
  }

  // Create the destination directory if it doesn't exist
  if (!await destination.exists()) {
    await destination.create(recursive: true);
  }

  // List all files and directories in the source directory
  await for (var entity in source.list(recursive: false)) {
    if (entity is File) {
      // Copy the files to the destination directory
      await entity.copy('${destination.path}/${entity.uri.pathSegments.last}');
    } else if (entity is Directory) {
      // Recursively copy the subdirectories
      await recursiveCopyDirectory(entity, Directory('${destination.path}/${entity.uri.pathSegments.last}'));
    }
  }
}

int getAddressAsInt(String address) {
  return int.parse(address, radix: 16);
}

List<int> intToByteList(int value, int byteSize) {
  List<int> bytes = [];
  for (int i = 0; i < byteSize; i++) {
    bytes.add((value >> (8 * i)) & 0xFF);
  }
  return bytes;
}

String getAppDirectory() {
  return File(Platform.resolvedExecutable).parent.path;
}
