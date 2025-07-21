import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String roomName;
  final String itemName;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? completionReason;
  final String? assignedTechnicianId;
  final String? technicianName;
  final String? imageUrl;
  final DateTime? completionDate;

  ReportModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.roomName,
    required this.itemName,
    required this.description,
    required this.status,
    required this.createdAt,
    this.completionReason,
    this.assignedTechnicianId,
    this.technicianName,
    this.imageUrl,
    this.completionDate,
  });

  /// Membuat ReportModel dari Firestore document
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final imageUrl = data['imageUrl'];
    if (imageUrl != null) {
      print(
          '[ReportModel] Document ID: ${doc.id}, Image URL ditemukan: ${imageUrl.toString().substring(0, min(30, imageUrl.toString().length))}...');
    } else {
      print('[ReportModel] Document ID: ${doc.id}, Image URL tidak ada');
    }

    return ReportModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      roomName: data['roomName'] ?? '',
      itemName: data['itemName'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completionReason: data['completionReason'],
      assignedTechnicianId: data['assignedTechnicianId'],
      technicianName: data['technicianName'],
      imageUrl: imageUrl,
      completionDate: data['completionDate'] != null
          ? (data['completionDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Mengkonversi ReportModel ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      print(
          '[ReportModel] Menyimpan image URL: ${imageUrl!.substring(0, min(30, imageUrl!.length))}...');
    } else {
      print('[ReportModel] Tidak ada image URL untuk disimpan');
    }

    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'roomName': roomName,
      'itemName': itemName,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completionReason': completionReason,
      'assignedTechnicianId': assignedTechnicianId,
      'technicianName': technicianName,
      'imageUrl': imageUrl,
      'completionDate':
          completionDate != null ? Timestamp.fromDate(completionDate!) : null,
    };
  }

  /// Mendapatkan nama status yang ditampilkan
  String getStatusDisplayName() {
    switch (status) {
      case 'open':
        return 'Open';
      case 'inProgress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }

  /// Mendapatkan warna berdasarkan status
  Color getStatusColor() {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'inProgress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Mendapatkan icon berdasarkan status
  IconData getStatusIcon() {
    switch (status) {
      case 'open':
        return Icons.pending;
      case 'inProgress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  /// Membuat salinan ReportModel dengan beberapa field yang diubah
  ReportModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? roomName,
    String? itemName,
    String? description,
    String? status,
    DateTime? createdAt,
    String? completionReason,
    String? assignedTechnicianId,
    String? technicianName,
    String? imageUrl,
    DateTime? completionDate,
  }) {
    return ReportModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      roomName: roomName ?? this.roomName,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completionReason: completionReason ?? this.completionReason,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      technicianName: technicianName ?? this.technicianName,
      imageUrl: imageUrl ?? this.imageUrl,
      completionDate: completionDate ?? this.completionDate,
    );
  }

  /// Memeriksa apakah gambar valid dan dapat ditampilkan
  bool hasValidImage() {
    // Jika URL kosong atau null, gambar tidak valid
    if (imageUrl == null || imageUrl!.isEmpty) {
      print('[ReportModel] Gambar tidak valid: URL kosong atau null');
      return false;
    }

    // URL harus dimulai dengan http, https, atau gs://
    if (!imageUrl!.startsWith('http') &&
        !imageUrl!.startsWith('https') &&
        !imageUrl!.startsWith('gs://')) {
      print(
          '[ReportModel] Gambar tidak valid: URL tidak dimulai dengan http/https/gs://: $imageUrl');
      return false;
    }

    // Tidak boleh mengandung kata "undefined" atau "null"
    if (imageUrl!.toLowerCase().contains('undefined') ||
        imageUrl!.toLowerCase().contains('null')) {
      print(
          '[ReportModel] Gambar tidak valid: URL mengandung "undefined" atau "null"');
      return false;
    }

    return true;
  }

  /// Normalisasi URL gambar untuk ditampilkan
  String? getNormalizedImageUrl() {
    if (!hasValidImage()) {
      return null;
    }

    // Jika URL sudah dimulai dengan http/https, gunakan langsung
    if (imageUrl!.startsWith('http')) {
      return imageUrl;
    }

    // Jika URL dimulai dengan gs://, ini adalah Firebase Storage URL
    // URL ini akan ditangani oleh FirebaseStorageImage widget
    return imageUrl;
  }
}

// Helper function untuk menghindari error substring
int min(int a, int b) {
  return a < b ? a : b;
}
