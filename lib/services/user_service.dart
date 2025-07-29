// File: services/user_service.dart - FULL CODE WITH MIGRATION

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Delete user (for admin) - UPDATED to handle driver documents
  Future<void> deleteUser(String uid) async {
    try {
      // Cek apakah user juga ada di collection drivers
      DocumentSnapshot driverDoc =
          await _firestore.collection('drivers').doc(uid).get();
      bool hasDriverDocument = driverDoc.exists;

      // Hapus dokumen dari users collection
      await _firestore.collection('users').doc(uid).delete();

      // Jika user juga driver, hapus dari collection drivers
      if (hasDriverDocument) {
        await _firestore.collection('drivers').doc(uid).delete();
        print('Driver document also deleted for: $uid');
      }

      print('User document deleted from Firestore: $uid');
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

  // Helper function untuk mengecek apakah user adalah driver
  bool _isDriverUser(String name, String email) {
    String nameLower = name.toLowerCase();
    String emailLower = email.toLowerCase();
    return nameLower.contains('driver') || emailLower.contains('driver');
  }

  // NEW: Get all available drivers (technicians with driver documents)
  Future<List<UserModel>> getAvailableDrivers() async {
    try {
      // Get available drivers from drivers collection
      QuerySnapshot driverQuery = await _firestore
          .collection('drivers')
          .where('isAvailable', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      List<UserModel> availableDrivers = [];

      // For each available driver, get the corresponding user data
      for (var driverDoc in driverQuery.docs) {
        try {
          UserModel userData = await getUserData(driverDoc.id);
          availableDrivers.add(userData);
        } catch (e) {
          print('Error fetching user data for driver ${driverDoc.id}: $e');
        }
      }

      return availableDrivers;
    } catch (e) {
      print('Error getting available drivers: $e');
      return [];
    }
  }

  // NEW: Update driver availability
  Future<void> updateDriverAvailability(String uid, bool isAvailable) async {
    try {
      await _firestore.collection('drivers').doc(uid).update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.now(),
      });
      print('Driver availability updated for: $uid, available: $isAvailable');
    } catch (e) {
      print('Error updating driver availability: $e');
      throw e;
    }
  }

  // NEW: Assign vehicle to driver
  Future<void> assignVehicleToDriver(
      String driverUid, String? vehicleId, String? vehicleName) async {
    try {
      await _firestore.collection('drivers').doc(driverUid).update({
        'currentVehicleId': vehicleId,
        'currentVehicleName': vehicleName,
        'updatedAt': Timestamp.now(),
      });
      print('Vehicle assigned to driver: $driverUid, vehicle: $vehicleName');
    } catch (e) {
      print('Error assigning vehicle to driver: $e');
      throw e;
    }
  }

  // NEW: Get driver info by UID
  Future<Map<String, dynamic>?> getDriverInfo(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('drivers').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting driver info: $e');
      return null;
    }
  }

  // MIGRATION: Create driver documents for existing technicians with "driver" in name/email
  Future<Map<String, dynamic>> migrateExistingDrivers() async {
    int successCount = 0;
    int skipCount = 0;
    List<String> errors = [];
    List<String> migrated = [];

    try {
      print('🚀 Starting driver migration...');

      // Get all technicians
      QuerySnapshot techniciansQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .get();

      print('📊 Found ${techniciansQuery.docs.length} technicians to check');

      for (var userDoc in techniciansQuery.docs) {
        try {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String uid = userDoc.id;
          String name = userData['name'] ?? '';
          String email = userData['email'] ?? '';

          print('🔍 Checking technician: $name ($email)');

          // Check if name or email contains "driver"
          if (_isDriverUser(name, email)) {
            print('🎯 Found potential driver: $name');

            // Check if driver document already exists
            DocumentSnapshot existingDriver =
                await _firestore.collection('drivers').doc(uid).get();

            if (!existingDriver.exists) {
              // Create driver document
              await _firestore.collection('drivers').doc(uid).set({
                'createdAt': Timestamp.now(),
                'currentVehicleId': null,
                'currentVehicleName': null,
                'email': email,
                'isAvailable': true,
                'name': name,
                'status': 'active',
                'uid': uid,
                'updatedAt': Timestamp.now(),
              });

              successCount++;
              migrated.add('$name ($email)');
              print('✅ Driver document created for existing user: $name');
            } else {
              skipCount++;
              print('⏭️ Driver document already exists for: $name');
            }
          } else {
            print('❌ Not a driver (no "driver" in name/email): $name');
          }
        } catch (e) {
          String errorMsg = 'Error processing user ${userDoc.id}: $e';
          errors.add(errorMsg);
          print('❌ $errorMsg');
        }
      }

      print('🎉 Migration completed!');
      print('✅ Success: $successCount');
      print('⏭️ Skipped: $skipCount');
      print('❌ Errors: ${errors.length}');

      return {
        'success': true,
        'successCount': successCount,
        'skipCount': skipCount,
        'errorCount': errors.length,
        'errors': errors,
        'migrated': migrated,
        'totalProcessed': techniciansQuery.docs.length,
        'message': 'Migration completed successfully!'
      };
    } catch (e) {
      String errorMsg = 'Migration failed: $e';
      print('💥 $errorMsg');
      return {
        'success': false,
        'error': errorMsg,
        'successCount': successCount,
        'skipCount': skipCount,
        'errorCount': errors.length,
        'migrated': migrated,
      };
    }
  }

  // NEW: Get all drivers (for debugging)
  Future<List<Map<String, dynamic>>> getAllDrivers() async {
    try {
      QuerySnapshot driversQuery = await _firestore.collection('drivers').get();
      return driversQuery.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all drivers: $e');
      return [];
    }
  }

  // NEW: Manually create driver document for specific user
  Future<String?> createDriverDocumentForUser(String uid) async {
    try {
      // Get user data
      UserModel userData = await getUserData(uid);

      // Check if user is technician
      if (userData.role != 'technician') {
        return 'User must be a technician to become a driver';
      }

      // Check if driver document already exists
      DocumentSnapshot existingDriver =
          await _firestore.collection('drivers').doc(uid).get();

      if (existingDriver.exists) {
        return 'Driver document already exists for this user';
      }

      // Create driver document
      await _firestore.collection('drivers').doc(uid).set({
        'createdAt': Timestamp.now(),
        'currentVehicleId': null,
        'currentVehicleName': null,
        'email': userData.email,
        'isAvailable': true,
        'name': userData.name,
        'status': 'active',
        'uid': uid,
        'updatedAt': Timestamp.now(),
      });

      print('✅ Driver document manually created for: ${userData.name}');
      return null; // Success
    } catch (e) {
      String errorMsg = 'Error creating driver document: $e';
      print('❌ $errorMsg');
      return errorMsg;
    }
  }

  // NEW: Remove driver document for specific user
  Future<String?> removeDriverDocumentForUser(String uid) async {
    try {
      // Check if driver document exists
      DocumentSnapshot driverDoc =
          await _firestore.collection('drivers').doc(uid).get();

      if (!driverDoc.exists) {
        return 'Driver document does not exist for this user';
      }

      // Delete driver document
      await _firestore.collection('drivers').doc(uid).delete();

      print('✅ Driver document removed for: $uid');
      return null; // Success
    } catch (e) {
      String errorMsg = 'Error removing driver document: $e';
      print('❌ $errorMsg');
      return errorMsg;
    }
  }
}
