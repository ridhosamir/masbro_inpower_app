import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  // Sign up with email and password
  Future<String?> signUp(
      String email, String password, String name, String role) async {
    try {
      _isLoading = true;
      notifyListeners();

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

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(userData.toMap());

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create user as admin (without signing in as the new user)
  Future<String?> createUserAsAdmin(
      String email, String password, String name, String role) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if current user is admin before allowing this operation
      DocumentSnapshot adminCheck = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      if (!adminCheck.exists ||
          (adminCheck.data() as Map<String, dynamic>)['role'] != 'admin') {
        _isLoading = false;
        notifyListeners();
        return 'Only admins can create new users';
      }

      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store the UID of the new user
      String newUserUid = result.user!.uid;

      // Save the admin user to re-authenticate later
      User? adminUser = _auth.currentUser;

      // Create user document in Firestore
      UserModel userData = UserModel(
        uid: newUserUid,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(newUserUid)
          .set(userData.toMap());

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Password reset
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

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    if (_auth.currentUser == null) return false;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

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
}
