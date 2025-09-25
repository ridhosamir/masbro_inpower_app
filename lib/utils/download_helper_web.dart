// lib/utils/download_helper_web.dart

import 'dart:html' as html;

Future<void> save(List<int> bytes, String fileName) async {
  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..style.display = "none";

    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    throw Exception('Gagal mengunduh file di web: $e');
  }
}
