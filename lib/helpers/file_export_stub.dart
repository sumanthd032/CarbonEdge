import 'dart:typed_data';

abstract class FileExportHelper {
  static Future<void> saveAndOpenFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    throw UnimplementedError('Platform not supported');
  }
}
