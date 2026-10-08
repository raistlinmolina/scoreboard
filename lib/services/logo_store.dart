import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Copies picked team logos into the app's permanent documents directory, so a
/// saved logo survives even if the OS purges the image picker's cache.
class LogoStore {
  static const String _subdir = 'logos';

  /// Copies [sourcePath] into `<appDocuments>/logos/` with a unique filename
  /// and returns the new permanent path. If the copy fails, returns the
  /// original path as a fallback so the user still gets a logo.
  Future<String> persist(String sourcePath) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/$_subdir');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // Preserve the original extension (default to .png).
      final dot = sourcePath.lastIndexOf('.');
      final ext = (dot >= 0 && dot > sourcePath.lastIndexOf('/'))
          ? sourcePath.substring(dot)
          : '.png';
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final destPath = '${dir.path}/logo_$stamp$ext';
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (_) {
      return sourcePath;
    }
  }
}
