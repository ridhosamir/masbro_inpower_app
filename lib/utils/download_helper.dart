// lib/utils/download_helper.dart

// Import ini akan digunakan jika BUKAN web (IO).
import 'package:masbro_inpower_app/utils/download_helper_mobile.dart'
    // Import ini akan digunakan HANYA JIKA ini adalah web.
    if (dart.library.html) 'package:masbro_inpower_app/utils/download_helper_web.dart';

// Kita membuat class abstract atau class biasa dengan metode yang akan diimplementasikan
// oleh file-file di atas.
class DownloadHelper {
  static Future<void> saveAndOpenFile(List<int> bytes, String fileName) async {
    // Fungsi 'save' ini akan secara dinamis memanggil implementasi
    // yang benar (IO atau Web) berdasarkan platform.
    await save(bytes, fileName);
  }
}
