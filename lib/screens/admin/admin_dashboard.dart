import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Ganti path ini sesuai dengan struktur proyek Anda
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../auth/register_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // State untuk filter berdasarkan peran
  String _selectedFilter = 'All';
  List<String> _filterOptions = [
    'All',
    'Employee',
    'Officer',
    'Technician',
    'Admin'
  ];

  // State baru untuk fungsionalitas pencarian
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Listener untuk memperbarui state query pencarian saat teks berubah
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    // Hapus controller untuk membebaskan sumber daya
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    // Tampilkan dialog konfirmasi
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirm Logout'),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: Icon(Icons.logout),
            label: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmLogout != true) return;

    print('🚪 Admin initiating logout...');

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }

      print('✅ Admin logout completed successfully');
    } catch (e) {
      print('❌ Error during admin logout: $e');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );

        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Logout completed with warnings'),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    }
  }

  void _createNewUser() async {
    print('📝 Navigating to create new user...');

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );

    if (result == true && mounted) {
      print('🔄 Refreshing admin dashboard after user creation');
      setState(() {});

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
    }
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

  void _showEditUserDialog(
      BuildContext context, Map<String, dynamic> userData, String userId) {
    final TextEditingController nameController =
        TextEditingController(text: userData['name']);
    final TextEditingController emailController =
        TextEditingController(text: userData['email']);
    String selectedRole = userData['role'] ?? Constants.ROLE_EMPLOYEE;
    bool isDriver = false;
    bool isDriverNameOrEmail =
        _isDriverUser(userData['name'] ?? '', userData['email'] ?? '');

    _checkIfUserIsDriver(userId).then((result) {
      if (result) {
        setState(() {
          isDriver = true;
        });
      }
    });

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text('Edit User'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  enabled: false,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
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
                    setState(() {
                      selectedRole = value!;
                      if (value != Constants.ROLE_TECHNICIAN) {
                        isDriver = false;
                      }
                    });
                  },
                ),
                if (selectedRole == Constants.ROLE_TECHNICIAN) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDriver ? Colors.green[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDriver ? Colors.green[300]! : Colors.blue[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.drive_eta,
                              color: isDriver
                                  ? Colors.green[700]
                                  : Colors.blue[700],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Driver Capabilities',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDriver
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
                            color:
                                isDriver ? Colors.green[800] : Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        SwitchListTile(
                          title: Text(
                            'Enable Driver Role',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDriver
                                  ? Colors.green[700]
                                  : Colors.blue[700],
                            ),
                          ),
                          value: isDriver,
                          onChanged: (value) {
                            setState(() {
                              isDriver = value;
                            });
                          },
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
                if (isDriverNameOrEmail &&
                    selectedRole == Constants.ROLE_TECHNICIAN)
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
                            'This user has "driver" in name/email which will automatically enable driver capabilities',
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
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.cancel, size: 18),
              label: Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    'name': nameController.text.trim(),
                    'role': selectedRole,
                  });

                  bool shouldBeDriver =
                      selectedRole == Constants.ROLE_TECHNICIAN &&
                          (isDriver ||
                              _isDriverUser(nameController.text.trim(),
                                  userData['email'] ?? ''));

                  bool isCurrentlyDriver = await _checkIfUserIsDriver(userId);

                  if (shouldBeDriver && !isCurrentlyDriver) {
                    await FirebaseFirestore.instance
                        .collection('drivers')
                        .doc(userId)
                        .set({
                      'createdAt': Timestamp.now(),
                      'currentVehicleId': null,
                      'currentVehicleName': null,
                      'email': userData['email'] ?? '',
                      'isAvailable': true,
                      'name': nameController.text.trim(),
                      'status': 'active',
                      'uid': userId,
                      'updatedAt': Timestamp.now(),
                    });
                  } else if (isCurrentlyDriver && !shouldBeDriver) {
                    await FirebaseFirestore.instance
                        .collection('drivers')
                        .doc(userId)
                        .update({
                      'isAvailable': false,
                      'status': 'inactive',
                      'updatedAt': Timestamp.now(),
                    });
                  } else if (isCurrentlyDriver && shouldBeDriver) {
                    await FirebaseFirestore.instance
                        .collection('drivers')
                        .doc(userId)
                        .update({
                      'name': nameController.text.trim(),
                      'updatedAt': Timestamp.now(),
                    });
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('User updated successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating user: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: Icon(Icons.save),
              label: Text('Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context,
      Map<String, dynamic> userData, String userId, bool isDriver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User'),
          ],
        ),
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
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.cancel, size: 18),
            label: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final userService =
                    Provider.of<UserService>(context, listen: false);
                await userService.deleteUser(userId);

                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(isDriver
                        ? 'User and driver profile deleted successfully'
                        : 'User deleted successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting user: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: Icon(Icons.delete_forever),
            label: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return FutureBuilder<Map<String, dynamic>?>(
                future: authService.getCurrentUserData(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          'Hi, ${snapshot.data!['name'] ?? 'Admin'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'view_drivers':
                  _viewAllDrivers();
                  break;
                case 'refresh':
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dashboard refreshed'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 1),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
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
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Refresh Dashboard'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _signOut,
            tooltip: 'Logout',
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
          // WIDGET BARU: Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            // Add any additional search clearing logic here
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 1.5),
                  ),
                ),
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
              ),
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

                // LOGIKA DIPERBARUI: Menggabungkan filter dan pencarian
                final filteredUsers = allUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = (data['role'] as String? ?? '').toLowerCase();
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  final lowerCaseQuery = _searchQuery.toLowerCase();

                  // Logika filter peran
                  final roleMatches = _selectedFilter == 'All' ||
                      role == _selectedFilter.toLowerCase();

                  // Logika filter pencarian
                  final searchMatches = _searchQuery.isEmpty ||
                      name.contains(lowerCaseQuery) ||
                      email.contains(lowerCaseQuery);

                  return roleMatches && searchMatches;
                }).toList();

                // BARU: Tampilkan pesan jika tidak ada pengguna yang cocok
                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No Users Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

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
}
