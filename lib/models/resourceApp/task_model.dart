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
  final String? timeRequired;
  final DateTime? completedAt;
  final String? completionNote;

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
    this.timeRequired,
    this.completedAt,
    this.completionNote,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
      timeRequired: data['timeRequired'],
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      completionNote: data['completionNote'],
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
      'timeRequired': timeRequired,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completionNote': completionNote,
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
}
