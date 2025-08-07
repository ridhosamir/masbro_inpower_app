import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String buildingId;
  final String buildingName;
  final String roomId;
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
  final double? technicianRating; // Technician rating field
  final String? technicianReview; // Added technician review field
  final String? afterImageUrl; // Added after image URL field

  ReportModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.buildingId,
    required this.buildingName,
    required this.roomId,
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
    this.technicianRating,
    this.technicianReview, // Add to constructor
    this.afterImageUrl, // Add to constructor
  });

  /// Create ReportModel from Firestore document
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final imageUrl = data['imageUrl'];
    if (imageUrl != null) {
      print(
          '[ReportModel] Document ID: ${doc.id}, Image URL found: ${imageUrl.toString().substring(0, min(30, imageUrl.toString().length))}...');
    } else {
      print('[ReportModel] Document ID: ${doc.id}, Image URL not found');
    }

    // Handle technician rating conversion from Firestore
    double? technicianRating;
    if (data['technicianRating'] != null) {
      technicianRating = data['technicianRating'] is int
          ? (data['technicianRating'] as int).toDouble()
          : data['technicianRating'] as double;
    }

    return ReportModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      buildingId: data['buildingId'] ?? '',
      buildingName: data['buildingName'] ?? '',
      roomId: data['roomId'] ?? '',
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
      technicianRating: technicianRating,
      technicianReview: data['technicianReview'], // Add to return object
      afterImageUrl: data['afterImageUrl'], // Add to return object
    );
  }

  /// Convert ReportModel to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      print(
          '[ReportModel] Saving image URL: ${imageUrl!.substring(0, min(30, imageUrl!.length))}...');
    } else {
      print('[ReportModel] No image URL to save');
    }

    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'buildingId': buildingId,
      'buildingName': buildingName,
      'roomId': roomId,
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
      'technicianRating': technicianRating,
      'technicianReview': technicianReview, // Add to map
      'afterImageUrl': afterImageUrl, // Add to map
    };
  }

  /// Get display status name
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

  /// Get status color
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

  /// Get status icon
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

  /// Create a copy of ReportModel with some fields changed
  ReportModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? buildingId,
    String? buildingName,
    String? roomId,
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
    double? technicianRating,
    String? technicianReview,
    String? afterImageUrl,
  }) {
    return ReportModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      buildingId: buildingId ?? this.buildingId,
      buildingName: buildingName ?? this.buildingName,
      roomId: roomId ?? this.roomId,
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
      technicianRating: technicianRating ?? this.technicianRating,
      technicianReview: technicianReview ?? this.technicianReview,
      afterImageUrl: afterImageUrl ?? this.afterImageUrl,
    );
  }

  /// Check if image is valid and can be displayed
  bool hasValidImage() {
    // If URL is empty or null, image is not valid
    if (imageUrl == null || imageUrl!.isEmpty) {
      print('[ReportModel] Image not valid: URL is empty or null');
      return false;
    }

    // URL must start with http, https, or gs://
    if (!imageUrl!.startsWith('http') &&
        !imageUrl!.startsWith('https') &&
        !imageUrl!.startsWith('gs://')) {
      print(
          '[ReportModel] Image not valid: URL does not start with http/https/gs://: $imageUrl');
      return false;
    }

    // URL must not contain "undefined" or "null"
    if (imageUrl!.toLowerCase().contains('undefined') ||
        imageUrl!.toLowerCase().contains('null')) {
      print(
          '[ReportModel] Image not valid: URL contains "undefined" or "null"');
      return false;
    }

    return true;
  }

  /// Check if after image is valid and can be displayed
  bool hasValidAfterImage() {
    // If URL is empty or null, image is not valid
    if (afterImageUrl == null || afterImageUrl!.isEmpty) {
      return false;
    }

    // URL must start with http, https, or gs://
    if (!afterImageUrl!.startsWith('http') &&
        !afterImageUrl!.startsWith('https') &&
        !afterImageUrl!.startsWith('gs://')) {
      return false;
    }

    // URL must not contain "undefined" or "null"
    if (afterImageUrl!.toLowerCase().contains('undefined') ||
        afterImageUrl!.toLowerCase().contains('null')) {
      return false;
    }

    return true;
  }

  /// Check if report has technician review
  bool hasReview() {
    return technicianReview != null && technicianReview!.isNotEmpty;
  }

  /// Normalize image URL for display
  String? getNormalizedImageUrl() {
    if (!hasValidImage()) {
      return null;
    }

    // If URL already starts with http/https, use directly
    if (imageUrl!.startsWith('http')) {
      return imageUrl;
    }

    // If URL starts with gs://, this is a Firebase Storage URL
    // This URL will be handled by FirebaseStorageImage widget
    return imageUrl;
  }

  /// Normalize after image URL for display
  String? getNormalizedAfterImageUrl() {
    if (!hasValidAfterImage()) {
      return null;
    }

    // If URL already starts with http/https, use directly
    if (afterImageUrl!.startsWith('http')) {
      return afterImageUrl;
    }

    // If URL starts with gs://, this is a Firebase Storage URL
    return afterImageUrl;
  }
}

// Helper function to avoid substring error
int min(int a, int b) {
  return a < b ? a : b;
}
