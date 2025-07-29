import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
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

  bool _isDriverUser(String name, String email) {
    String nameLower = name.toLowerCase();
    String emailLower = email.toLowerCase();
    return nameLower.contains('driver') || emailLower.contains('driver');
  }

  Future<bool> _checkIfUserIsDriver(String uid) async {
    try {
      DocumentSnapshot driverDoc =
          await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
      return driverDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> _runDriverMigration() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.backup, color: Colors.blue),
            SizedBox(width: 5),
            Expanded(
              child: Text(
                'Migrate Existing Drivers',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create driver documents for existing technicians with "driver" in their name/email.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'What this will do:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Scan all technicians in the system'),
                  Text('• Find those with "driver" in name/email'),
                  Text('• Create driver documents for them'),
                  Text('• Skip if driver document already exists'),
                  Text('• Show detailed results when complete'),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is safe to run multiple times. Existing data will not be affected.',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: Icon(Icons.play_arrow),
            label: Text('Run Migration'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Running Driver Migration...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we scan and create driver documents',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few moments...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      Map<String, dynamic> result = await userService.migrateExistingDrivers();

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.error,
                color: result['success'] ? Colors.green : Colors.red,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Migration ${result['success'] ? 'Completed!' : 'Failed'}',
                  style: TextStyle(
                    color:
                        result['success'] ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result['success']) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Migration Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildSummaryRow('✅ Successfully created',
                              '${result['successCount']} drivers'),
                          _buildSummaryRow('⏭️ Skipped (already exist)',
                              '${result['skipCount']} drivers'),
                          _buildSummaryRow(
                              '❌ Errors', '${result['errorCount']} drivers'),
                          _buildSummaryRow('📈 Total processed',
                              '${result['totalProcessed']} technicians'),
                        ],
                      ),
                    ),
                    if (result['migrated'].isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        '🎉 New drivers created:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: result['migrated']
                              .map<Widget>((name) => Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.drive_eta,
                                            color: Colors.blue[700], size: 16),
                                        SizedBox(width: 8),
                                        Expanded(child: Text(name)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    if (result['errors'].isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        '⚠️ Errors encountered:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: result['errors']
                              .map<Widget>((error) => Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '• $error',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red[700]),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Migration failed with error:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            result['error'] ?? 'Unknown error',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (result['success'] && (result['successCount'] ?? 0) > 0)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _viewAllDrivers();
                },
                icon: Icon(Icons.list),
                label: Text('View All Drivers'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _runDriverMigration(),
          ),
        ),
      );
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewAllDrivers() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.drive_eta, color: Colors.blue),
            SizedBox(width: 8),
            Text('All Drivers'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: Provider.of<UserService>(context, listen: false)
                .getAllDrivers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              List<Map<String, dynamic>> drivers = snapshot.data ?? [];

              if (drivers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_accounts, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No drivers found'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  var driver = drivers[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (driver['isAvailable'] ?? false)
                            ? Colors.green
                            : Colors.orange,
                        child: Icon(
                          Icons.drive_eta,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(driver['name'] ?? 'Unknown'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver['email'] ?? 'No email'),
                          Text(
                            'Status: ${driver['status'] ?? 'Unknown'} • ${(driver['isAvailable'] ?? false) ? 'Available' : 'Busy'}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: driver['currentVehicleName'] != null
                          ? Chip(
                              label: Text(
                                driver['currentVehicleName'],
                                style: TextStyle(fontSize: 10),
                              ),
                              backgroundColor: Colors.blue[100],
                            )
                          : Text(
                              'No vehicle',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'migrate_drivers':
                  _runDriverMigration();
                  break;
                case 'view_drivers':
                  _viewAllDrivers();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'migrate_drivers',
                child: Row(
                  children: [
                    Icon(Icons.backup, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Migrate Existing Drivers'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'view_drivers',
                child: Row(
                  children: [
                    Icon(Icons.drive_eta, color: Colors.green),
                    SizedBox(width: 12),
                    Text('View All Drivers'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
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

                var allUsers = snapshot.data!.docs;
                var filteredUsers = allUsers.where((doc) {
                  if (_selectedFilter == 'All') return true;
                  var role = doc['role'] as String? ?? '';
                  return role.toLowerCase() == _selectedFilter.toLowerCase();
                }).toList();

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var userData =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    var userId = filteredUsers[index].id;

                    return FutureBuilder<bool>(
                      future: _checkIfUserIsDriver(userId),
                      builder: (context, driverSnapshot) {
                        bool isDriver = driverSnapshot.data ?? false;

                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      _getRoleColor(userData['role']),
                                  child: Icon(
                                    _getRoleIcon(userData['role']),
                                    color: Colors.white,
                                  ),
                                ),
                                if (isDriver)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 1),
                                      ),
                                      child: Icon(
                                        Icons.drive_eta,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    userData['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isDriver)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(6),
                                      border:
                                          Border.all(color: Colors.green[300]!),
                                    ),
                                    child: Text(
                                      'DRIVER',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  userData['email'] ?? 'No email',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    Text(
                                      'Role: ${_capitalizeFirstLetter(userData['role'] ?? 'Unknown')}',
                                      style: TextStyle(
                                        color: _getRoleColor(userData['role']),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isDriver) ...[
                                      Text(
                                        '• Driver enabled',
                                        style: TextStyle(
                                          color: Colors.green[600],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showEditUserDialog(
                                        context, userData, userId);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _showDeleteConfirmDialog(
                                        context, userData, userId, isDriver);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Create New User',
      ),
    );
  }

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

  String _capitalizeFirstLetter(String? text) {
    if (text == null || text.isEmpty) return 'Unknown';
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
                enabled: false,
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
              if (_isDriverUser(
                  userData['name'] ?? '', userData['email'] ?? ''))
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
                      Icon(Icons.info, color: Colors.blue[700], size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This user has driver privileges due to name/email containing "driver"',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
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
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'name': nameController.text.trim(),
                  'role': selectedRole,
                });

                if (_isDriverUser(
                    nameController.text.trim(), userData['email'] ?? '')) {
                  DocumentSnapshot driverDoc = await FirebaseFirestore.instance
                      .collection('drivers')
                      .doc(userId)
                      .get();

                  if (driverDoc.exists) {
                    await FirebaseFirestore.instance
                        .collection('drivers')
                        .doc(userId)
                        .update({
                      'name': nameController.text.trim(),
                      'updatedAt': Timestamp.now(),
                    });
                  }
                }

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

  void _showDeleteConfirmDialog(BuildContext context,
      Map<String, dynamic> userData, String userId, bool isDriver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${userData['name']}?'),
            SizedBox(height: 12),
            if (isDriver)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This user is also a driver. Driver profile will be deleted too.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final userService =
                    Provider.of<UserService>(context, listen: false);
                await userService.deleteUser(userId);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isDriver
                        ? 'User and driver profile deleted successfully'
                        : 'User deleted successfully'),
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
