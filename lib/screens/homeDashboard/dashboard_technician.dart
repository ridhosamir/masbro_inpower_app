import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/models/maintenanceApp/task_model.dart'
    as maintenance_task;
import 'package:masbro_inpower_app/models/operasionalApp/ride_request_model.dart'
    as operasional_task;
import 'package:masbro_inpower_app/models/resourceApp/task_model.dart'
    as resource_task;
import 'package:masbro_inpower_app/models/user_model.dart';
import 'package:masbro_inpower_app/screens/technician/maintenanceApp/technician_dashboard.dart';
import 'package:masbro_inpower_app/screens/technician/operasionalApp/driver_dashboard.dart';
import 'package:masbro_inpower_app/screens/technician/resourceApp/technician_dashboard.dart';
import 'package:masbro_inpower_app/services/auth_service.dart';
import 'package:masbro_inpower_app/services/maintenanceApp/firestore_service.dart'
    as maintenance_service;
import 'package:masbro_inpower_app/services/operasionalApp/firestore_service.dart'
    as operasional_service;
import 'package:masbro_inpower_app/services/resourceApp/firestore_service.dart'
    as resource_service;
import 'package:masbro_inpower_app/services/user_service.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import 'package:provider/provider.dart';
import '../../../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class HomeDashboardTechnician extends StatefulWidget {
  const HomeDashboardTechnician({super.key});

  @override
  State<HomeDashboardTechnician> createState() =>
      _HomeDashboardTechnicianState();
}

class _HomeDashboardTechnicianState extends State<HomeDashboardTechnician>
    with SingleTickerProviderStateMixin {
  UserModel? currentUser;
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (authService.user != null) {
      final userData = await userService.getUserData(authService.user!.uid);
      if (mounted) {
        setState(() {
          currentUser = userData;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      backgroundColor: const Color.fromARGB(255, 4, 117, 217),
                      expandedHeight: 325.0,
                      floating: false,
                      pinned: true,
                      automaticallyImplyLeading: false,
                      title: LayoutBuilder(
                        builder: (context, constraints) {
                          final settings =
                              context.dependOnInheritedWidgetOfExactType<
                                  FlexibleSpaceBarSettings>()!;
                          final delta = settings.maxExtent - settings.minExtent;
                          final opacity = (1.0 -
                                  (settings.currentExtent -
                                          settings.minExtent) /
                                      delta)
                              .clamp(0.0, 1.0);

                          return Opacity(
                            opacity: opacity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Technician Dashboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: _buildProfileMenu(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      centerTitle: false,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildHeader(context),
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 3.0,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.7),
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 16),
                        tabs: const [
                          Tab(text: 'My Task'),
                          Tab(text: 'Application'),
                        ],
                      ),
                    )
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    TechnicianStatusTab(currentUser: currentUser!),
                    _buildAppGrid(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4A90E2),
            Color.fromARGB(255, 4, 117, 217),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.9],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
                ]),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -80,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  Colors.white.withOpacity(0.03),
                ]),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final settings = context.dependOnInheritedWidgetOfExactType<
                      FlexibleSpaceBarSettings>()!;
                  final delta = settings.maxExtent - settings.minExtent;
                  final opacity =
                      ((settings.currentExtent - settings.minExtent) / delta)
                          .clamp(0.0, 1.0);

                  return Opacity(
                    opacity: opacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Technician Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: _buildProfileMenu(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.waving_hand,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentUser!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Technician since ${DateFormat('dd MMM yyyy').format(currentUser!.createdAt)}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.25),
        child: const Icon(Icons.person, color: Colors.white),
      ),
      onSelected: (value) {
        if (value == 'profile') {
          _showProfileDialog();
        } else if (value == 'logout') {
          _showLogoutDialog();
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('My Profile'),
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildAppGrid(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6F8),
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildAppCard(
            context: context,
            title: 'Maintenance',
            icon: Icons.construction,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TechnicianDashboard()),
              );
            },
          ),
          _buildAppCard(
            context: context,
            title: 'Resource/Item',
            icon: Icons.groups,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TechnicianDashboardResource()),
              );
            },
          ),
          _buildAppCard(
            context: context,
            title: 'Operational',
            icon: Icons.directions_car,
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DriverDashboard()),
              );
            },
          ),
          _buildAppCard(
            context: context,
            title: 'Booking Room',
            icon: Icons.meeting_room,
            color: Colors.teal,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'This application is not available for Technicians.'),
                  backgroundColor: Colors.blueGrey,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog() {
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Profil Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('Name', currentUser!.name),
            _buildProfileItem('Email', currentUser!.email),
            _buildProfileItem('Role', currentUser!.role.toUpperCase()),
            _buildProfileItem(
              'Technician since',
              DateFormat('dd MMMM yyyy').format(currentUser!.createdAt),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout Confirmation'),
        content:
            const Text('Are you sure you want to log out of this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthService>(context, listen: false).signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 18),
          if (icon != null) const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

// --- ADDED WIDGET: A basic implementation for CustomTextField was needed. ---
class CustomTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}

class TechnicianStatusTab extends StatefulWidget {
  final UserModel currentUser;
  const TechnicianStatusTab({super.key, required this.currentUser});

  @override
  State<TechnicianStatusTab> createState() => _TechnicianStatusTabState();
}

class _TechnicianStatusTabState extends State<TechnicianStatusTab>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final TextEditingController _searchController = TextEditingController();
  final _completionMaintncNoteController = TextEditingController();
  final _completionResourceNoteController = TextEditingController();
  final _completionRideNoteController = TextEditingController();

  // --- CORRECTION: Firestore services instantiated for use in methods. ---
  final _maintenanceFirestoreService = maintenance_service.FirestoreService();
  final _resourceFirestoreService = resource_service.FirestoreServiceResource();
  final _operasionalFirestoreService =
      operasional_service.OperasionalFirestoreService();

  String _searchQuery = '';
  List<dynamic> _combinedList = [];
  List<dynamic> _filteredList = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  bool _isSearching = false;
  final StorageService _storageService = StorageService();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 2, vsync: this);
    _fetchData();
    _searchController.addListener(_onSearchChanged);
    _statusTabController.addListener(_filterData); // Re-filter on tab change
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    _searchController.dispose();
    _completionMaintncNoteController.dispose();
    _completionResourceNoteController.dispose();
    _completionRideNoteController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _isSearching = _searchQuery.isNotEmpty;
      _filterData();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
      _filterData();
    });
  }

  void _clearTimeFilter() {
    setState(() {
      _selectedFilter = 'all';
      _filterData();
    });
  }

  Future<void> _pickImage(
      ImageSource source, StateSetter setStateDialog) async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setStateDialog(() {
            _selectedImage = pickedFile;
            _selectedImageBytes = bytes;
          });
        } else {
          setStateDialog(() {
            _selectedImage = pickedFile;
          });
        }
      }
    } catch (e) {
      print('Failed to select image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final String technicianId = widget.currentUser.uid;

    final maintenanceFuture =
        _maintenanceFirestoreService.getTasksByTechnician(technicianId).first;
    final resourceFuture =
        _resourceFirestoreService.getTasksByTechnician(technicianId).first;
    final operationalFuture = _operasionalFirestoreService
        .getRideRequestsByDriver(technicianId)
        .first;

    final results = await Future.wait([
      maintenanceFuture,
      resourceFuture,
      operationalFuture,
    ]);

    final maintenanceTasks = results[0] as List<maintenance_task.TaskModel>;
    final resourceTasks = results[1] as List<resource_task.TaskModel>;
    // --- CORRECTION: Using the correct aliased type RideRequestModel. ---
    final operationalRequests =
        results[2] as List<operasional_task.RideRequestModel>;

    setState(() {
      // --- CORRECTION: Fetch all tasks, not just active ones, to populate both tabs. ---
      _combinedList = [
        ...maintenanceTasks,
        ...resourceTasks,
        ...operationalRequests,
      ];
      _combinedList.sort((a, b) {
        // --- CORRECTION: Use the correct aliased type for the check. ---
        DateTime dateA = a is operasional_task.RideRequestModel
            ? a.assignedAt!
            : (a as dynamic).assignedAt;
        DateTime dateB = b is operasional_task.RideRequestModel
            ? b.assignedAt!
            : (b as dynamic).assignedAt;
        return dateB.compareTo(dateA); // Sort descending by date
      });
      _filterData();
      _isLoading = false;
    });
  }

  // --- CORRECTION: Rewritten filter logic to correctly handle tabs and search. ---
  void _filterData() {
    List<dynamic> tempFiltered = _combinedList;
    final now = DateTime.now();

    final isProgressTab = _statusTabController.index == 0;
    if (isProgressTab) {
      tempFiltered = tempFiltered
          .where((item) =>
              item.status == 'inProgress' || item.status == 'in_progress')
          .toList();
    } else {
      tempFiltered =
          tempFiltered.where((item) => item.status == 'completed').toList();
    }

    if (_searchQuery.isNotEmpty) {
      tempFiltered = tempFiltered.where((item) {
        if (item is maintenance_task.TaskModel) {
          return item.roomName.toLowerCase().contains(_searchQuery) ||
              item.itemName.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery);
        } else if (item is resource_task.TaskModel) {
          return item.description.toLowerCase().contains(_searchQuery) ||
              (item.timeRequired?.toLowerCase().contains(_searchQuery) ??
                  false);
        } else if (item is operasional_task.RideRequestModel) {
          return item.pickupLocation.toLowerCase().contains(_searchQuery) ||
              item.dropoffLocation.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
        }
        return false;
      }).toList();
    }

    if (_selectedFilter != 'all') {
      tempFiltered = tempFiltered.where((item) {
        // Menentukan tanggal yang relevan berdasarkan status
        DateTime? relevantDate;
        if (item.status == 'completed' && item.completedAt != null) {
          relevantDate = item.completedAt;
        } else if ((item.status == 'inProgress' ||
                item.status == 'in_progress') &&
            item.assignedAt != null) {
          relevantDate = item.assignedAt;
        }

        if (relevantDate == null) return false;

        switch (_selectedFilter) {
          case 'today':
            return relevantDate.year == now.year &&
                relevantDate.month == now.month &&
                relevantDate.day == now.day;
          case 'week':
            return now.difference(relevantDate).inDays < 7 &&
                relevantDate.isBefore(now);
          case 'month':
            return relevantDate.year == now.year &&
                relevantDate.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    setState(() {
      _filteredList = tempFiltered;
      _currentPage = 1;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter By Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All Time'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Today'),
              value: 'today',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('This Week'),
              value: 'week',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('This Month'),
              value: 'month',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _loadMore() {
    setState(() {
      _currentPage++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginatedList =
        _filteredList.take(_currentPage * _itemsPerPage).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildStatisticsCards(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSearchAndFilterBar(),
                ),
                TabBar(
                  controller: _statusTabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'In Progress'),
                    Tab(text: 'Done'),
                  ],
                ),
              ],
            ),
          ),
          if (_isSearching)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.blue.withOpacity(0.1),
              child: Text(
                '${_filteredList.length} results for "${_searchController.text}"',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (paginatedList.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: _buildEmptyState(),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- CORRECTION: Corrected type checking for dispatching to the right card builder. ---
                  ...paginatedList.map((item) {
                    if (item is maintenance_task.TaskModel) {
                      return _buildMaintenanceTaskCard(item);
                    } else if (item is resource_task.TaskModel) {
                      return _buildResourceTaskCard(item);
                    } else if (item is operasional_task.RideRequestModel) {
                      return _buildRideRequestCard(item);
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                  if (_filteredList.length > paginatedList.length)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: _loadMore,
                          icon: const Icon(Icons.expand_more),
                          label: const Text('See More'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final inProgressCount = _combinedList
        .where((item) =>
            item.status == 'inProgress' || item.status == 'in_progress')
        .length;
    final completedCount =
        _combinedList.where((item) => item.status == 'completed').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'In Progress',
              count: inProgressCount,
              icon: Icons.sync_outlined,
              color: Colors.purple.shade800,
              backgroundColor: Colors.purple.shade50,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Done',
              count: completedCount,
              icon: Icons.check_circle_outline,
              color: Colors.green.shade800,
              backgroundColor: Colors.green.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Task...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).primaryColor,
            ),
            tooltip: 'Filter By Time',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final bool isSearchActive = _searchQuery.isNotEmpty;
    final bool isTimeFilterActive = _selectedFilter != 'all';

    IconData icon = Icons.inbox_outlined;
    String title = 'Nothing Found';
    String description = 'There are no tasks with this status at this time.';
    Widget? actionButton;

    // 1. Cek apakah ada pencarian aktif
    if (isSearchActive) {
      icon = Icons.search_off;
      title = 'Search Not Found';
      description = 'No data matches the keyword "${_searchController.text}".';
      actionButton = TextButton.icon(
        onPressed: _clearSearch,
        icon: const Icon(Icons.clear, color: Colors.red),
        label: const Text('Clear Search', style: TextStyle(color: Colors.red)),
      );
    }
    // 2. Jika tidak, cek apakah ada filter waktu aktif
    else if (isTimeFilterActive) {
      icon = Icons.filter_alt_off_outlined;
      title = 'Data Not Found';
      description = 'There is no data in the selected time range.';
      actionButton = TextButton.icon(
        onPressed: _clearTimeFilter,
        icon: const Icon(Icons.clear, color: Colors.red),
        label: const Text(
          'Clear Filter',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (actionButton != null) actionButton,
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        text = 'IN PROGRESS';
        color = Colors.blue;
        break;
      case 'completed':
        text = 'COMPLETED';
        color = Colors.green;
        break;
      default:
        text = status.toUpperCase();
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  void _showTaskDetailMaintenance(maintenance_task.TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with status
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Task Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),
            ),

            Divider(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task info card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem('Room', task.roomName, Icons.room),
                          if (task.itemName.isNotEmpty)
                            _buildDetailItem(
                                'Item', task.itemName, Icons.build),
                          _buildDetailItem(
                            'Assigned',
                            DateFormat('dd MMM yyyy, HH:mm')
                                .format(task.assignedAt),
                            Icons.calendar_today,
                          ),
                          if (task.status == 'completed' &&
                              task.completedAt != null)
                            _buildDetailItem(
                              'Completed',
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(task.completedAt!),
                              Icons.check_circle,
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Image if available
                    if (task.imageUrl != null) ...[
                      Text(
                        'Issue Photo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () =>
                            _showFullScreenImage(context, task.imageUrl!),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  task.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Description section
                    Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        task.description,
                        style: TextStyle(
                          height: 1.5,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),

                    // Completion Notes
                    if (task.status == 'completed' &&
                        task.completionNote != null) ...[
                      SizedBox(height: 20),
                      Text(
                        'Completion Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          task.completionNote!,
                          style: TextStyle(
                            height: 1.5,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Action button
            if (task.status == 'inProgress' || task.status == 'in_progress')
              Padding(
                padding: EdgeInsets.all(16),
                child: CustomButton(
                  text: 'Mark as Completed',
                  onPressed: () {
                    Navigator.pop(context);
                    _showCompleteDialogMaintenance(task);
                  },
                  backgroundColor: Colors.green,
                ),
              ),

            if (task.status == 'completed')
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.keyboard_return),
                  label: Text('Back to Tasks'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetailResource(resource_task.TaskModel task) {
    final bool isResourceRequest = task.request == 'resource';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Task Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(
                            'Need',
                            '${task.request[0].toUpperCase()}${task.request.substring(1)}',
                            task.request == 'resource'
                                ? Icons.supervisor_account
                                : Icons.inventory,
                          ),
                          _buildDetailItem(
                              'Requester', task.requesterName, Icons.person),
                          if (task.timeRequired != null &&
                              task.timeRequired!.isNotEmpty)
                            _buildDetailItem('Time Required',
                                task.timeRequired!, Icons.calendar_today),
                          _buildDetailItem(
                            'Assigned',
                            DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                                .format(task.assignedAt),
                            Icons.access_time,
                          ),
                          if (task.status == 'completed' &&
                              task.completedAt != null)
                            _buildDetailItem(
                              'Finished',
                              DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID')
                                  .format(task.completedAt!),
                              Icons.check_circle,
                            ),
                        ],
                      ),
                    ),
                    // Tampilkan foto jika ini adalah permintaan item
                    if (!isResourceRequest && task.hasValidImage()) ...[
                      const SizedBox(height: 24),
                      const Text('Item Photo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          // Panggil fungsi untuk menampilkan gambar fullscreen
                          _showFullScreenImage(
                              context, task.getNormalizedImageUrl()!);
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FirebaseStorageImage(
                                  imageUrl: task.getNormalizedImageUrl(),
                                  fit: BoxFit.cover,
                                  placeholder: Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey[400]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.zoom_in,
                                  color: Colors.white, size: 32),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Task Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        task.description,
                        style: TextStyle(
                          height: 1.5,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    if (task.status == 'completed' &&
                        task.completionNote != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Your Completion Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          task.completionNote!,
                          style: TextStyle(
                            height: 1.5,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (task.status == 'inProgress' || task.status == 'in_progress')
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  text: 'Mark Complete',
                  onPressed: () {
                    _showCompleteDialogResource(task);
                  },
                  backgroundColor: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- CORRECTION: Using correct aliased type RideRequestModel. ---
  void _showRequestDetailRide(operasional_task.RideRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with status
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ride Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(request.status),
                ],
              ),
            ),

            Divider(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ride info card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem('From', request.pickupLocation,
                              Icons.location_on),
                          _buildDetailItem(
                              'To', request.dropoffLocation, Icons.location_on),
                          _buildDetailItem(
                            'Pickup',
                            DateFormat('dd MMM yyyy, HH:mm')
                                .format(request.pickupDateTime),
                            Icons.event,
                          ),
                          if (request.returnDateTime != null)
                            _buildDetailItem(
                              'Return',
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(request.returnDateTime!),
                              Icons.event_available,
                            ),
                          _buildDetailItem(
                            'Passengers',
                            request.passengerCapacity.toString(),
                            Icons.group,
                          ),
                          _buildDetailItem(
                            'Requester',
                            request.employeeName,
                            Icons.person,
                          ),
                          if (request.vehicleName != null)
                            _buildDetailItem(
                              'Vehicle',
                              request.vehicleName!,
                              Icons.directions_car,
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Description section
                    Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        request.description,
                        style: TextStyle(
                          height: 1.5,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),

                    // Completion Notes
                    if (request.status == 'completed' &&
                        request.completionNote != null) ...[
                      SizedBox(height: 20),
                      Text(
                        'Completion Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          request.completionNote!,
                          style: TextStyle(
                            height: 1.5,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Action button
            if (request.status == 'inProgress' ||
                request.status == 'in_progress')
              Padding(
                padding: EdgeInsets.all(16),
                child: CustomButton(
                  text: 'Mark as Completed',
                  onPressed: () {
                    Navigator.pop(context);
                    _showCompleteDialogRide(request);
                  },
                  backgroundColor: Colors.green,
                ),
              ),

            if (request.status == 'completed')
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.keyboard_return),
                  label: Text('Back to Rides'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialogMaintenance(maintenance_task.TaskModel task) {
    _completionMaintncNoteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark Task as Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide completion notes:'),
            SizedBox(height: 16),
            CustomTextField(
              labelText: 'Completion Notes',
              hintText: 'Enter notes about the completed work...',
              controller: _completionMaintncNoteController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _completionMaintncNoteController.clear();
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _completeTaskMaintnc(task),
            child: _isLoading
                ? Container(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  )
                : Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTaskMaintnc(maintenance_task.TaskModel task) async {
    if (_completionMaintncNoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide completion notes'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Navigator.pop(context); // Close dialog first

    try {
      await _maintenanceFirestoreService.updateTaskStatus(
        task.id,
        'completed',
        completionNote: _completionMaintncNoteController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing task: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fetchData(); // Refresh the list
      }
    }
  }

  void _showCompleteDialogResource(resource_task.TaskModel task) {
    _completionResourceNoteController.clear();
    _selectedImage = null;
    _selectedImageBytes = null;
    String? dialogErrorText;

    showDialog(
      context: context,
      builder: (context) {
        XFile? localSelectedImage;
        Uint8List? localSelectedImageBytes;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Complete the Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      labelText: 'Completion Notes',
                      hintText: 'Enter task notes...',
                      controller: _completionResourceNoteController,
                      maxLines: 3,
                    ),
                    if (task.request == 'item') ...[
                      const SizedBox(height: 16),
                      Text('Item Photo (Optional)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? (_selectedImageBytes != null
                                  ? Image.memory(_selectedImageBytes!,
                                      fit: BoxFit.cover)
                                  : Center(
                                      child: Icon(
                                          Icons.photo_camera_back_outlined,
                                          color: Colors.grey[400],
                                          size: 40)))
                              : (_selectedImage != null
                                  ? Image.file(File(_selectedImage!.path),
                                      fit: BoxFit.cover)
                                  : Center(
                                      child: Icon(
                                          Icons.photo_camera_back_outlined,
                                          color: Colors.grey[400],
                                          size: 40))),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            onPressed: () =>
                                _pickImage(ImageSource.gallery, setStateDialog),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            onPressed: () =>
                                _pickImage(ImageSource.camera, setStateDialog),
                          ),
                        ],
                      ),
                    ],
                    if (dialogErrorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dialogErrorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (_completionResourceNoteController.text.trim().isEmpty) {
                      setStateDialog(() {
                        dialogErrorText = 'Please provide completion notes';
                      });
                    } else {
                      _completeTaskResource(task);
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Complete',
                          style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _completeTaskResource(resource_task.TaskModel task) async {
    Navigator.pop(context);
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    String? imageUrl;
    try {
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadImage(
            _selectedImage!, 'completed_items');
        if (imageUrl == null) {
          throw Exception('Failed to upload image.');
        }
      }
      await _resourceFirestoreService.updateTaskStatus(
        task.id,
        'completed',
        completionNote: _completionResourceNoteController.text.trim(),
        afterImageUrl: imageUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task successfully completed!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedImage = null;
          _selectedImageBytes = null;
        });
      }
    }
  }

  void _showCompleteDialogRide(operasional_task.RideRequestModel task) {
    _completionRideNoteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark Ride as Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide completion notes:'),
            SizedBox(height: 16),
            CustomTextField(
              labelText: 'Completion Notes',
              hintText: 'Enter notes about the completed ride...',
              controller: _completionRideNoteController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _completionRideNoteController.clear();
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          // --- CORRECTION: Fixed typo, it should call _completeRequestRide(task) ---
          TextButton(
            onPressed: () => _completeRequestRide(task),
            child: _isLoading
                ? Container(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  )
                : Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // --- CORRECTION: Fixed function signature and variable names (task vs request) ---
  Future<void> _completeRequestRide(
      operasional_task.RideRequestModel task) async {
    if (_completionRideNoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide completion notes'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Navigator.pop(context); // Close dialog first

    try {
      await _operasionalFirestoreService.completeRideRequest(
        task.id,
        _completionRideNoteController.text.trim(),
        driverId: task.driverId,
        vehicleId: task.vehicleId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing ride: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fetchData(); // Refresh the list
      }
    }
  }

  // --- KARTU TUGAS UNTUK TEKNISI ---

  Widget _buildMaintenanceTaskCard(maintenance_task.TaskModel task) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shadowColor: Colors.orange.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTaskDetailMaintenance(task),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.construction,
                                color: Colors.orange[700], size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Report Maintenance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                if (task.itemName.isNotEmpty)
                                  Text(
                                    'Item: ${task.itemName}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(task.status),
                  ],
                ),
                const SizedBox(height: 12),
                if (task.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      task.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.description,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[700], height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- FIX: Menambahkan null-check untuk waktu ---
                    if (task.status == 'completed' && task.completedAt != null)
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green[700])
                    else if (task.assignedAt != null)
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),

                    const SizedBox(width: 8),

                    if (task.status == 'completed' && task.completedAt != null)
                      Text(
                        'Completed: ${_getTimeAgo(task.completedAt!)}',
                        style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      )
                    else if (task.assignedAt != null)
                      Text(
                        'Assigned: ${_getTimeAgo(task.assignedAt!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),

                    const Spacer(),
                  ],
                ),
                if (task.status == 'inProgress' ||
                    task.status == 'in_progress') ...[
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Mark Complete',
                    onPressed: () => _showCompleteDialogMaintenance(task),
                    backgroundColor: Colors.green,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CORRECTION: Using correct aliased type RideRequestModel. ---
  Widget _buildRideRequestCard(operasional_task.RideRequestModel request) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shadowColor: Colors.red.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showRequestDetailRide(request),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.directions_car,
                                color: Colors.red[700], size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup: ${request.pickupLocation}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Drop off: ${request.dropoffLocation}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(request.status),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.event, 'Pickup: ',
                    DateFormat('MMM dd, HH:mm').format(request.pickupDateTime)),
                _buildInfoRow(Icons.group, 'Passenger: ',
                    request.passengerCapacity.toString()),
                _buildInfoRow(
                    Icons.person, 'Applicant: ', request.employeeName),
                const SizedBox(height: 12),
                if (request.status == 'inProgress' ||
                    request.status == 'in_progress') ...[
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Mark Complete',
                    onPressed: () => _showCompleteDialogRide(request),
                    backgroundColor: Colors.green,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceTaskCard(resource_task.TaskModel task) {
    final bool isResourceRequest = task.request == 'resource';
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.cyan.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTaskDetailResource(task),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.cyan.withOpacity(0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isResourceRequest ? Icons.groups : Icons.inventory,
                        color: Colors.cyan[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request Resource/Item',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Text(
                            'By: ${task.requesterName ?? "N/A"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(task.status),
                  ],
                ),
                if (!isResourceRequest && task.hasValidImage()) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FirebaseStorageImage(
                        imageUrl: task.getNormalizedImageUrl(),
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: Colors.grey[200],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.description ?? 'There is no description.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                if (task.request != null)
                  _buildInfoRow(
                    isResourceRequest
                        ? Icons.supervisor_account
                        : Icons.inventory,
                    'Need',
                    '${task.request![0].toUpperCase()}${task.request!.substring(1)}',
                  ),
                if (task.timeRequired != null && task.timeRequired!.isNotEmpty)
                  _buildInfoRow(
                      Icons.calendar_today, 'Time', task.timeRequired!),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- FIX: Menambahkan null-check untuk waktu ---
                    if (task.status == 'completed' && task.completedAt != null)
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green[700])
                    else if (task.assignedAt != null)
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),

                    const SizedBox(width: 8),

                    if (task.status == 'completed' && task.completedAt != null)
                      Text(
                        'Completed at: ${_getTimeAgo(task.completedAt!)}',
                        style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      )
                    else if (task.assignedAt != null)
                      Text(
                        'Assigned at: ${_getTimeAgo(task.assignedAt!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),

                    const Spacer(),
                  ],
                ),
                if (task.status == 'inProgress' ||
                    task.status == 'in_progress') ...[
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Mark Complete',
                    onPressed: () => _showCompleteDialogResource(task),
                    backgroundColor: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
