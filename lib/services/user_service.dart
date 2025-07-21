// File: services/user_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data from Firestore
  Future<UserModel> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user data: $e');
      throw e;
    }
  }

  // Get all technicians
  Future<List<UserModel>> getTechnicians() async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting technicians: $e');
      return [];
    }
  }

  // Get users by role (for admin)
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  // Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Create a new user document in Firestore
  Future<void> createUserDocument(
      String uid, String name, String email, String role) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error creating user document: $e');
      throw e;
    }
  }

  // Update user data (for admin)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user: $e');
      throw e;
    }
  }

  // Delete user (for admin)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print('Error deleting user: $e');
      throw e;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin';
      }
      return false;
    } catch (e) {
      print('Error checking if user is admin: $e');
      return false;
    }
  }

  // Get user counts by role (for admin dashboard)
  Future<Map<String, int>> getUserCountsByRole() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();

      Map<String, int> roleCounts = {
        'admin': 0,
        'officer': 0,
        'technician': 0,
        'employee': 0,
        'total': 0,
      };

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'unknown';

        if (roleCounts.containsKey(role)) {
          roleCounts[role] = (roleCounts[role] ?? 0) + 1;
        }

        roleCounts['total'] = (roleCounts['total'] ?? 0) + 1;
      }

      return roleCounts;
    } catch (e) {
      print('Error getting user counts: $e');
      return {
        'admin': 0,
        'officer': 0,
        'technician': 0,
        'employee': 0,
        'total': 0,
      };
    }
  }
}
