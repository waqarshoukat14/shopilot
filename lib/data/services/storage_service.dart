import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'api_service.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();

  /// Picks an image from gallery and uploads it to the server via
  /// POST /api/upload, returning the hosted URL (resolves from any device).
  ///
  /// Falls back to a local file copy (only resolves on this device) if
  /// [token] is missing/invalid or the upload fails, so picking an image
  /// still works offline.
  Future<String?> pickAndUploadImage(String path, {String? token}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final hasApiToken = token != null && token.isNotEmpty && !token.startsWith('session:');
    if (hasApiToken) {
      try {
        return await _api.uploadImage(token: token, file: File(picked.path));
      } catch (e) {
        debugPrint('StorageService.pickAndUploadImage: upload failed: $e');
      }
    }

    try {
      // Fallback: save to app's documents directory (local-only path).
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images/$path');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final destPath = '${imagesDir.path}/$fileName';
      final file = File(picked.path);
      await file.copy(destPath);
      return destPath;
    } catch (_) {
      // Fallback: return the original picked path
      return picked.path;
    }
  }

  /// Upload a file from a given path.
  Future<String?> uploadImageFromFile(String path, File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images/$path');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final destPath = '${imagesDir.path}/$fileName';
      await file.copy(destPath);
      return destPath;
    } catch (_) {
      return file.path;
    }
  }

  /// Deletes a local image file.
  Future<void> deleteImage(String url) async {
    try {
      final file = File(url);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
