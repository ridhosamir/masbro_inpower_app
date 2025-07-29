import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final int capacity;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.createdAt,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return RoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RoomModel copyWith({
    String? id,
    String? name,
    int? capacity,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
