import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String requestId;
  final String assignedTo;
  final String technicianName;
  final String description;
  final String status; // inProgress, completed
  final DateTime assignedAt;
  final String? timeRequired;
  final DateTime? completedAt;
  final String? completionNote;

  TaskModel({
    required this.id,
    required this.requestId,
    required this.assignedTo,
    required this.technicianName,
    required this.description,
    required this.status,
    required this.assignedAt,
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
      description: data['description'] ?? '',
      status: data['status'] ?? 'inProgress',
      assignedAt: (data['assignedAt'] as Timestamp).toDate(),
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
      'description': description,
      'status': status,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'timeRequired': timeRequired,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completionNote': completionNote,
    };
  }
}
