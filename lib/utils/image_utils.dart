import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

Future<XFile?> compressImage(XFile file) async {
  final compressed = await FlutterImageCompress.compressWithFile(
    file.path,
    minWidth: 800,
    minHeight: 800,
    quality: 25,
  );

  if (compressed == null) return null;

  final tempDir = Directory.systemTemp;
  final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final compressedFile = await File(targetPath).writeAsBytes(compressed);
  return XFile(compressedFile.path);
}
