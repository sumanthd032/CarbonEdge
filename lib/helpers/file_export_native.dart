import 'dart:io';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';

class FileExportHelper {
  static Future<void> saveAndOpenFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = Directory.systemTemp;
    final file = File("${dir.path}/$fileName");
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }
}
