import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class RequestModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String description;
  final String status;
  final DateTime createdAt;
  final String request;
  final String? timeRequired;
  final String? completionReason;
  final String? assignedTechnicianId;
  final String? technicianName;
  final String? imageUrl;
  final DateTime? completionDate;

  RequestModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.request,
    this.timeRequired,
    this.completionReason,
    this.assignedTechnicianId,
    this.technicianName,
    this.imageUrl,
    this.completionDate,
  });

  /// Membuat RequestModel dari Firestore document
  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final imageUrl = data['imageUrl'];
    // Logging untuk debugging URL gambar saat data diambil
    if (imageUrl != null) {
      print(
          '[RequestModel] Document ID: ${doc.id}, Image URL found: ${imageUrl.toString().substring(0, min(30, imageUrl.toString().length))}...');
    } else {
      print('[RequestModel] Document ID: ${doc.id}, Image URL not found');
    }

    return RequestModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      request: data['request'] ?? 'resource',
      timeRequired: data['timeRequired'],
      completionReason: data['completionReason'],
      assignedTechnicianId: data['assignedTechnicianId'],
      technicianName: data['technicianName'],
      imageUrl: imageUrl,
      completionDate: data['completionDate'] != null
          ? (data['completionDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Mengkonversi RequestModel ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      print(
          '[RequestModel] Saving image URL: ${imageUrl!.substring(0, min(30, imageUrl!.length))}...');
    } else {
      print('[RequestModel] No image URL to save');
    }

    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'request': request,
      'timeRequired': timeRequired,
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

  /// Membuat salinan RequestModel dengan beberapa field yang diubah
  RequestModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? description,
    String? status,
    DateTime? createdAt,
    String? request,
    String? timeRequired,
    String? completionReason,
    String? assignedTechnicianId,
    String? technicianName,
    String? imageUrl,
    DateTime? completionDate,
  }) {
    return RequestModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      request: request ?? this.request,
      timeRequired: timeRequired ?? this.timeRequired,
      completionReason: completionReason ?? this.completionReason,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      technicianName: technicianName ?? this.technicianName,
      imageUrl: imageUrl ?? this.imageUrl,
      completionDate: completionDate ?? this.completionDate,
    );
  }

  bool hasValidImage() {
    // Jika URL kosong atau null, gambar tidak valid
    if (imageUrl == null || imageUrl!.isEmpty) {
      print('[RequestModel] Image not valid: URL is empty or null');
      return false;
    }

    if (!imageUrl!.startsWith('http') &&
        !imageUrl!.startsWith('https') &&
        !imageUrl!.startsWith('gs://')) {
      print(
          '[RequestModel] Image not valid: URL does not start with http/https/gs://: $imageUrl');
      return false;
    }

    // URL tidak boleh mengandung "undefined" atau "null"
    if (imageUrl!.toLowerCase().contains('undefined') ||
        imageUrl!.toLowerCase().contains('null')) {
      print(
          '[RequestModel] Image not valid: URL contains "undefined" or "null"');
      return false;
    }

    return true;
  }

  /// Menormalkan URL gambar untuk ditampilkan
  String? getNormalizedImageUrl() {
    if (!hasValidImage()) {
      return null;
    }

    // Jika URL sudah dimulai dengan http/https, gunakan secara langsung
    if (imageUrl!.startsWith('http')) {
      return imageUrl;
    }

    // Jika URL dimulai dengan gs://, ini adalah URL Firebase Storage
    // URL ini akan ditangani oleh widget seperti FirebaseStorageImage
    return imageUrl;
  }
}

// Helper function untuk menghindari error substring
int min(int a, int b) {
  return a < b ? a : b;
}
