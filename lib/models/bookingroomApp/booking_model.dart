import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String roomId;
  final String roomName;
  final String eventAgenda;
  final DateTime usageStartDate;
  final DateTime usageEndDate;
  final String needs;
  final int numberOfParticipants;
  final String status;
  final DateTime createdAt;
  final String? completionReason;
  final DateTime? completionDate;

  BookingModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.roomId,
    required this.roomName,
    required this.eventAgenda,
    required this.usageStartDate,
    required this.usageEndDate,
    required this.needs,
    required this.numberOfParticipants,
    required this.status,
    required this.createdAt,
    this.completionReason,
    this.completionDate,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return BookingModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      eventAgenda: data['eventAgenda'] ?? '',
      usageStartDate: (data['usageStartDate'] as Timestamp).toDate(),
      usageEndDate: (data['usageEndDate'] as Timestamp).toDate(),
      needs: data['needs'] ?? '',
      numberOfParticipants: data['numberOfParticipants'] ?? 0,
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completionReason: data['completionReason'],
      completionDate: data['completionDate'] != null
          ? (data['completionDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'roomId': roomId,
      'roomName': roomName,
      'eventAgenda': eventAgenda,
      'usageStartDate': Timestamp.fromDate(usageStartDate),
      'usageEndDate': Timestamp.fromDate(usageEndDate),
      'needs': needs,
      'numberOfParticipants': numberOfParticipants,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completionReason': completionReason,
      'completionDate':
          completionDate != null ? Timestamp.fromDate(completionDate!) : null,
    };
  }

  String getStatusDisplayName() {
    switch (status) {
      case 'open':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case 'open':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  BookingModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? roomId,
    String? roomName,
    String? eventAgenda,
    DateTime? usageDateTime,
    String? needs,
    int? numberOfParticipants,
    String? status,
    DateTime? createdAt,
    String? completionReason,
    DateTime? completionDate,
  }) {
    return BookingModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      eventAgenda: eventAgenda ?? this.eventAgenda,
      usageStartDate: usageStartDate ?? this.usageStartDate,
      usageEndDate: usageEndDate ?? this.usageEndDate,
      needs: needs ?? this.needs,
      numberOfParticipants: numberOfParticipants ?? this.numberOfParticipants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completionReason: completionReason ?? this.completionReason,
      completionDate: completionDate ?? this.completionDate,
    );
  }
}
