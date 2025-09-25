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
  final String activityType;
  final int numberOfParticipants;
  final String status;
  final DateTime createdAt;
  final String requestType;
  final String? completionReason;
  final DateTime? completionDate;
  final double? rating;
  final String? ratingComment;
  final DateTime? ratingDate;

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
    required this.activityType,
    required this.numberOfParticipants,
    required this.status,
    required this.createdAt,
    required this.requestType,
    this.completionReason,
    this.completionDate,
    this.rating,
    this.ratingComment,
    this.ratingDate,
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
      activityType: data['activityType'] ?? '',
      numberOfParticipants: data['numberOfParticipants'] ?? 0,
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      requestType: data['requestType'] ?? 'Sedang',
      completionReason: data['completionReason'],
      completionDate: data['completionDate'] != null
          ? (data['completionDate'] as Timestamp).toDate()
          : null,
      rating: (data['rating'] as num?)?.toDouble(),
      ratingComment: data['ratingComment'],
      ratingDate: data['ratingDate'] != null
          ? (data['ratingDate'] as Timestamp).toDate()
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
      'activityType': activityType,
      'numberOfParticipants': numberOfParticipants,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'requestType': requestType,
      'completionReason': completionReason,
      'completionDate':
          completionDate != null ? Timestamp.fromDate(completionDate!) : null,
      'rating': rating,
      'ratingComment': ratingComment,
      'ratingDate': ratingDate != null ? Timestamp.fromDate(ratingDate!) : null,
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
    DateTime? usageStartDate,
    DateTime? usageEndDate,
    String? needs,
    String? activityType,
    int? numberOfParticipants,
    String? status,
    DateTime? createdAt,
    String? requestType,
    String? completionReason,
    DateTime? completionDate,
    double? rating,
    String? ratingComment,
    DateTime? ratingDate,
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
      activityType: activityType ?? this.activityType,
      numberOfParticipants: numberOfParticipants ?? this.numberOfParticipants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      requestType: requestType ?? this.requestType,
      completionReason: completionReason ?? this.completionReason,
      completionDate: completionDate ?? this.completionDate,
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      ratingDate: ratingDate ?? this.ratingDate,
    );
  }
}
