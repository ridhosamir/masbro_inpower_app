// File: screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../auth/register_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedFilter = 'All';
  List<String> _filterOptions = [
    'All',
    'Employee',
    'Officer',
    'Technician',
    'Admin'
  ];

  Future<void> _signOut() async {
    await Provider.of<AuthService>(context, listen: false).signOut();
  }

  void _createNewUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          // Admin stats and quick actions
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Control Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildQuickStatCard(
                      context,
                      Icons.person,
                      'Manage Users',
                      'Create or edit user accounts',
                      onTap: () {
                        setState(() {
                          _selectedFilter = 'All';
                        });
                      },
                    ),
                    SizedBox(width: 12),
                    _buildQuickStatCard(
                      context,
                      Icons.add_circle,
                      'Create Account',
                      'Add a new user',
                      onTap: _createNewUser,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter options
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Filter by Role: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: _filterOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedFilter = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found'));
                }

                // Filter users based on selected role
                var allUsers = snapshot.data!.docs;
                var filteredUsers = allUsers.where((doc) {
                  if (_selectedFilter == 'All') return true;
                  var role = doc['role'] as String;
                  return role.toLowerCase() == _selectedFilter.toLowerCase();
                }).toList();

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var userData =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    var userId = filteredUsers[index].id;

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(userData['role']),
                          child: Icon(
                            _getRoleIcon(userData['role']),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          userData['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(userData['email'] ?? 'No email'),
                            SizedBox(height: 2),
                            Text(
                              'Role: ${_capitalizeFirstLetter(userData['role'] ?? 'Unknown')}',
                              style: TextStyle(
                                color: _getRoleColor(userData['role']),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // Edit user functionality
                                _showEditUserDialog(context, userData, userId);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Delete user functionality
                                _showDeleteConfirmDialog(
                                    context, userData, userId);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewUser,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add),
        tooltip: 'Create New User',
      ),
    );
  }

  // Helper methods
  Widget _buildQuickStatCard(
      BuildContext context, IconData icon, String title, String subtitle,
      {required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'officer':
        return Colors.blue;
      case 'technician':
        return Colors.orange;
      case 'employee':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'officer':
        return Icons.supervisor_account;
      case 'technician':
        return Icons.engineering;
      case 'employee':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showEditUserDialog(
      BuildContext context, Map<String, dynamic> userData, String userId) {
    final TextEditingController nameController =
        TextEditingController(text: userData['name']);
    final TextEditingController emailController =
        TextEditingController(text: userData['email']);
    String selectedRole = userData['role'] ?? Constants.ROLE_EMPLOYEE;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                enabled: false, // Email cannot be changed
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: Constants.ROLE_EMPLOYEE,
                    child: Text('Employee'),
                  ),
                  DropdownMenuItem(
                    value: Constants.ROLE_OFFICER,
                    child: Text('Officer'),
                  ),
                  DropdownMenuItem(
                    value: Constants.ROLE_TECHNICIAN,
                    child: Text('Technician'),
                  ),
                  DropdownMenuItem(
                    value: Constants.ROLE_ADMIN,
                    child: Text('Admin'),
                  ),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Update user in Firestore
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'name': nameController.text.trim(),
                  'role': selectedRole,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating user: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, Map<String, dynamic> userData, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${userData['name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Delete user from Firestore
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting user: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
