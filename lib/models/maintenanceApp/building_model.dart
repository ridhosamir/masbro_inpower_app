import 'package:cloud_firestore/cloud_firestore.dart';

class BuildingModel {
  final String id;
  final String name;
  final DateTime createdAt;

  BuildingModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// Create BuildingModel from Firestore document
  factory BuildingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return BuildingModel(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert BuildingModel to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy of BuildingModel with some fields changed
  BuildingModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return BuildingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
