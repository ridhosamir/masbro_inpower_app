import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isAvailable;

  DriverModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isAvailable = true,
  });

  // Copy with method for creating a modified version of the object
  DriverModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isAvailable,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  // Convert model to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAvailable': isAvailable,
    };
  }

  // Create a model from a Firestore document
  factory DriverModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverModel(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }
}
