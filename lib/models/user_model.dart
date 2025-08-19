import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final double? averageRating;
  final int? totalRatings;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.averageRating,
    this.totalRatings,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle date conversion
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.parse(data['createdAt'] as String);
    } else {
      createdAt = DateTime.now(); // Fallback
    }

    // Handle rating conversion
    double? averageRating;
    if (data['averageRating'] != null) {
      averageRating = data['averageRating'] is int
          ? (data['averageRating'] as int).toDouble()
          : data['averageRating'] as double;
    }

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'employee',
      createdAt: createdAt,
      averageRating: averageRating,
      totalRatings: data['totalRatings'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    };
  }

  // Untuk membuat salinan objek dengan nilai yang diperbarui
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    double? averageRating,
    int? totalRatings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
    );
  }
}
