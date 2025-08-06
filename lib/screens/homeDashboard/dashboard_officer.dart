import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/models/maintenanceApp/report_model.dart';
import 'package:masbro_inpower_app/models/resourceApp/request_model.dart';
import 'package:masbro_inpower_app/models/operasionalApp/ride_request_model.dart';
import 'package:masbro_inpower_app/models/bookingroomApp/booking_model.dart';
import 'package:masbro_inpower_app/models/bookingroomApp/room_model.dart';
import 'package:masbro_inpower_app/models/user_model.dart';
import 'package:masbro_inpower_app/screens/employee/maintenanceApp/report_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/operasionalApp/ride_request_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/resourceApp/request_detail_screen.dart';
import 'package:masbro_inpower_app/screens/officer/bookingroomApp/booking_detail_screen.dart';
import 'package:masbro_inpower_app/screens/officer/bookingroomApp/officer_dahboard.dart';
import 'package:masbro_inpower_app/screens/officer/maintenanceApp/assign_technician_screen.dart';
import 'package:masbro_inpower_app/screens/officer/maintenanceApp/officer_dashboard.dart';
import 'package:masbro_inpower_app/screens/officer/operasionalApp/assign_driver_vehicle_screen.dart';
import 'package:masbro_inpower_app/screens/officer/operasionalApp/officer_dashboard.dart';
import 'package:masbro_inpower_app/screens/officer/resourceApp/assign_technician_screen.dart';
import 'package:masbro_inpower_app/screens/officer/resourceApp/officer_dashboard.dart';
import 'package:masbro_inpower_app/screens/officer/resourceApp/request_detail_screen.dart';
import 'package:masbro_inpower_app/services/auth_service.dart';
import 'package:masbro_inpower_app/services/maintenanceApp/firestore_service.dart'
    as maintenance_service;
import 'package:masbro_inpower_app/services/resourceApp/firestore_service.dart'
    as resource_service;
import 'package:masbro_inpower_app/services/operasionalApp/firestore_service.dart'
    as operasional_service;
import 'package:masbro_inpower_app/services/bookingroomApp/firestore_service.dart'
    as booking_service;
import 'package:masbro_inpower_app/services/user_service.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import 'package:provider/provider.dart';

enum BookingType { harian, beberapaHari }

class HomeDashboardOfficer extends StatefulWidget {
  const HomeDashboardOfficer({super.key});

  @override
  State<HomeDashboardOfficer> createState() => _HomeDashboardOfficerState();
}

class _HomeDashboardOfficerState extends State<HomeDashboardOfficer>
    with SingleTickerProviderStateMixin {
  UserModel? currentUser;
  final _searchController = TextEditingController();
  final _rejectionReasonController = TextEditingController();
  late TabController _tabController;
  late booking_service.FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _firestoreService = booking_service.FirestoreService();
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
    _rejectionReasonController.dispose();
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
                                    'Dashboard Officer',
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
                          Tab(text: 'Status'),
                          Tab(text: 'Aplikasi'),
                        ],
                      ),
                    )
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    OfficerStatusTab(currentUser: currentUser!),
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
                          'Dashboard Officer',
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
                              'Selamat Datang,',
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
                              'Officer Sejak ${DateFormat('dd MMM yyyy').format(currentUser!.createdAt)}',
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
            title: Text('Profil Saya'),
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Keluar', style: TextStyle(color: Colors.red)),
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
        children: [
          _buildAppCard(
            context: context,
            title: 'Maintenance',
            icon: Icons.construction,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OfficerDashboard()),
              );
            },
          ),
          _buildAppCard(
            context: context,
            title: 'Resource/Item',
            icon: Icons.people_alt_outlined,
            color: Colors.cyan,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OfficerDashboardResource()),
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
                MaterialPageRoute(
                    builder: (context) => OfficerDashboardOprational()),
              );
            },
          ),
          _buildAppCard(
            context: context,
            title: 'Booking Room',
            icon: Icons.meeting_room,
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OfficerDashboardBookingRoom()),
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
        title: const Text('Informasi Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('Nama', currentUser!.name),
            _buildProfileItem('Email', currentUser!.email),
            _buildProfileItem('Peran', currentUser!.role.toUpperCase()),
            _buildProfileItem(
              'Officer Sejak',
              DateFormat('dd MMMM yyyy').format(currentUser!.createdAt),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
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
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthService>(context, listen: false).signOut();
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class OfficerStatusTab extends StatefulWidget {
  final UserModel currentUser;
  const OfficerStatusTab({super.key, required this.currentUser});

  @override
  State<OfficerStatusTab> createState() => _OfficerStatusTabState();
}

class _OfficerStatusTabState extends State<OfficerStatusTab>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _completionReasonController =
      TextEditingController();
  bool _isCompleting = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  List<dynamic> _combinedList = [];
  List<dynamic> _filteredList = [];
  bool _isLoading = true;
  bool _isSearching = false;

  int _currentPage = 1;
  final int _itemsPerPage = 5;

  late booking_service.FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 2, vsync: this);
    _firestoreService = booking_service.FirestoreService();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
    _statusTabController.addListener(_filterByStatus);
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    _searchController.dispose();
    _completionReasonController.dispose();
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
    });
  }

  void _clearTimeFilter() {
    setState(() {
      _selectedFilter = 'all';
      _filterData();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter Berdasarkan Waktu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Semua Waktu'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Hari Ini'),
              value: 'today',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Minggu Ini'),
              value: 'week',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Bulan Ini'),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          )
        ],
      ),
    );
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final maintenanceService = maintenance_service.FirestoreService();
    final resourceService = resource_service.FirestoreServiceResource();
    final operasionalService =
        operasional_service.OperasionalFirestoreService();
    final bookingService = booking_service.FirestoreService();

    // Get the current snapshot from the streams
    final reportsSnapshot = await maintenanceService.getReports().first;
    final requestsSnapshot = await resourceService.getRequests().first;
    final operationalSnapshot =
        await operasionalService.getRideRequests().first;
    final bookingSnapshot = await bookingService.getBookings().first;

    // Extract the data from snapshots
    final reports = reportsSnapshot;
    final requests = requestsSnapshot;
    final operationalRequests = operationalSnapshot;
    final bookingRequests = bookingSnapshot;

    final openAndInProgressReports = reports
        .where((r) => r.status == 'open' || r.status == 'inProgress')
        .toList();
    final openAndInProgressRequests = requests
        .where((r) => r.status == 'open' || r.status == 'inProgress')
        .toList();
    final openAndInProgressOperational = operationalRequests
        .where((r) => r.status == 'open' || r.status == 'inProgress')
        .toList();
    final openAndInProgressBooking = bookingRequests
        .where((r) => r.status == 'open' || r.status == 'approved')
        .toList();

    setState(() {
      _combinedList = [
        ...openAndInProgressReports,
        ...openAndInProgressRequests,
        ...openAndInProgressOperational,
        ...openAndInProgressBooking,
      ];
      _combinedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _filterData();
      _isLoading = false;
    });
  }

  void _filterData() {
    List<dynamic> filtered = _combinedList;

    if (_searchQuery.isEmpty) {
      final status = _statusTabController.index == 0 ? 'open' : 'inProgress';
      filtered = _combinedList.where((item) => item.status == status).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        if (item is ReportModel) {
          return item.buildingName.toLowerCase().contains(_searchQuery) ||
              item.roomName.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
        } else if (item is RequestModel) {
          return item.description.toLowerCase().contains(_searchQuery) ||
              (item.timeRequired?.toLowerCase().contains(_searchQuery) ??
                  false) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
        } else if (item is RideRequestModel) {
          return item.pickupLocation.toLowerCase().contains(_searchQuery) ||
              item.dropoffLocation.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
        } else if (item is BookingModel) {
          return item.roomName.toLowerCase().contains(_searchQuery) ||
              item.eventAgenda.toLowerCase().contains(_searchQuery) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
        }
        return false;
      }).toList();
    }

    if (_selectedFilter != 'all') {
      final now = DateTime.now();
      filtered = filtered.where((item) {
        final DateTime createdAt = item.createdAt;
        switch (_selectedFilter) {
          case 'today':
            return createdAt.year == now.year &&
                createdAt.month == now.month &&
                createdAt.day == now.day;
          case 'week':
            return now.difference(createdAt).inDays < 7;
          case 'month':
            return createdAt.year == now.year && createdAt.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    setState(() {
      _filteredList = filtered;
      _currentPage = 1;
    });
  }

  void _filterByStatus() {
    if (!_isSearching) {
      _filterData();
    }
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
                if (!_isSearching)
                  TabBar(
                    controller: _statusTabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Theme.of(context).primaryColor,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                    tabs: const [
                      Tab(text: 'Open'),
                      Tab(text: 'In Progress'),
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
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Hasil pencarian untuk "${_searchController.text}"',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredList.length} hasil',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          if (paginatedList.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: _buildEmptyState(),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ...paginatedList.map((item) {
                    if (item is ReportModel) {
                      return _buildReportCard(item);
                    } else if (item is RequestModel) {
                      return _buildRequestCard(item);
                    } else if (item is RideRequestModel) {
                      return _buildRideRequestCard(item);
                    } else if (item is BookingModel) {
                      return _buildBookingCard(item);
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
                          label: const Text('Lihat lebih banyak'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            backgroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
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
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final openCount =
        _combinedList.where((item) => item.status == 'open').length;
    final inProgressCount =
        _combinedList.where((item) => item.status == 'inProgress').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Open',
              count: openCount,
              icon: Icons.folder_open_outlined,
              color: Colors.orange.shade800,
              backgroundColor: Colors.orange.shade50,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'In Progress',
              count: inProgressCount,
              icon: Icons.sync_outlined,
              color: Colors.purple.shade800,
              backgroundColor: Colors.purple.shade50,
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari status terbaru disini...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).primaryColor,
            ),
            tooltip: 'Filter Berdasarkan Waktu',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final bool isSearchActive = _searchQuery.isNotEmpty;
    final bool isTimeFilterActive = _selectedFilter != 'all';

    IconData icon = Icons.inbox_outlined;
    String title = 'Tidak Ada Data';
    String description = 'Tidak ada tugas dengan status ini saat ini.';
    Widget? actionButton;

    if (isSearchActive) {
      icon = Icons.search_off;
      title = 'Pencarian Tidak Ditemukan';
      description =
          'Tidak ada data yang cocok dengan kata kunci "${_searchController.text}".';
      actionButton = TextButton.icon(
        onPressed: _clearSearch,
        icon: const Icon(Icons.clear, color: Colors.blue),
        label: const Text(
          'Hapus Pencarian',
          style: TextStyle(color: Colors.blue),
        ),
      );
    } else if (isTimeFilterActive) {
      icon = Icons.filter_alt_off_outlined;
      title = 'Data Tidak Ditemukan';
      description = 'Tidak ada data pada rentang waktu yang dipilih.';
      actionButton = TextButton.icon(
        onPressed: _clearTimeFilter,
        icon: const Icon(Icons.clear, color: Colors.blue),
        label: const Text(
          'Hapus Filter',
          style: TextStyle(color: Colors.blue),
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
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (actionButton != null) actionButton,
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime? value,
      Function(DateTime) onPicked,
      {DateTime? firstDate}) {
    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: value ?? firstDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (pickedDate != null) onPicked(pickedDate);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value == null
                ? 'Pilih tanggal'
                : DateFormat('EEEE, d MMM yyyy', 'id_ID').format(value)),
            const Icon(Icons.calendar_month),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, TimeOfDay? value,
      Function(TimeOfDay) onPicked,
      {TimeOfDay? startTimeFilter}) {
    List<TimeOfDay> times = List.generate(48, (index) {
      final hour = index ~/ 2;
      final minute = (index % 2) * 30;
      return TimeOfDay(hour: hour, minute: minute);
    });

    if (startTimeFilter != null) {
      final startTimeInMinutes =
          startTimeFilter.hour * 60 + startTimeFilter.minute;
      times = times.where((time) {
        final currentTimeInMinutes = time.hour * 60 + time.minute;
        return currentTimeInMinutes > startTimeInMinutes;
      }).toList();
    }

    return DropdownButtonFormField<TimeOfDay>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      menuMaxHeight: 200,
      hint: times.isEmpty ? const Text('Pilih Jam Mulai') : null,
      items: times.map((time) {
        return DropdownMenuItem<TimeOfDay>(
          value: time,
          child: Text(time.format(context)),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onPicked(newValue);
        }
      },
      validator: (val) => val == null ? 'Wajib diisi' : null,
    );
  }

  Widget _buildStatusChip(String status) {
    String text;
    Color color;
    Color backgroundColor;

    switch (status) {
      case 'open':
        text = 'OPEN';
        color = Colors.red.shade700;
        backgroundColor = Colors.red.withOpacity(0.1);
        break;
      case 'inProgress':
      case 'approved':
        text = 'IN PROGRESS';
        color = Colors.blue.shade700;
        backgroundColor = Colors.blue.withOpacity(0.1);
        break;
      default:
        text = status.toUpperCase();
        color = Colors.grey.shade700;
        backgroundColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 4,
      shadowColor: Colors.teal.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToDetail(booking),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.teal.withOpacity(0.05),
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
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.meeting_room,
                          color: Colors.teal[700], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Room',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2D3748)),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(booking.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Agenda Acara:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${booking.eventAgenda}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.meeting_room_outlined,
                    'Ruangan: ${booking.roomName}'),
                const SizedBox(height: 6),
                _buildInfoRow(
                    Icons.person_outline, 'Oleh: ${booking.employeeName}'),
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  _formatBookingDuration(
                      booking.usageStartDate, booking.usageEndDate),
                ),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.access_time,
                    'Dibuat: ${_getTimeAgo(booking.createdAt)}'),
                if (booking.status == 'open') ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showManageBookingSheet(booking),
                          icon: const Icon(Icons.edit_calendar_outlined,
                              size: 16),
                          label: const Text('Kelola Booking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRejectDialog(booking),
                          icon: const Icon(Icons.free_cancellation, size: 16),
                          label: const Text('Tolak Booking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shadowColor: Colors.orange.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToDetail(report),
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
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.construction,
                                color: Colors.orange[700], size: 20),
                          ),
                          SizedBox(width: 12),
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
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.business,
                                        size: 12,
                                        color: Colors.blue[700],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        report.buildingName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(report.status),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 8),
                    Text(
                      'By ${report.employeeName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 8),
                    Text(
                      _getTimeAgo(report.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (report.imageUrl != null && report.hasValidImage()) ...[
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        report.getNormalizedImageUrl()!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 32,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (report.status == 'open') ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _navigateToAssignTechnicianReport(report),
                          icon: Icon(Icons.engineering, size: 16),
                          label: Text('Assign'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showCompleteDialogMaintenance(report),
                          icon: Icon(Icons.check_circle, size: 16),
                          label: Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (report.status == 'inProgress') ...[
                  SizedBox(height: 16),
                  report.assignedTechnicianId == null
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _navigateToAssignTechnicianReport(report),
                            icon: Icon(Icons.engineering, size: 16),
                            label: Text('Assign Technician'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.engineering,
                                  color: Colors.blue[700], size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Assigned to ${report.technicianName}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _showCompleteDialogMaintenance(report),
                                child: Text('Complete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
                if (report.status == 'completed' &&
                    report.completionReason != null) ...[
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completion Notes:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          report.completionReason!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRideRequestCard(RideRequestModel request) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 4,
      shadowColor: Colors.red.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToDetail(request),
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
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.directions_car,
                                color: Colors.red[700], size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Request Operasional',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2D3748),
                                  ),
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
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 8),
                    Text(
                      'By ${request.employeeName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 8),
                    Text(
                      _getTimeAgo(request.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 8),
                    Text(
                      'Pickup: ${DateFormat('MMM dd, HH:mm').format(request.pickupDateTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (request.returnDateTime != null) ...[
                      SizedBox(width: 16),
                      Icon(Icons.event_available,
                          size: 16, color: Colors.grey[500]),
                      SizedBox(width: 8),
                      Text(
                        'Return: ${DateFormat('MMM dd, HH:mm').format(request.returnDateTime!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (request.status == 'open') ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _navigateToAssignDriverVehicle(request),
                          icon: Icon(Icons.directions_car, size: 16),
                          label: Text('Assign'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showCompleteDialogOperasional(request),
                          icon: Icon(Icons.check_circle, size: 16),
                          label: Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (request.status == 'inProgress') ...[
                  SizedBox(height: 16),
                  if (request.driverName != null && request.vehicleName != null)
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person,
                                  color: Colors.blue[700], size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Driver: ${request.driverName}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.directions_car,
                                  color: Colors.blue[700], size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vehicle: ${request.vehicleName}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    _showCompleteDialogOperasional(request),
                                child: Text('Complete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _navigateToAssignDriverVehicle(request),
                        icon: Icon(Icons.directions_car, size: 16),
                        label: Text('Assign Driver & Vehicle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
                if (request.status == 'completed' &&
                    request.completionNote != null) ...[
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completion Notes:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          request.completionNote!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    final bool isResourceRequest = request.request == 'resource';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shadowColor: Colors.cyan.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToDetail(request),
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
                      child:
                          Icon(Icons.groups, color: Colors.cyan[700], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request Resource',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(request.status),
                  ],
                ),
                if (!isResourceRequest && request.hasValidImage()) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FirebaseStorageImage(
                        imageUrl: request.getNormalizedImageUrl(),
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
                Text(
                  'Permintaan:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isResourceRequest
                          ? Icons.supervisor_account
                          : Icons.inventory,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Kebutuhan: ${request.request[0].toUpperCase()}${request.request.substring(1)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Text(
                      'Oleh: ${request.employeeName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (request.timeRequired != null &&
                    request.timeRequired!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        request.timeRequired!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Icon(
                      request.status == 'completed'
                          ? Icons.check_circle
                          : Icons.access_time,
                      size: 14,
                      color: request.status == 'completed'
                          ? Colors.green[700]
                          : Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      request.status == 'completed' &&
                              request.completionDate != null
                          ? 'Selesai: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(request.completionDate!)}'
                          : 'Dibuat: ${_getTimeAgo(request.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: request.status == 'completed'
                            ? Colors.green[800]
                            : Colors.grey[600],
                        fontWeight: request.status == 'completed'
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (request.status == 'open' ||
                    request.status == 'inProgress') ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _navigateToAssignTechnicianRequest(request),
                          icon: const Icon(Icons.engineering, size: 16),
                          label: Text(request.assignedTechnicianId == null
                              ? 'Tugaskan'
                              : 'Ubah Teknisi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCompleteDialogResource(request),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Selesaikan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              color: isBold ? Colors.grey[800] : Colors.grey[600],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final DateFormat dayFormat = DateFormat('E, d MMM yyyy', 'id_ID');
    final DateFormat timeFormat = DateFormat('HH:mm', 'id_ID');
    if (DateUtils.isSameDay(start, end)) {
      // Jika di hari yang sama: "Sen, 28 Jul 2025, 09:00 - 11:00"
      return '${dayFormat.format(start)}, ${timeFormat.format(start)} - ${timeFormat.format(end)}';
    } else {
      // Jika beda hari: "28 Jul 2025, 09:00 - 29 Jul 2025, 11:00"
      final DateFormat fullFormat = DateFormat('d MMM y', 'id_ID');
      return '${fullFormat.format(start)} - ${fullFormat.format(end)}';
    }
  }

  void _navigateToAssignTechnicianReport(ReportModel report) {
    if (report.assignedTechnicianId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'This report already has an assigned technician: ${report.technicianName}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTechnicianScreen(report: report),
      ),
    );
  }

  void _navigateToAssignTechnicianRequest(RequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTechnicianScreenResource(request: request),
      ),
    );
  }

  void _navigateToAssignDriverVehicle(RideRequestModel request) {
    // Check if request already has an assigned driver and vehicle
    if (request.driverId != null && request.vehicleId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This request already has assigned driver and vehicle'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignDriverVehicleScreen(request: request),
      ),
    ).then((result) {
      // Refresh the UI when returning from assignment screen
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showCompleteDialogMaintenance(ReportModel report) {
    _completionReasonController.clear();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: !_isCompleting,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Report'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provide completion notes:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _completionReasonController,
                decoration: const InputDecoration(
                  labelText: 'Completion Notes',
                  hintText: 'Enter notes about completion...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide completion notes';
                  }
                  return null;
                },
              ),
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
              if (formKey.currentState!.validate()) {
                _completeReportMaintenance(report);
              }
            },
            child: _isCompleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeReportMaintenance(ReportModel report) async {
    if (_completionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide completion notes'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCompleting = true);

    try {
      final maintenanceService = maintenance_service.FirestoreService();
      await maintenanceService.completeReport(
        report.id,
        _completionReasonController.text.trim(),
        technicianId: report.assignedTechnicianId ?? 'officer',
        technicianName: report.technicianName ?? 'Office Management',
      );

      // Pop the dialog on success
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchData();
    } catch (e) {
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing report: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  void _showCompleteDialogResource(RequestModel request) {
    _completionReasonController.clear();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: !_isCompleting,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provide completion notes:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _completionReasonController,
                decoration: const InputDecoration(
                  labelText: 'Completion Notes',
                  hintText: 'Enter notes about completion...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide completion notes';
                  }
                  return null;
                },
              ),
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
              if (formKey.currentState!.validate()) {
                _completeRequestResource(request);
              }
            },
            child: _isCompleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRequestResource(RequestModel request) async {
    if (_completionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide completion notes'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.currentUser == null) return;

    setState(() => _isCompleting = true);

    try {
      final resourceService = resource_service.FirestoreServiceResource();
      await resourceService.completeRequest(
        request.id,
        _completionReasonController.text.trim(),
        technicianId: request.assignedTechnicianId ?? widget.currentUser!.uid,
        technicianName: request.technicianName ?? widget.currentUser!.name,
      );

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchData();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  void _showCompleteDialogOperasional(RideRequestModel request) {
    _completionReasonController.clear();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: !_isCompleting,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Ride Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provide completion notes (optional):'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _completionReasonController,
                decoration: const InputDecoration(
                  labelText: 'Completion Notes',
                  hintText: 'Enter notes about completion...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide completion notes';
                  }
                  return null;
                },
              ),
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
              if (formKey.currentState!.validate()) {
                _completeRequestOperasional(request);
              }
            },
            child: _isCompleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRequestOperasional(RideRequestModel request) async {
    if (_completionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide completion notes'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCompleting = true);

    try {
      final operasionalService =
          operasional_service.OperasionalFirestoreService();
      await operasionalService.completeRideRequest(
        request.id,
        _completionReasonController.text.trim(),
        driverId: request.driverId,
        vehicleId: request.vehicleId,
      );

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride request marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchData();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  void _showManageBookingSheet(BookingModel booking) {
    final formKey = GlobalKey<FormState>();

    RoomModel? selectedRoom;
    final notesController =
        TextEditingController(text: booking.completionReason);

    BookingType bookingType =
        DateUtils.isSameDay(booking.usageStartDate, booking.usageEndDate)
            ? BookingType.harian
            : BookingType.beberapaHari;

    // State untuk durasi Harian
    DateTime selectedDate = booking.usageStartDate;
    TimeOfDay startTime = TimeOfDay.fromDateTime(booking.usageStartDate);
    TimeOfDay endTime = TimeOfDay.fromDateTime(booking.usageEndDate);

    // State untuk durasi Beberapa Hari
    DateTime startDateMulti = booking.usageStartDate;
    DateTime endDateMulti = booking.usageEndDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String? selectedRoomId =
            booking.roomName == 'Belum Ditentukan' ? null : booking.roomId;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> handleFinalApproval() async {
              if (!formKey.currentState!.validate()) return;

              DateTime finalStartDate;
              DateTime finalEndDate;

              if (bookingType == BookingType.harian) {
                finalStartDate = DateTime(selectedDate.year, selectedDate.month,
                    selectedDate.day, startTime.hour, startTime.minute);
                finalEndDate = DateTime(selectedDate.year, selectedDate.month,
                    selectedDate.day, endTime.hour, endTime.minute);
              } else {
                finalStartDate = startDateMulti;
                finalEndDate = endDateMulti;
              }

              // CEK KONFLIK JADWAL TERLEBIH DAHULU
              try {
                showDialog(
                    context: context,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                    barrierDismissible: false);

                // Cek apakah ada konflik dengan booking yang sudah approved
                final hasConflict =
                    await _firestoreService.checkBookingConflictForApproval(
                  selectedRoomId!,
                  finalStartDate,
                  finalEndDate,
                  bookingIdToExclude:
                      booking.id, // Exclude booking yang sedang diproses
                );

                // Tutup loading dialog
                if (mounted) Navigator.pop(context);

                if (hasConflict) {
                  // Dapatkan detail booking yang bentrok untuk info lebih detail
                  final conflictingBookings =
                      await _firestoreService.getConflictingBookings(
                    selectedRoomId!,
                    finalStartDate,
                    finalEndDate,
                    bookingIdToExclude: booking.id,
                  );

                  // Tampilkan popup error dengan info detail
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 24),
                            SizedBox(width: 8),
                            Text('Jadwal Bentrok!'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tidak bisa menyetujui booking karena jadwal bentrok dengan agenda lain yang sudah disetujui:',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: conflictingBookings
                                      .map((conflictBooking) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '• ${conflictBooking.eventAgenda}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                height: 28,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            BookingDetailScreen(
                                                                booking:
                                                                    conflictBooking),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    side: BorderSide.none,
                                                  ),
                                                  child: const Text(
                                                      'Lihat Jadwal',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ),
                                              )
                                            ],
                                          ),
                                          Text(
                                            '  ${_formatDateRange(conflictBooking.usageStartDate, conflictBooking.usageEndDate)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                          Text(
                                            '  Pemesan: ${conflictBooking.employeeName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Silakan pilih jadwal atau ruangan lain.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.red, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                // Jika tidak ada konflik, lanjutkan dengan konfirmasi approval
                final bool? confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi Persetujuan'),
                    content: const Text(
                        'Apakah Anda yakin ingin menyetujui pemesanan ini?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Batal')),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Ya, Setujui',
                              style: TextStyle(color: Colors.green))),
                    ],
                  ),
                );

                if (confirmed != true) return;
                if (!mounted) return;

                // Tampilkan loading lagi untuk proses approval
                showDialog(
                    context: context,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                    barrierDismissible: false);

                // Proses approval
                await _firestoreService.updateAndApproveBooking(
                  bookingId: booking.id,
                  roomId: selectedRoomId!,
                  roomName: selectedRoom!.name,
                  startDate: finalStartDate,
                  endDate: finalEndDate,
                  notes: notesController.text.trim(),
                );

                if (!mounted) return;

                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Booking berhasil disetujui.'),
                  backgroundColor: Colors.green,
                ));
              } catch (e) {
                // Tutup loading jika ada error
                if (mounted) Navigator.pop(context);

                // Tampilkan error
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Error'),
                      content: Text('Terjadi kesalahan: ${e.toString()}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            }

            Widget _buildSingleDayInputs(
              BuildContext context,
              StateSetter setState,
              DateTime? currentDate,
              TimeOfDay? currentTime,
              TimeOfDay? endTime, {
              required Function(DateTime) onDateChanged,
              required Function(TimeOfDay) onStartTimeChanged,
              required Function(TimeOfDay) onEndTimeChanged,
            }) {
              return Column(
                children: [
                  _buildDatePicker(context, 'Pilih Tanggal Acara', currentDate,
                      (date) {
                    setState(() => onDateChanged(date));
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(
                          context,
                          'Jam Mulai',
                          currentTime,
                          (time) {
                            setState(() {
                              onStartTimeChanged(time);
                              if (endTime != null &&
                                  (endTime.hour * 60 + endTime.minute) <=
                                      (time.hour * 60 + time.minute)) {
                                onEndTimeChanged(TimeOfDay(
                                    hour: time.hour + 1, minute: time.minute));
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePicker(
                          context,
                          'Jam Selesai',
                          endTime,
                          (time) => setState(() => onEndTimeChanged(time)),
                          startTimeFilter: currentTime,
                        ),
                      ),
                    ],
                  )
                ],
              );
            }

            Widget _buildMultiDayInputs(
              BuildContext context,
              StateSetter setState,
              DateTime? currentStartDate,
              DateTime? currentEndDate, {
              required Function(DateTime) onStartDateChanged,
              required Function(DateTime) onEndDateChanged,
            }) {
              return Column(
                children: [
                  _buildDatePicker(context, 'Tanggal Mulai', currentStartDate,
                      (date) {
                    setState(() {
                      onStartDateChanged(date);
                      if (currentEndDate != null &&
                          date.isAfter(currentEndDate)) {
                        onEndDateChanged(date.add(const Duration(days: 1)));
                      }
                    });
                  }),
                  const SizedBox(height: 16),
                  _buildDatePicker(
                    context,
                    'Tanggal Selesai',
                    currentEndDate,
                    (date) => setState(() => onEndDateChanged(date)),
                    firstDate: currentStartDate,
                  ),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                          const Text('Kelola Booking',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          _buildStatusChip('open'),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildDetailItem(Icons.event_note,
                                        'Agenda Acara', booking.eventAgenda),
                                    _buildDetailItem(
                                        Icons.local_activity_outlined,
                                        'Jenis Kegiatan',
                                        booking.activityType),
                                    _buildDetailItem(Icons.person_outline,
                                        'Pemesan', booking.employeeName),
                                    _buildDetailItem(Icons.add_box_outlined,
                                        'Kebutuhan', booking.needs),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Konfigurasi Ruangan & Waktu'),
                              StreamBuilder<List<RoomModel>>(
                                stream: _firestoreService.getRooms(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Text(
                                        'Error: Tidak ada ruangan tersedia.');
                                  }
                                  final rooms = snapshot.data!;
                                  if (selectedRoomId != null &&
                                      selectedRoom == null) {
                                    try {
                                      selectedRoom = rooms.firstWhere(
                                          (r) => r.id == selectedRoomId);
                                    } catch (_) {
                                      selectedRoomId = null;
                                      selectedRoom = null;
                                    }
                                  }

                                  return DropdownButtonFormField<String>(
                                    value: selectedRoomId,
                                    menuMaxHeight: 300,
                                    decoration: const InputDecoration(
                                      labelText: 'Pilih Ruangan',
                                      prefixIcon:
                                          Icon(Icons.meeting_room_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    isExpanded: true,
                                    itemHeight: null,
                                    selectedItemBuilder:
                                        (BuildContext context) {
                                      return rooms
                                          .map<Widget>((RoomModel room) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            room.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList();
                                    },
                                    items: rooms.map((room) {
                                      return DropdownMenuItem<String>(
                                        value: room.id,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    room.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Kapasitas: ${room.capacity} orang',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: Color(0xFFEEEEEE),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedRoomId = value;
                                        selectedRoom = rooms
                                            .firstWhere((r) => r.id == value);
                                      });
                                    },
                                    validator: (value) => value == null
                                        ? 'Ruangan harus dipilih'
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              SegmentedButton<BookingType>(
                                segments: const [
                                  ButtonSegment(
                                    value: BookingType.harian,
                                    label: Text('Harian'),
                                    icon: Icon(Icons.access_time),
                                  ),
                                  ButtonSegment(
                                    value: BookingType.beberapaHari,
                                    label: Text('Beberapa Hari'),
                                    icon: Icon(Icons.date_range),
                                  ),
                                ],
                                selected: {bookingType},
                                onSelectionChanged:
                                    (Set<BookingType> newSelection) {
                                  setModalState(() {
                                    bookingType = newSelection.first;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              if (bookingType == BookingType.harian)
                                _buildSingleDayInputs(
                                  context,
                                  setModalState,
                                  selectedDate,
                                  startTime,
                                  endTime,
                                  onDateChanged: (d) => selectedDate = d,
                                  onStartTimeChanged: (t) => startTime = t,
                                  onEndTimeChanged: (t) => endTime = t,
                                )
                              else
                                _buildMultiDayInputs(
                                  context,
                                  setModalState,
                                  startDateMulti,
                                  endDateMulti,
                                  onStartDateChanged: (d) => startDateMulti = d,
                                  onEndDateChanged: (d) => endDateMulti = d,
                                ),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Catatan Tambahan (Opsional)'),
                              TextFormField(
                                controller: notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Catatan Tambahan',
                                  hintText:
                                      'Tambahkan catatan untuk pemesan...',
                                  prefixIcon: Icon(Icons.note_alt_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Batal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: handleFinalApproval,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Setujui'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BookingModel booking) {
    final _rejectionReasonController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Booking'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _rejectionReasonController,
            decoration: const InputDecoration(
              labelText: 'Alasan Penolakan',
              hintText: 'Berikan alasan penolakan booking...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Alasan tidak boleh kosong';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // Instantiating the correct service from the aliased import
                final bookingService = booking_service.FirestoreService();

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  await bookingService.updateBookingStatus(
                    booking.id,
                    'cancelled',
                    reason:
                        'Ditolak: ${_rejectionReasonController.text.trim()}',
                  );

                  // Pop loading dialog
                  if (mounted) Navigator.pop(context);
                  // Pop reject dialog
                  if (mounted) Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Booking telah ditolak.'),
                    backgroundColor: Colors.orange,
                  ));

                  // Refresh the data list
                  _fetchData();
                } catch (e) {
                  // Pop loading dialog on error
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Gagal menolak booking: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak Booking',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((_) => _rejectionReasonController.dispose());
  }

  void _navigateToDetail(dynamic item) {
    if (item is ReportModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ReportDetailScreen(report: item)),
      );
    } else if (item is RequestModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RequestDetailScreenResource(request: item)),
      );
    } else if (item is RideRequestModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RideRequestDetailScreen(request: item)),
      );
    } else if (item is BookingModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => BookingDetailScreen(booking: item)),
      );
    }
  }

  String _formatBookingDuration(DateTime start, DateTime end) {
    final isSingleDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (isSingleDay) {
      // Format untuk booking harian: Sen, 4 Agu 2025, 09:00 - 11:30
      final date = DateFormat('E, d MMM yyyy', 'id_ID').format(start);
      final startTime = DateFormat('HH:mm').format(start);
      final endTime = DateFormat('HH:mm').format(end);
      return '$date, $startTime - $endTime';
    } else {
      // Format untuk booking beberapa hari: Sen, 4 Agu 2025 s/d Rab, 6 Agu 2025
      final startDate = DateFormat('E, d MMM yyyy', 'id_ID').format(start);
      final endDate = DateFormat('E, d MMM yyyy', 'id_ID').format(end);
      return '$startDate s/d $endDate';
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}
