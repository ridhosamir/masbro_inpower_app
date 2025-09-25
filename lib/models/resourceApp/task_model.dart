import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String requestId;
  final String assignedTo;
  final String technicianName;
  final String requesterName;
  final String description;
  final String status; // inProgress, completed
  final DateTime assignedAt;
  final String request;
  final String requestType;
  final String? timeRequired;
  final DateTime? completedAt;
  final String? completionNote;
  final String? imageUrl;
  final double? userRating;
  final String? userReview;
  final String? afterImageUrl;

  TaskModel({
    required this.id,
    required this.requestId,
    required this.assignedTo,
    required this.technicianName,
    required this.requesterName,
    required this.description,
    required this.status,
    required this.assignedAt,
    required this.request,
    required this.requestType,
    this.timeRequired,
    this.completedAt,
    this.completionNote,
    this.imageUrl,
    this.userRating,
    this.userReview,
    this.afterImageUrl,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    double? userRating;
    if (data['userRating'] != null) {
      userRating = data['userRating'] is int
          ? (data['userRating'] as int).toDouble()
          : data['userRating'] as double;
    }

    return TaskModel(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      technicianName: data['technicianName'] ?? '',
      requesterName: data['requesterName'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'inProgress',
      assignedAt: (data['assignedAt'] as Timestamp).toDate(),
      request: data['request'] ?? 'resource',
      requestType: data['requestType'] ?? 'Sedang',
      timeRequired: data['timeRequired'],
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      completionNote: data['completionNote'],
      imageUrl: data['imageUrl'],
      userRating: userRating,
      userReview: data['userReview'],
      afterImageUrl: data['afterImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'assignedTo': assignedTo,
      'technicianName': technicianName,
      'requesterName': requesterName,
      'description': description,
      'status': status,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'request': request,
      'requestType': requestType,
      'timeRequired': timeRequired,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completionNote': completionNote,
      'imageUrl': imageUrl,
      'userRating': userRating,
      'userReview': userReview,
      'afterImageUrl': afterImageUrl,
    };
  }

  /// Mendapatkan nama status yang ditampilkan
  String getStatusDisplayName() {
    switch (status) {
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
      case 'inProgress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  bool hasValidImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return false;
    }
    if (!imageUrl!.startsWith('http') &&
        !imageUrl!.startsWith('https') &&
        !imageUrl!.startsWith('gs://')) {
      return false;
    }
    if (imageUrl!.toLowerCase().contains('undefined') ||
        imageUrl!.toLowerCase().contains('null')) {
      return false;
    }
    return true;
  }

  /// Menormalkan URL gambar untuk ditampilkan
  String? getNormalizedImageUrl() {
    if (!hasValidImage()) {
      return null;
    }
    return imageUrl;
  }
}
