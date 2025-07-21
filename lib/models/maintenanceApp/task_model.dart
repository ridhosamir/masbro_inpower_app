import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? imageUrl; // Added for photo functionality

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
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
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
    };
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

  // Helper method to get status color and icon
  Map<String, dynamic> getStatusStyles() {
    switch (status) {
      case 'inProgress':
        return {
          'color': 'blue',
          'icon': 'engineering',
        };
      case 'completed':
        return {
          'color': 'green',
          'icon': 'check_circle',
        };
      default:
        return {
          'color': 'grey',
          'icon': 'help',
        };
    }
  }
}
