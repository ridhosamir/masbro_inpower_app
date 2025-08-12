import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:masbro_inpower_app/services/auth_service.dart';
import 'package:masbro_inpower_app/screens/auth/login_screen.dart';
import 'package:masbro_inpower_app/screens/admin/admin_dashboard.dart';
import 'package:masbro_inpower_app/widgets/custom_button.dart';
import 'package:masbro_inpower_app/widgets/custom_text_field.dart';
import 'package:masbro_inpower_app/utils/constants.dart';
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
  bool _isDriver = false; // Flag untuk driver option

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    print('🚀 RegisterScreen initialized');
  }

  Future<void> _checkAdminStatus() async {
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    print('🚀 Starting registration process...');
    print(
        '📝 User details: $name ($email) - Role: $_selectedRole, Driver: $_isDriver');

    try {
      String? error;

      if (_isAdmin) {
        print('👨‍💼 Admin creating new user');

        // Simpan informasi admin sebelum membuat user baru
        final currentUser = authService.user;
        print('👨‍💼 Current admin before creation: ${currentUser?.email}');

        error = await authService.createUserAsAdmin(
          email,
          password,
          name,
          _selectedRole,
          isDriver: _isDriver,
        );

        // Verifikasi admin masih login setelah pembuatan user
        final adminAfterCreation = authService.user;
        print('👨‍💼 Admin after creation: ${adminAfterCreation?.email}');

        if (error == null) {
          print('✅ Admin user creation successful');
          _showSuccessAndReturn();
          return;
        }
      } else {
        print('👤 Normal user registration');
        error = await authService.signUp(
          email,
          password,
          name,
          _selectedRole,
          isDriver: _isDriver,
        );

        if (error == null) {
          print('✅ Normal registration successful');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
          return;
        }
      }

      print('❌ Registration failed: $error');
      _showErrorSnackBar(error ?? 'Unknown error occurred');
    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Auth Error: ${e.message}');
      _showErrorSnackBar('Authentication Error: ${e.message}');
    } catch (e) {
      print('💥 Unexpected Error: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showSuccessAndReturn() {
    print('✅ User created successfully, returning to admin dashboard');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('User created successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // PERBAIKAN: Gunakan Navigator.pop() instead of pushReplacement
      // untuk kembali ke AdminDashboard yang sudah ada
      Navigator.pop(context, true); // Pass true untuk indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdminCreatingAccount = _isAdmin;

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
                        // Back Button and Title
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
                          prefixIcon: Icons.person,
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
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}'
                )
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
                          prefixIcon: Icons.lock,
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
                          prefixIcon: Icons.lock_outline,
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
                        SizedBox(height: 16),

                        // Driver Option (visible only for Technician role)
                        if (_selectedRole == Constants.ROLE_TECHNICIAN)
                          Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isDriver
                                  ? Colors.green[50]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isDriver
                                    ? Colors.green[300]!
                                    : Colors.blue[200]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.drive_eta,
                                      color: _isDriver
                                          ? Colors.green[700]
                                          : Colors.blue[700],
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Driver Capabilities',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isDriver
                                            ? Colors.green[700]
                                            : Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Enable this technician to drive vehicles and fulfill transportation requests',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _isDriver
                                        ? Colors.green[800]
                                        : Colors.blue[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                SwitchListTile(
                                  title: Text(
                                    'Enable Driver Role',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _isDriver
                                          ? Colors.green[700]
                                          : Colors.blue[700],
                                    ),
                                  ),
                                  value: _isDriver,
                                  onChanged: (value) {
                                    setState(() {
                                      _isDriver = value;
                                    });
                                    print('🚗 Driver flag changed to: $_isDriver');
                                  },
                                  activeColor: Colors.green,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                                if (_isDriver)
                                  Container(
                                    margin: EdgeInsets.only(top: 8),
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green[700],
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This technician will be available in the driver assignment system',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

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
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            ),
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Debug: Admin mode active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_selectedRole == Constants.ROLE_TECHNICIAN)
                                  Text(
                                    'Driver enabled: $_isDriver',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _isDriver ? Colors.green : Colors.grey[600],
                                    ),
                                  ),
                              ],
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
          // Reset driver flag when changing roles
          if (_selectedRole != Constants.ROLE_TECHNICIAN) {
            _isDriver = false;
          }
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