import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RideRequestModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String pickupLocation;
  final DateTime pickupDateTime;
  final String dropoffLocation;
  final DateTime? returnDateTime;
  final int passengerCapacity;
  final String description;
  final String status; // 'open', 'inProgress', 'completed'
  final DateTime createdAt;
  final String? driverId;
  final String? driverName;
  final String? vehicleId;
  final String? vehicleName;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final String? completionNote;

  RideRequestModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.pickupLocation,
    required this.pickupDateTime,
    required this.dropoffLocation,
    this.returnDateTime,
    required this.passengerCapacity,
    required this.description,
    required this.status,
    required this.createdAt,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleName,
    this.assignedAt,
    this.completedAt,
    this.completionNote,
  });

  // Copy with method for creating a modified version of the object
  RideRequestModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? pickupLocation,
    DateTime? pickupDateTime,
    String? dropoffLocation,
    DateTime? returnDateTime,
    int? passengerCapacity,
    String? description,
    String? status,
    DateTime? createdAt,
    String? driverId,
    String? driverName,
    String? vehicleId,
    String? vehicleName,
    DateTime? assignedAt,
    DateTime? completedAt,
    String? completionNote,
  }) {
    return RideRequestModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupDateTime: pickupDateTime ?? this.pickupDateTime,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      returnDateTime: returnDateTime ?? this.returnDateTime,
      passengerCapacity: passengerCapacity ?? this.passengerCapacity,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      completionNote: completionNote ?? this.completionNote,
    );
  }

  // Convert model to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'pickupLocation': pickupLocation,
      'pickupDateTime': Timestamp.fromDate(pickupDateTime),
      'dropoffLocation': dropoffLocation,
      'returnDateTime': returnDateTime != null
          ? Timestamp.fromDate(returnDateTime!)
          : null,
      'passengerCapacity': passengerCapacity,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'completionNote': completionNote,
    };
  }

  // Create a model from a Firestore document
  factory RideRequestModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideRequestModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      pickupLocation: data['pickupLocation'] ?? '',
      pickupDateTime: (data['pickupDateTime'] as Timestamp).toDate(),
      dropoffLocation: data['dropoffLocation'] ?? '',
      returnDateTime: data['returnDateTime'] != null
          ? (data['returnDateTime'] as Timestamp).toDate()
          : null,
      passengerCapacity: data['passengerCapacity'] ?? 1,
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      driverId: data['driverId'],
      driverName: data['driverName'],
      vehicleId: data['vehicleId'],
      vehicleName: data['vehicleName'],
      assignedAt: data['assignedAt'] != null
          ? (data['assignedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      completionNote: data['completionNote'],
    );
  }

  // Helper method to get status color for UI
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

  // Helper method to get status icon for UI
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

  // Helper method to get status display name for UI
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
}


