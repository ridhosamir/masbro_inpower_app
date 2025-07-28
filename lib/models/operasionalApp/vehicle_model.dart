import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String vehicleType;
  final String vehicleModel;
  final String licensePlate;
  final String color;
  final DateTime createdAt;
  final bool isAvailable;

  VehicleModel({
    required this.id,
    required this.vehicleType,
    required this.vehicleModel,
    required this.licensePlate,
    required this.color,
    required this.createdAt,
    this.isAvailable = true,
  });

  // Copy with method for creating a modified version of the object
  VehicleModel copyWith({
    String? id,
    String? vehicleType,
    String? vehicleModel,
    String? licensePlate,
    String? color,
    DateTime? createdAt,
    bool? isAvailable,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  // Convert model to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'licensePlate': licensePlate,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAvailable': isAvailable,
    };
  }

  // Create a model from a Firestore document
  factory VehicleModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      vehicleType: data['vehicleType'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      color: data['color'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  // Get display name for UI
  String get displayName {
    return '$vehicleType $vehicleModel - $licensePlate';
  }
}
