import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static const _uuid = Uuid();

  Future<Directory> _baseDir() async {
    final base = await getApplicationDocumentsDirectory();
    return base;
  }

  Future<Directory> getAudioDirectory() async {
    final dir = Directory(p.join((await _baseDir()).path, 'audio'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> getImageDirectory() async {
    final dir = Directory(p.join((await _baseDir()).path, 'images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> getScreenshotDirectory() async {
    final dir = Directory(p.join((await _baseDir()).path, 'screenshots'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Moves an audio file from [sourcePath] (usually a temp path) to the app's
  /// audio directory and returns the relative path from app docs dir.
  Future<String> saveAudioFile(String sourcePath) async {
    final audioDir = await getAudioDirectory();
    final ext = p.extension(sourcePath);
    final filename = '${_uuid.v4()}$ext';
    final destPath = p.join(audioDir.path, filename);
    await File(sourcePath).copy(destPath);
    // Return relative path from app docs dir
    final base = await _baseDir();
    return p.relative(destPath, from: base.path);
  }

  /// Saves raw image bytes to the images directory. Returns the relative path.
  Future<String> saveImageBytes(Uint8List bytes, {String ext = '.jpg'}) async {
    final imageDir = await getImageDirectory();
    final filename = '${_uuid.v4()}$ext';
    final fullPath = p.join(imageDir.path, filename);
    await File(fullPath).writeAsBytes(bytes);
    final base = await _baseDir();
    return p.relative(fullPath, from: base.path);
  }

  /// Copies a screenshot from an external path (e.g. DCIM/Screenshots) into
  /// the app's screenshots directory. Returns the relative path.
  Future<String> saveScreenshotFromPath(String sourcePath) async {
    final screenshotDir = await getScreenshotDirectory();
    final ext = p.extension(sourcePath);
    final filename = '${_uuid.v4()}$ext';
    final destPath = p.join(screenshotDir.path, filename);
    await File(sourcePath).copy(destPath);
    final base = await _baseDir();
    return p.relative(destPath, from: base.path);
  }

  /// Resolves a relative path (as returned by the save methods) to an absolute path.
  Future<String> resolve(String relativePath) async {
    final base = await _baseDir();
    return p.join(base.path, relativePath);
  }

  /// Reads a file by its relative path and returns raw bytes.
  Future<Uint8List> readFileAsBytes(String relativePath) async {
    final fullPath = await resolve(relativePath);
    return File(fullPath).readAsBytes();
  }

  /// Deletes a file by its relative path. Silently ignores if file does not exist.
  Future<void> deleteFile(String relativePath) async {
    final fullPath = await resolve(relativePath);
    final file = File(fullPath);
    if (await file.exists()) await file.delete();
  }

  /// Returns the File object for a relative path.
  Future<File> getFile(String relativePath) async {
    final fullPath = await resolve(relativePath);
    return File(fullPath);
  }
}
