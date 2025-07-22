import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String buildingId;
  final String buildingName;
  final String name;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.buildingId,
    required this.buildingName,
    required this.name,
    required this.createdAt,
  });

  /// Create RoomModel from Firestore document
  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return RoomModel(
      id: doc.id,
      buildingId: data['buildingId'] ?? '',
      buildingName: data['buildingName'] ?? '',
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert RoomModel to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'buildingName': buildingName,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy of RoomModel with some fields changed
  RoomModel copyWith({
    String? id,
    String? buildingId,
    String? buildingName,
    String? name,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      buildingName: buildingName ?? this.buildingName,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get the full room name (building + room name)
  String getFullName() {
    return '$buildingName - $name';
  }
}
