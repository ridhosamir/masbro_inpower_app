// lib/utils/download_helper_io.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> save(List<int> bytes, String fileName) async {
  var status = await Permission.storage.request();
  if (!status.isGranted) {
    throw Exception('Izin penyimpanan ditolak.');
  }
  final directory = await getExternalStorageDirectory();
  final path = '${directory!.path}/$fileName';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(path);
}
