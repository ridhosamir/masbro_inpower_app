import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RideRequestModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime pickupDateTime;
  final DateTime? returnDateTime;
  final int passengerCapacity;
  final String description;
  final String status; // 'open', 'inProgress', 'completed'
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final String? driverId;
  final String? driverName;
  final String? vehicleId;
  final String? vehicleName;
  final String? completionNote;

  // Rating fields
  final double? driverRating;
  final String? driverReview;
  final double? vehicleRating;
  final String? vehicleReview;

  RideRequestModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupDateTime,
    this.returnDateTime,
    required this.passengerCapacity,
    required this.description,
    required this.status,
    required this.createdAt,
    this.assignedAt,
    this.completedAt,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleName,
    this.completionNote,
    this.driverRating,
    this.driverReview,
    this.vehicleRating,
    this.vehicleReview,
  });

  factory RideRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideRequestModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      pickupLocation: data['pickupLocation'] ?? '',
      dropoffLocation: data['dropoffLocation'] ?? '',
      pickupDateTime: data['pickupDateTime'] != null
          ? (data['pickupDateTime'] as Timestamp).toDate()
          : DateTime.now(),
      returnDateTime: data['returnDateTime'] != null
          ? (data['returnDateTime'] as Timestamp).toDate()
          : null,
      passengerCapacity: data['passengerCapacity'] ?? 1,
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      assignedAt: data['assignedAt'] != null
          ? (data['assignedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      driverId: data['driverId'],
      driverName: data['driverName'],
      vehicleId: data['vehicleId'],
      vehicleName: data['vehicleName'],
      completionNote: data['completionNote'],
      driverRating: data['driverRating'] != null
          ? (data['driverRating'] is int
              ? (data['driverRating'] as int).toDouble()
              : data['driverRating'] as double)
          : null,
      driverReview: data['driverReview'],
      vehicleRating: data['vehicleRating'] != null
          ? (data['vehicleRating'] is int
              ? (data['vehicleRating'] as int).toDouble()
              : data['vehicleRating'] as double)
          : null,
      vehicleReview: data['vehicleReview'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'pickupDateTime': Timestamp.fromDate(pickupDateTime),
      'returnDateTime':
          returnDateTime != null ? Timestamp.fromDate(returnDateTime!) : null,
      'passengerCapacity': passengerCapacity,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'completionNote': completionNote,
      'driverRating': driverRating,
      'driverReview': driverReview,
      'vehicleRating': vehicleRating,
      'vehicleReview': vehicleReview,
    };
  }

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

  IconData getStatusIcon() {
    switch (status) {
      case 'open':
        return Icons.pending;
      case 'inProgress':
        return Icons.directions_car;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String getStatusDisplayName() {
    switch (status) {
      case 'open':
        return 'Open';
      case 'inProgress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  // Helper methods for ratings
  bool hasDriverRating() {
    return driverRating != null;
  }

  bool hasDriverReview() {
    return driverReview != null && driverReview!.isNotEmpty;
  }

  bool hasVehicleRating() {
    return vehicleRating != null;
  }

  bool hasVehicleReview() {
    return vehicleReview != null && vehicleReview!.isNotEmpty;
  }

  bool canBeRated() {
    return status == 'completed' && driverId != null && vehicleId != null;
  }

  bool isFullyRated() {
    return hasDriverRating() && hasVehicleRating();
  }
}
