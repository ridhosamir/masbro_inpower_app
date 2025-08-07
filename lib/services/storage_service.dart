import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  /// Upload file dari perangkat ke Firebase Storage
  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: _getContentType(path));

      // Upload file ke Firebase Storage
      await ref.putFile(file, metadata);

      // Dapatkan URL download
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('[STORAGE] Error uploading file: $e');
      throw Exception('Gagal mengunggah file: ${e.toString()}');
    }
  }

  /// Upload file dari web (Uint8List) ke Firebase Storage
  Future<String> uploadWebFile(Uint8List bytes, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: _getContentType(path),
        customMetadata: {'uploaded-from': 'web'},
      );

      // Upload data ke Firebase Storage
      await ref.putData(bytes, metadata);

      // Dapatkan URL download
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('[STORAGE] Error uploading web file: $e');
      throw Exception('Gagal mengunggah file: ${e.toString()}');
    }
  }

  /// Dapatkan URL download dari path Firebase Storage
  Future<String> getDownloadUrl(String path) async {
    try {
      // Normalisasi path agar konsisten
      final normalizedPath = _normalizePath(path);

      // Dapatkan URL download
      final downloadUrl =
          await _storage.ref().child(normalizedPath).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('[STORAGE] Error getting download URL: $e');
      throw Exception('Gagal mendapatkan URL gambar: ${e.toString()}');
    }
  }

  /// Perbarui URL download (memastikan URL masih valid)
  Future<String> refreshDownloadUrl(String path) async {
    try {
      // Normalisasi path agar konsisten
      final normalizedPath = _normalizePath(path);
      print('[STORAGE] Refreshing download URL for path: $normalizedPath');

      // Hapus cache untuk path ini
      try {
        final existingUrl =
            await _storage.ref().child(normalizedPath).getDownloadURL();
        await _cacheManager.removeFile(existingUrl);
      } catch (e) {
        // Jika tidak ada URL yang ada, lanjutkan saja
        print('[STORAGE] No existing URL to clear from cache');
      }

      // Dapatkan URL download baru
      final ref = _storage.ref().child(normalizedPath);
      final downloadUrl = await ref.getDownloadURL();

      // Tambahkan cache buster untuk memastikan URL selalu fresh
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final freshUrl = downloadUrl.contains('?')
          ? '$downloadUrl&cb=$timestamp'
          : '$downloadUrl?cb=$timestamp';

      print('[STORAGE] Fresh download URL: $freshUrl');
      return freshUrl;
    } catch (e) {
      print('[STORAGE] Error refreshing download URL: $e');
      throw Exception('Gagal memperbarui URL gambar: ${e.toString()}');
    }
  }

  /// Hapus file dari Firebase Storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();

      // Hapus dari cache juga
      await _cacheManager.removeFile(url);
    } catch (e) {
      print('[STORAGE] Error deleting file: $e');
      throw Exception('Gagal menghapus file: ${e.toString()}');
    }
  }

  /// Cek ketersediaan URL (verifikasi URL masih valid)
  Future<bool> isUrlValid(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('[STORAGE] Error checking URL validity: $e');
      return false;
    }
  }

  /// Normalisasi path agar konsisten
  String _normalizePath(String pathOrUrl) {
    // Jika path dimulai dengan gs://
    if (pathOrUrl.startsWith('gs://')) {
      try {
        final withoutPrefix = pathOrUrl.replaceFirst('gs://', '');
        final parts = withoutPrefix.split('/');

        // Ambil bagian path setelah bucket name
        if (parts.length > 1) {
          return parts.sublist(1).join('/');
        }

        print('[STORAGE] Invalid gs:// URL format: $pathOrUrl');
        return pathOrUrl;
      } catch (e) {
        print('[STORAGE] Error normalizing gs:// path: $e');
        return pathOrUrl;
      }
    }

    // Jika URL Firebase Storage lengkap
    if (pathOrUrl.startsWith('https://firebasestorage.googleapis.com')) {
      try {
        final uri = Uri.parse(pathOrUrl);
        final pathSegments = uri.pathSegments;

        // Ambil path dari URL (setelah 'o/')
        if (pathSegments.contains('o')) {
          final index = pathSegments.indexOf('o');
          if (index < pathSegments.length - 1) {
            // Decode URL-encoded path
            return Uri.decodeComponent(pathSegments[index + 1]);
          }
        }

        print('[STORAGE] Could not extract path from URL: $pathOrUrl');
        return pathOrUrl;
      } catch (e) {
        print('[STORAGE] Error extracting path from URL: $e');
        return pathOrUrl;
      }
    }

    // Jika sudah dalam format path biasa
    return pathOrUrl;
  }

  /// Dapatkan content type berdasarkan ekstensi file
  String _getContentType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
