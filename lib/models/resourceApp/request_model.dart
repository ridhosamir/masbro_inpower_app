import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? timeRequired;
  final String? completionReason;
  final String? assignedTechnicianId;
  final String? technicianName;
  final DateTime? completionDate;

  RequestModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.description,
    required this.status,
    required this.createdAt,
    this.timeRequired,
    this.completionReason,
    this.assignedTechnicianId,
    this.technicianName,
    this.completionDate,
  });

  /// Membuat RequestModel dari Firestore document
  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return RequestModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      timeRequired: data['timeRequired'],
      completionReason: data['completionReason'],
      assignedTechnicianId: data['assignedTechnicianId'],
      technicianName: data['technicianName'],
      completionDate: data['completionDate'] != null
          ? (data['completionDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Mengkonversi RequestModel ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'timeRequired': timeRequired,
      'completionReason': completionReason,
      'assignedTechnicianId': assignedTechnicianId,
      'technicianName': technicianName,
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
    String? timeRequired,
    String? completionReason,
    String? assignedTechnicianId,
    String? technicianName,
    DateTime? completionDate,
  }) {
    return RequestModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      timeRequired: timeRequired ?? this.timeRequired,
      completionReason: completionReason ?? this.completionReason,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      technicianName: technicianName ?? this.technicianName,
      completionDate: completionDate ?? this.completionDate,
    );
  }
}
