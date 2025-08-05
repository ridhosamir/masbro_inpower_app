import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/models/maintenanceApp/report_model.dart';
import 'package:masbro_inpower_app/models/resourceApp/request_model.dart';
import 'package:masbro_inpower_app/models/operasionalApp/ride_request_model.dart';
import 'package:masbro_inpower_app/models/bookingroomApp/booking_model.dart';
import 'package:masbro_inpower_app/models/user_model.dart';
import 'package:masbro_inpower_app/screens/employee/bookingroomApp/employee_dashboard.dart';
import 'package:masbro_inpower_app/screens/employee/maintenanceApp/employee_dashboard.dart';
import 'package:masbro_inpower_app/screens/employee/operasionalApp/employee_dashboard.dart';
import 'package:masbro_inpower_app/screens/employee/resourceApp/employee_dashboard.dart';
import 'package:masbro_inpower_app/screens/employee/maintenanceApp/report_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/resourceApp/request_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/operasionalApp/ride_request_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/bookingroomApp/booking_detail_screen.dart';
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

class HomeDashboardUser extends StatefulWidget {
  const HomeDashboardUser({super.key});

  @override
  State<HomeDashboardUser> createState() => _HomeDashboardUserState();
}

class _HomeDashboardUserState extends State<HomeDashboardUser>
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
                                    'Home Dashboard',
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
                    StatusTab(currentUser: currentUser!),
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
                          'Home Dashboard',
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
                              'Anggota Sejak ${DateFormat('dd MMM yyyy').format(currentUser!.createdAt)}',
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
                MaterialPageRoute(builder: (context) => EmployeeDashboard()),
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
                    builder: (context) => EmployeeDashboardResource()),
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
                    builder: (context) => EmployeeDashboardOprational()),
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
                    builder: (context) => EmployeeDashboardBookingRoom()),
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
              'Anggota Sejak',
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

class StatusTab extends StatefulWidget {
  final UserModel currentUser;
  const StatusTab({super.key, required this.currentUser});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  List<dynamic> _combinedList = [];
  List<dynamic> _filteredList = [];
  bool _isLoading = true;
  bool _isSearching = false;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 2, vsync: this);
    _fetchData();
    _searchController.addListener(_onSearchChanged);
    _statusTabController.addListener(_filterByStatus);
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    _searchController.dispose();
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
      // Listener _onSearchChanged akan otomatis menangani sisanya
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

    final reportsFuture =
        maintenanceService.getReportsByEmployee(widget.currentUser.uid).first;
    final requestsFuture =
        resourceService.getRequestsByEmployee(widget.currentUser.uid).first;
    final operationalFuture = operasionalService
        .getRideRequestsByEmployee(widget.currentUser.uid)
        .first;
    final bookingFuture =
        bookingService.getBookingsByEmployee(widget.currentUser.uid).first;

    // Tunggu semua data selesai diambil
    final results = await Future.wait([
      reportsFuture,
      requestsFuture,
      operationalFuture,
      bookingFuture,
    ]);

    final reports = results[0] as List<ReportModel>;
    final requests = results[1] as List<RequestModel>;
    final operationalRequests = results[2] as List<RideRequestModel>;
    final bookingRequests = results[3] as List<BookingModel>;

    // Filter semua data berdasarkan status 'open' atau 'inProgress'
    final openAndInProgressReports = reports
        .where((r) => r.status == 'open' || r.status == 'inProgress')
        .toList();
    final openAndInProgressRequests = requests
        .where((r) => r.status == 'open' || r.status == 'inProgress')
        .toList();
    final openAndInProgressOperational = operationalRequests
        .where((r) => r.status == 'open' || r.status == 'inProgress')
        .toList();
    // Catatan: Booking statusnya 'open' dan 'approved'
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
              item.description.toLowerCase().contains(_searchQuery);
        } else if (item is RequestModel) {
          return item.description.toLowerCase().contains(_searchQuery) ||
              (item.timeRequired?.toLowerCase().contains(_searchQuery) ??
                  false);
        } else if (item is RideRequestModel) {
          return item.pickupLocation.toLowerCase().contains(_searchQuery) ||
              item.dropoffLocation.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery);
        } else if (item is BookingModel) {
          return item.roomName.toLowerCase().contains(_searchQuery) ||
              item.eventAgenda.toLowerCase().contains(_searchQuery);
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

  void _navigateToDetail(dynamic item) {
    if (item is ReportModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportDetailScreen(report: item),
        ),
      );
    } else if (item is RequestModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequestDetailScreen(request: item),
        ),
      );
    } else if (item is RideRequestModel) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RideRequestDetailScreen(request: item)));
    } else if (item is BookingModel) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BookingDetailScreen(booking: item)));
    }
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
                      return _buildUnifiedReportCard(item);
                    } else if (item is RequestModel) {
                      return _buildUnifiedRequestCard(item);
                    } else if (item is RideRequestModel) {
                      return _buildUnifiedOperasionalCard(item);
                    } else if (item is BookingModel) {
                      return _buildUnifiedBookingCard(item);
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
        // Tombol Filter
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

  Widget _buildUnifiedReportCard(ReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.construction,
                          color: Colors.orange[700], size: 20),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: report.status == 'open'
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              report.status == 'open' ? 'OPEN' : 'IN PROGRESS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: report.status == 'open'
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 16),
                if (report.imageUrl != null && report.hasValidImage())
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FirebaseStorageImage(
                        imageUrl: report.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${report.buildingName} - ${report.roomName}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pelaporan:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 6),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedRequestCard(RequestModel request) {
    final bool isResourceRequest = request.request == 'resource';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isResourceRequest
                            ? Icons.supervisor_account
                            : Icons.inventory,
                        size: 16,
                        color: Colors.grey[600],
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: request.status == 'open'
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.status == 'open' ? 'OPEN' : 'IN PROGRESS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: request.status == 'open'
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                if (request.request == 'resource')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildInfoRow(Icons.supervisor_account, 'Resource'),
                  )
                else if (request.request == 'item')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildInfoRow(Icons.inventory, 'Item'),
                  ),
                if (request.timeRequired != null &&
                    request.timeRequired!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildInfoRow(
                      Icons.calendar_today_outlined,
                      '${request.timeRequired!}',
                    ),
                  ),
                _buildInfoRow(
                  Icons.access_time,
                  'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(request.createdAt)}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedOperasionalCard(RideRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.directions_car,
                          color: Colors.red[700], size: 20),
                    ),
                    const SizedBox(width: 12),
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
                          _buildStatusChip(request.status),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.my_location,
                  'Dari: ${request.pickupLocation}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Ke: ${request.dropoffLocation}',
                ),
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
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.event,
                  'Pickup Date: ${DateFormat('dd MMM yyyy, HH:mm').format(request.pickupDateTime)}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.event_available,
                  'Return: ${DateFormat('dd MMM yyyy, HH:mm').format(request.pickupDateTime)}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(request.createdAt)}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedBookingCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                          _buildStatusChip(booking.status),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  booking.roomName.isEmpty
                      ? 'Belum ditentukan'
                      : booking.roomName,
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.eventAgenda,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  _formatBookingDuration(
                      booking.usageStartDate, booking.usageEndDate),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(booking.createdAt)}',
                ),
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
}
