import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  User? get user => _auth.currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      print(
          '🔄 Auth state changed: ${user?.email ?? 'null'} (UID: ${user?.uid ?? 'null'})');
      notifyListeners();
    });
  }

  bool _isDriverUser(String name, String email) {
    String nameLower = name.toLowerCase();
    String emailLower = email.toLowerCase();
    return nameLower.contains('driver') || emailLower.contains('driver');
  }

  Future<void> _createDriverDocumentViaCloudFunction(
      String uid, String name, String email) async {
    try {
      print('🚀 Creating driver document via Cloud Function for: $name ($uid)');

      final callable = _functions.httpsCallable('createDriverDocument');
      final result = await callable.call<Map<String, dynamic>>(
          {'uid': uid, 'name': name, 'email': email});

      if (result.data['success'] == true) {
        if (result.data['created'] == true) {
          print(
              '✅ Driver document created via Cloud Function for: $name ($uid)');
        } else {
          print(
              '✅ Driver document updated via Cloud Function for: $name ($uid)');
        }
      } else {
        print('❌ Cloud Function failed: ${result.data['message']}');
      }
    } catch (e) {
      print('❌ Error calling Cloud Function: $e');
    }
  }

  Future<String?> signUp(
      String email, String password, String name, String role,
      {bool isDriver = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      print(
          '🚀 Creating user account: $name ($email), role: $role, driver: $isDriver');

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel userData = UserModel(
        uid: result.user!.uid,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );

      final Map<String, dynamic> userMap = userData.toMap();
      if (role == 'technician' && isDriver) {
        userMap['isDriver'] = true;
      }

      await _firestore.collection('users').doc(result.user!.uid).set(userMap);

      if (role == 'technician' && (isDriver || _isDriverUser(name, email))) {
        print('🚗 Creating driver document for new user: $name');
        try {
          await _createDriverDocumentViaCloudFunction(
              result.user!.uid, name, email);
        } catch (driverError) {
          print('⚠️ Warning: Failed to create driver document: $driverError');
        }
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      print('❌ Registration error: $e');
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // PERBAIKAN: Fungsi signIn yang tidak mengubah state _isLoading
  Future<String?> signIn(String email, String password) async {
    try {
      // Baris _isLoading dan notifyListeners() dihapus dari sini
      print('🚪 Attempting to sign in user: $email');

      if (_auth.currentUser != null) {
        print('⚠️ User already signed in, signing out first...');
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
          '✅ Sign in successful for: ${result.user?.email} (UID: ${result.user?.uid})');

      // Baris _isLoading dan notifyListeners() dihapus dari sini
      return null;
    } catch (e) {
      print('❌ Sign in error: $e');
      // Baris _isLoading dan notifyListeners() dihapus dari sini

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            return 'No user found with this email address.';
          case 'wrong-password':
            return 'Incorrect password.';
          case 'invalid-email':
            return 'Invalid email address.';
          case 'user-disabled':
            return 'This account has been disabled.';
          case 'too-many-requests':
            return 'Too many failed attempts. Please try again later.';
          default:
            return 'Login failed: ${e.message}';
        }
      }
      return e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      print('🚪 Starting sign out process...');

      final currentUser = _auth.currentUser;
      print('📝 Current user before logout: ${currentUser?.email ?? 'null'}');

      _isLoading = true;
      notifyListeners();

      await _auth.signOut();
      await Future.delayed(const Duration(milliseconds: 500));

      final userAfterLogout = _auth.currentUser;
      if (userAfterLogout == null) {
        print('✅ Sign out successful - no current user');
      } else {
        print(
            '⚠️ Sign out might not be complete - user still exists: ${userAfterLogout.email}');
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      _isLoading = false;
      notifyListeners();

      print('✅ Sign out process completed');
    } catch (e) {
      print('❌ Error during sign out: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> createUserAsAdmin(
      String email, String password, String name, String role,
      {bool isDriver = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      print(
          '🚀 Admin creating user: $name ($email), role: $role, driver: $isDriver');

      if (_auth.currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return 'No authenticated admin found';
      }

      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        _isLoading = false;
        notifyListeners();
        return 'Only admins can create new users';
      }

      final currentAdminUid = _auth.currentUser!.uid;
      final currentAdminEmail = _auth.currentUser!.email;
      print('👨‍💼 Current admin: $currentAdminEmail ($currentAdminUid)');

      try {
        print('☁️ Attempting to create user via Cloud Function...');
        final callable = _functions.httpsCallable('createUserByAdmin');
        final result = await callable.call<Map<String, dynamic>>({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'isDriver':
              role == 'technician' && (isDriver || _isDriverUser(name, email)),
        });

        if (result.data['success'] == true) {
          print('✅ User created successfully via Cloud Function');
          _isLoading = false;
          notifyListeners();
          return null;
        } else {
          print('❌ Cloud Function failed: ${result.data['error']}');
          _isLoading = false;
          notifyListeners();
          return result.data['error'] ??
              'Failed to create user via Cloud Function';
        }
      } catch (cloudFunctionError) {
        print('⚠️ Cloud Function failed: $cloudFunctionError');

        return await _createUserManuallyAsAdmin(
          email,
          password,
          name,
          role,
          isDriver: isDriver,
          adminUid: currentAdminUid,
          adminEmail: currentAdminEmail,
        );
      }
    } catch (e) {
      print('❌ Admin create user error: $e');
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> _createUserManuallyAsAdmin(
    String email,
    String password,
    String name,
    String role, {
    required bool isDriver,
    required String adminUid,
    required String? adminEmail,
  }) async {
    try {
      print('🔧 Falling back to manual user creation...');

      final adminUser = _auth.currentUser;
      if (adminUser == null || adminUser.uid != adminUid) {
        return 'Admin authentication lost';
      }

      print('👤 Creating new user account...');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String newUserUid = result.user!.uid;
      print('✅ New user created with UID: $newUserUid');

      UserModel userData = UserModel(
        uid: newUserUid,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );

      final Map<String, dynamic> userMap = userData.toMap();
      if (role == 'technician' && isDriver) {
        userMap['isDriver'] = true;
      }

      await _firestore.collection('users').doc(newUserUid).set(userMap);
      print('✅ User document created in Firestore');

      if (role == 'technician' && (isDriver || _isDriverUser(name, email))) {
        print('🚗 Creating driver document...');
        try {
          await _createDriverDocumentViaCloudFunction(newUserUid, name, email);
        } catch (driverError) {
          print('⚠️ Warning: Failed to create driver document: $driverError');
        }
      }

      print('🔄 Logging out new user and restoring admin session...');
      await _auth.signOut();
      await Future.delayed(const Duration(milliseconds: 500));

      print('⚠️ Admin needs to login again after manual user creation');

      _isLoading = false;
      notifyListeners();

      return 'User created successfully, but admin needs to login again due to authentication changes';
    } catch (e) {
      print('❌ Manual user creation error: $e');
      _isLoading = false;
      notifyListeners();
      return 'Failed to create user: ${e.toString()}';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    if (_auth.currentUser == null) {
      print('🔍 No current user - not admin');
      return false;
    }

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool isAdmin = data['role'] == 'admin';
        print(
            '🔍 Is current user admin? $isAdmin (${_auth.currentUser!.email})');
        return isAdmin;
      }
      print('🔍 User document not found - not admin');
      return false;
    } catch (e) {
      print('❌ Error checking if user is admin: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_auth.currentUser == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user data: $e');
      return null;
    }
  }

  void debugAuthState() {
    final user = _auth.currentUser;
    print('🔍 DEBUG AUTH STATE:');
    print('  - Current user: ${user?.email ?? 'null'}');
    print('  - UID: ${user?.uid ?? 'null'}');
    print('  - Is loading: $_isLoading');
  }
}
