import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String reportId;
  final String assignedTo;
  final String technicianName;
  final String roomName;
  final String itemName;
  final String description;
  final String status; // inProgress, completed
  final DateTime assignedAt;
  final DateTime? completedAt;
  final String? completionNote;
  final String? imageUrl; // Original issue image
  final String? afterImageUrl; // New field for "after" completion image
  final double? userRating; // New field for user rating
  final String? userReview; // New field for user review text

  TaskModel({
    required this.id,
    required this.reportId,
    required this.assignedTo,
    required this.technicianName,
    required this.roomName,
    required this.itemName,
    required this.description,
    required this.status,
    required this.assignedAt,
    this.completedAt,
    this.completionNote,
    this.imageUrl,
    this.afterImageUrl, // Add to constructor
    this.userRating, // Add to constructor
    this.userReview, // Add to constructor
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle rating conversion from Firestore
    double? userRating;
    if (data['userRating'] != null) {
      userRating = data['userRating'] is int
          ? (data['userRating'] as int).toDouble()
          : data['userRating'] as double;
    }

    return TaskModel(
      id: doc.id,
      reportId: data['reportId'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      technicianName: data['technicianName'] ?? '',
      roomName: data['roomName'] ?? '',
      itemName: data['itemName'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'inProgress',
      assignedAt: (data['assignedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      completionNote: data['completionNote'],
      imageUrl: data['imageUrl'],
      afterImageUrl: data['afterImageUrl'], // Get from Firestore
      userRating: userRating, // Get from Firestore
      userReview: data['userReview'], // Get from Firestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'assignedTo': assignedTo,
      'technicianName': technicianName,
      'roomName': roomName,
      'itemName': itemName,
      'description': description,
      'status': status,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completionNote': completionNote,
      'imageUrl': imageUrl,
      'afterImageUrl': afterImageUrl, // Save to Firestore
      'userRating': userRating, // Save to Firestore
      'userReview': userReview, // Save to Firestore
    };
  }

  // Create a copy of TaskModel with updated fields
  TaskModel copyWith({
    String? id,
    String? reportId,
    String? assignedTo,
    String? technicianName,
    String? roomName,
    String? itemName,
    String? description,
    String? status,
    DateTime? assignedAt,
    DateTime? completedAt,
    String? completionNote,
    String? imageUrl,
    String? afterImageUrl,
    double? userRating,
    String? userReview,
  }) {
    return TaskModel(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      assignedTo: assignedTo ?? this.assignedTo,
      technicianName: technicianName ?? this.technicianName,
      roomName: roomName ?? this.roomName,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      completionNote: completionNote ?? this.completionNote,
      imageUrl: imageUrl ?? this.imageUrl,
      afterImageUrl: afterImageUrl ?? this.afterImageUrl,
      userRating: userRating ?? this.userRating,
      userReview: userReview ?? this.userReview,
    );
  }

  // Helper method to get display name for status
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

  // Helper method to get status color
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

  // Helper method to get status icon
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

  // Check if task has an after image
  bool hasAfterImage() {
    return afterImageUrl != null && afterImageUrl!.isNotEmpty;
  }

  // Check if task has been rated
  bool hasRating() {
    return userRating != null;
  }

  // Get rating display text
  String getRatingText() {
    if (userRating == null) return 'Not Rated';
    return '${userRating!.toStringAsFixed(1)} Stars';
  }

  // Get color based on rating
  Color getRatingColor() {
    if (userRating == null) return Colors.grey;
    if (userRating! >= 4.5) return Colors.green;
    if (userRating! >= 3.5) return Colors.amber;
    if (userRating! >= 2.5) return Colors.orange;
    return Colors.red;
  }
}
