// File: screens/auth/register_screen.dart - FULL CODE COMPLETE

import 'package:flutter/material.dart';
import 'package:masbro_inpower_app/screens/auth/login_screen.dart';
import 'package:masbro_inpower_app/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = Constants.ROLE_EMPLOYEE;
  bool _isLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
    print('🚀 RegisterScreen initialized');
  }

  Future<void> _checkIfAdmin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user != null) {
      try {
        final isAdmin = await authService.isCurrentUserAdmin();
        setState(() {
          _isAdmin = isAdmin;
        });
        print('🔍 Admin check result: $isAdmin');
      } catch (e) {
        print('❌ Error checking admin status: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    print('🧹 RegisterScreen disposed');
    super.dispose();
  }

  // Fungsi untuk mengecek apakah user adalah driver
  bool _isDriverUser(String name, String email) {
    String nameLower = name.toLowerCase();
    String emailLower = email.toLowerCase();
    bool isDriver =
        nameLower.contains('driver') || emailLower.contains('driver');
    print('🚗 Driver check for "$name" / "$email": $isDriver');
    return isDriver;
  }

  // Fungsi untuk membuat dokumen driver (backup jika AuthService gagal)
  Future<void> _createDriverDocument(
      String uid, String name, String email) async {
    try {
      print('🚗 Creating backup driver document for: $name');
      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
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
      print('✅ Backup driver document created successfully for: $name');
    } catch (e) {
      print('❌ Error creating backup driver document: $e');
      throw e;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    String? error;
    String? newUserUid;
    bool driverDocumentCreated = false;

    try {
      print('🚀 Starting registration process...');
      print(
          '📝 User details: ${_nameController.text.trim()} (${_emailController.text.trim()}) - Role: $_selectedRole');

      if (authService.user != null && _isAdmin) {
        print('👨‍💼 Admin creating new user');
        // Admin is creating a new user
        error = await authService.createUserAsAdmin(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _selectedRole,
        );

        // Jika berhasil dan tidak ada error, ambil UID user yang baru dibuat
        if (error == null) {
          print('✅ Admin user creation successful, finding new user UID...');
          // Cari user yang baru dibuat berdasarkan email
          QuerySnapshot userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: _emailController.text.trim())
              .get();

          if (userQuery.docs.isNotEmpty) {
            newUserUid = userQuery.docs.first.id;
            print('✅ Found new user UID: $newUserUid');
          } else {
            print('❌ Could not find newly created user in Firestore');
          }
        }
      } else {
        print('👤 Normal user registration');
        // Normal registration
        error = await authService.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _selectedRole,
        );

        // Jika berhasil, ambil UID dari current user
        if (error == null && authService.user != null) {
          newUserUid = authService.user!.uid;
          print('✅ Normal registration successful, UID: $newUserUid');
        }
      }

      // Verifikasi apakah driver document sudah dibuat oleh AuthService
      if (error == null &&
          newUserUid != null &&
          _selectedRole == Constants.ROLE_TECHNICIAN &&
          _isDriverUser(
              _nameController.text.trim(), _emailController.text.trim())) {
        print('🔍 Checking if driver document already exists...');

        // Cek apakah driver document sudah ada
        DocumentSnapshot driverCheck = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(newUserUid)
            .get();

        if (driverCheck.exists) {
          print('✅ Driver document already exists (created by AuthService)');
          driverDocumentCreated = true;
        } else {
          print('⚠️ Driver document not found, creating backup...');
          try {
            await _createDriverDocument(newUserUid, _nameController.text.trim(),
                _emailController.text.trim());
            driverDocumentCreated = true;
            print(
                '✅ Backup driver document created for technician: ${_nameController.text.trim()}');
          } catch (driverError) {
            print(
                '❌ Warning: Failed to create backup driver document: $driverError');
            // Tidak menggagalkan registrasi jika pembuatan driver document gagal
          }
        }
      }
    } catch (e) {
      error = 'Terjadi kesalahan: $e';
      print('💥 Registration process error: $e');
    }

    setState(() => _isLoading = false);

    if (error != null) {
      print('❌ Registration failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      String successMessage = 'Account created successfully!';

      // Tambahkan pesan khusus jika driver document juga dibuat
      if (_selectedRole == Constants.ROLE_TECHNICIAN &&
          _isDriverUser(
              _nameController.text.trim(), _emailController.text.trim()) &&
          driverDocumentCreated) {
        successMessage += '\n🚗 Driver profile also created automatically.';
      }

      print('✅ Registration completed successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    bool isAdminCreatingAccount = authService.user != null && _isAdmin;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back Button
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.arrow_back),
                              color: Theme.of(context).primaryColor,
                            ),
                            Expanded(
                              child: Text(
                                isAdminCreatingAccount
                                    ? 'Create New User'
                                    : 'Create Account',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 48), // Balance the back button
                          ],
                        ),
                        SizedBox(height: 24),

                        // Name Field
                        CustomTextField(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Email Field
                        CustomTextField(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Password Field
                        CustomTextField(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          controller: _passwordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Confirm Password Field
                        CustomTextField(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Role Selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Role',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  _buildRoleOption(
                                    Constants.ROLE_EMPLOYEE,
                                    'Employee',
                                    'Report maintenance issues',
                                    Icons.person,
                                  ),
                                  Divider(height: 1),
                                  _buildRoleOption(
                                    Constants.ROLE_OFFICER,
                                    'Officer',
                                    'Approve reports and assign tasks',
                                    Icons.supervisor_account,
                                  ),
                                  Divider(height: 1),
                                  _buildRoleOption(
                                    Constants.ROLE_TECHNICIAN,
                                    'Technician',
                                    'Complete maintenance tasks',
                                    Icons.engineering,
                                  ),

                                  // Only show admin option if current user is admin
                                  if (_isAdmin)
                                    Column(
                                      children: [
                                        Divider(height: 1),
                                        _buildRoleOption(
                                          Constants.ROLE_ADMIN,
                                          'Admin',
                                          'Manage all users and system settings',
                                          Icons.admin_panel_settings,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Info Box untuk Driver
                        if (_selectedRole == Constants.ROLE_TECHNICIAN &&
                            _isDriverUser(
                                _nameController.text, _emailController.text))
                          Container(
                            margin: EdgeInsets.only(top: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.drive_eta,
                                    color: Colors.blue[700], size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Driver Profile Detected',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Technician with name/email containing "driver" will automatically get driver privileges for vehicle assignment.',
                                        style: TextStyle(
                                          color: Colors.blue[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 24),

                        // Register Button
                        CustomButton(
                          text: isAdminCreatingAccount
                              ? 'Create User'
                              : 'Create Account',
                          onPressed: _register,
                          isLoading: _isLoading,
                        ),
                        SizedBox(height: 16),

                        // Login Link - only show for non-admin users
                        if (!isAdminCreatingAccount)
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(color: Colors.grey[600]),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Debug info (only in debug mode)
                        if (isAdminCreatingAccount)
                          Container(
                            margin: EdgeInsets.only(top: 16),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Debug: Admin mode active',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(
      String value, String title, String subtitle, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedRole,
      onChanged: (value) {
        setState(() {
          _selectedRole = value!;
        });
        print('🎯 Role selected: $_selectedRole');
      },
      title: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      activeColor: Theme.of(context).primaryColor,
    );
  }
}
