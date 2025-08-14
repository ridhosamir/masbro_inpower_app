import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/operasionalApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../models/operasionalApp/ride_request_model.dart';
import '../../../models/operasionalApp/driver_model.dart';
import '../../../models/operasionalApp/vehicle_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_text_field.dart';
import 'vehicle_manage_screen.dart';
import 'driver_manage_screen.dart';
import 'ride_request_detail_screen.dart';
import 'assign_driver_vehicle_screen.dart';

class OfficerDashboardOprational extends StatefulWidget {
  @override
  _OfficerDashboardState createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboardOprational>
    with TickerProviderStateMixin {
  final OperasionalFirestoreService _firestoreService =
      OperasionalFirestoreService();
  UserModel? currentUser;
  late TabController _tabController;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _completionReasonController = TextEditingController();
  bool _isCompleting = false;

  List<DriverModel> _drivers = [];
  List<VehicleModel> _vehicles = [];
  bool _loadingDrivers = false;
  bool _loadingVehicles = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
    _loadDriversAndVehicles();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firestoreService.syncDriverVehicleStatus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _completionReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (authService.user != null) {
      try {
        final userData = await userService.getUserData(authService.user!.uid);
        if (mounted) {
          setState(() {
            currentUser = userData;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _loadDriversAndVehicles() async {
    setState(() {
      _loadingDrivers = true;
      _loadingVehicles = true;
    });

    try {
      _firestoreService.getDrivers().listen((drivers) {
        if (mounted) {
          setState(() {
            _drivers = drivers;
            _loadingDrivers = false;
          });
        }
      });

      _firestoreService.getVehicles().listen((vehicles) {
        if (mounted) {
          setState(() {
            _vehicles = vehicles;
            _loadingVehicles = false;
          });
        }
      });
    } catch (e) {
      print('Error loading drivers and vehicles: $e');
      if (mounted) {
        setState(() {
          _loadingDrivers = false;
          _loadingVehicles = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _getDriverRating(String driverId) async {
    try {
      return await _firestoreService.getDriverRatingData(driverId);
    } catch (e) {
      print('Error getting driver rating: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _getVehicleRating(String vehicleId) async {
    try {
      return await _firestoreService.getVehicleRatingData(vehicleId);
    } catch (e) {
      print('Error getting vehicle rating: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              automaticallyImplyLeading: false,
              pinned: true,
              backgroundColor: Theme.of(context).primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                background: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -60,
                      bottom: -40,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentUser != null) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.supervisor_account,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back,',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          currentUser!.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 16, left: 4),
                                child: Text(
                                  'Manage and review transportation requests',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              StreamBuilder<List<RideRequestModel>>(
                                stream: _firestoreService.getRideRequests(),
                                builder: (context, snapshot) {
                                  final requests = snapshot.data ?? [];
                                  final open = requests
                                      .where((r) => r.status == 'open')
                                      .length;
                                  final inProgress = requests
                                      .where((r) => r.status == 'inProgress')
                                      .length;

                                  if (requests.isEmpty) {
                                    return Text(
                                      'No requests to review yet',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    );
                                  }

                                  return Text(
                                    '${requests.length} total requests · $open open · $inProgress in progress',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.search, color: Colors.white, size: 18),
                  ),
                  onPressed: _showSearchDialog,
                  tooltip: 'Search Requests',
                ),
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.filter_list, color: Colors.white, size: 18),
                  ),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter Requests',
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  offset: Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 20,
                  color: Colors.white,
                  shadowColor: Colors.black.withOpacity(0.2),
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        _showProfileDialog();
                        break;
                      case 'sync':
                        _syncDriverVehicleStatus();
                        break;
                      case 'back':
                        Navigator.pop(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 25, 115, 184)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: Color.fromARGB(255, 25, 115, 184),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Profile',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sync',
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.sync,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sync Driver/Vehicle Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'back',
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.red[600],
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Back to Home',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.red[600],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Open'),
                  Tab(text: 'In Progress'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Statistics Cards
            _buildStatisticsCards(),

            // Quick Action Buttons
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.star_border,
                          label: 'Vehicle Ratings',
                          color: Colors.green,
                          onTap: () {
                            _showVehicleRatingsDialog();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.star,
                          label: 'Driver Ratings',
                          color: Colors.blue,
                          onTap: () {
                            _showDriverRatingsDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.directions_car,
                    label: 'Vehicle Management',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleManagementScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),

            // Search Results Info
            if (_searchQuery.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.blue[700], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Searching for: "$_searchQuery"',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child:
                          Icon(Icons.close, color: Colors.blue[700], size: 16),
                    ),
                  ],
                ),
              ),

            // Filter indicator
            if (_selectedFilter != 'all')
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal: 16, vertical: _searchQuery.isNotEmpty ? 8 : 0),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                        _selectedFilter == 'today'
                            ? Icons.today
                            : _selectedFilter == 'week'
                                ? Icons.date_range
                                : Icons.calendar_month,
                        color: Colors.purple[700],
                        size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filtered by: ${_selectedFilter == 'today' ? 'Today' : _selectedFilter == 'week' ? 'This Week' : 'This Month'}',
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = 'all';
                        });
                      },
                      child: Icon(Icons.close,
                          color: Colors.purple[700], size: 16),
                    ),
                  ],
                ),
              ),

            // Ride Requests List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestsList('all'),
                  _buildRequestsList('open'),
                  _buildRequestsList('inProgress'),
                  _buildRequestsList('completed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return StreamBuilder<List<RideRequestModel>>(
      stream: _firestoreService.getRideRequests(),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        final open = requests.where((r) => r.status == 'open').length;
        final inProgress =
            requests.where((r) => r.status == 'inProgress').length;
        final completed = requests.where((r) => r.status == 'completed').length;
        final today = DateTime.now();
        final todayRequests = requests
            .where((r) =>
                r.createdAt.year == today.year &&
                r.createdAt.month == today.month &&
                r.createdAt.day == today.day)
            .length;

        return Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'All Requests',
                  count: requests.length,
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Open',
                  count: open,
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Today',
                  count: todayRequests,
                  icon: Icons.today,
                  color: Colors.purple,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'In Progress',
                  count: inProgress,
                  icon: Icons.directions_car,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDriverRatingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.blue),
              SizedBox(width: 8),
              Text('Driver Ratings'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: _loadingDrivers
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading drivers...'),
                      ],
                    ),
                  )
                : _drivers.isEmpty
                    ? Center(
                        child: Text('No drivers found.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _drivers.length,
                        itemBuilder: (context, index) {
                          final driver = _drivers[index];
                          return _buildDriverRatingItem(driver);
                        },
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showVehicleRatingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.green),
              SizedBox(width: 8),
              Text('Vehicle Ratings'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: _loadingVehicles
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading vehicles...'),
                      ],
                    ),
                  )
                : _vehicles.isEmpty
                    ? Center(
                        child: Text('No vehicles found.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _vehicles[index];
                          return _buildVehicleRatingItem(vehicle);
                        },
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDriverRatingItem(DriverModel driver) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDriverRating(driver.id),
      builder: (context, snapshot) {
        double averageRating = 0.0;
        int totalRatings = 0;

        if (snapshot.hasData) {
          averageRating = snapshot.data!['averageRating'] ?? 0.0;
          totalRatings = snapshot.data!['totalRatings'] ?? 0;
        }

        return Card(
          margin: EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
            title: Text(
              driver.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: driver.isAvailable
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: driver.isAvailable
                              ? Colors.green[300]!
                              : Colors.red[300]!,
                        ),
                      ),
                      child: Text(
                        driver.isAvailable ? 'Available' : 'Busy',
                        style: TextStyle(
                          fontSize: 10,
                          color: driver.isAvailable
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '($totalRatings ${totalRatings == 1 ? "rating" : "ratings"})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleRatingItem(VehicleModel vehicle) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getVehicleRating(vehicle.id),
      builder: (context, snapshot) {
        double averageRating = 0.0;
        int totalRatings = 0;

        if (snapshot.hasData) {
          averageRating = snapshot.data!['averageRating'] ?? 0.0;
          totalRatings = snapshot.data!['totalRatings'] ?? 0;
        }

        return Card(
          margin: EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.directions_car,
                color: Colors.green[700],
                size: 20,
              ),
            ),
            title: Text(
              vehicle.vehicleModel ?? 'Unknown Model',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('License: ${vehicle.licensePlate}'),
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: vehicle.isAvailable
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: vehicle.isAvailable
                              ? Colors.green[300]!
                              : Colors.red[300]!,
                        ),
                      ),
                      child: Text(
                        vehicle.isAvailable ? 'Available' : 'In Use',
                        style: TextStyle(
                          fontSize: 10,
                          color: vehicle.isAvailable
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '($totalRatings ${totalRatings == 1 ? "rating" : "ratings"})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _syncDriverVehicleStatus() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Syncing driver and vehicle status...'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _firestoreService.syncDriverVehicleStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Driver and vehicle status synchronized successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error synchronizing status: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(String status) {
    return StreamBuilder<List<RideRequestModel>>(
      stream: _firestoreService.getRideRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading requests...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading requests'),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        List<RideRequestModel> requests = snapshot.data ?? [];

        if (status != 'all') {
          requests = requests.where((r) => r.status == status).toList();
        }

        if (_searchQuery.isNotEmpty) {
          requests = requests
              .where((r) =>
                  r.pickupLocation
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  r.dropoffLocation
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  r.employeeName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  r.description
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  (r.driverName != null &&
                      r.driverName!
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase())) ||
                  (r.vehicleName != null &&
                      r.vehicleName!
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase())))
              .toList();
        }

        if (_selectedFilter != 'all') {
          switch (_selectedFilter) {
            case 'today':
              final today = DateTime.now();
              requests = requests
                  .where((r) =>
                      r.createdAt.year == today.year &&
                      r.createdAt.month == today.month &&
                      r.createdAt.day == today.day)
                  .toList();
              break;
            case 'week':
              final weekAgo = DateTime.now().subtract(Duration(days: 7));
              requests =
                  requests.where((r) => r.createdAt.isAfter(weekAgo)).toList();
              break;
            case 'month':
              final monthAgo = DateTime.now().subtract(Duration(days: 30));
              requests =
                  requests.where((r) => r.createdAt.isAfter(monthAgo)).toList();
              break;
          }
        }

        requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (requests.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(requests[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(RideRequestModel request) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToRequestDetail(request),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.blue[700],
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From: ${request.pickupLocation}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'To: ${request.dropoffLocation}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
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
                SizedBox(height: 16),
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
                        onPressed: () => _showCompleteDialog(request),
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
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                              onPressed: () => _showCompleteDialog(request),
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
                      onPressed: () => _navigateToAssignDriverVehicle(request),
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
              if (request.status == 'completed') ...[
                if (request.driverRating != null &&
                    request.driverId != null) ...[
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue[700], size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Driver Rating: ${request.driverRating!.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        Spacer(),
                        if (request.driverName != null)
                          Text(
                            '${request.driverName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (request.vehicleRating != null &&
                    request.vehicleId != null) ...[
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.directions_car,
                            color: Colors.green[700], size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Vehicle Rating: ${request.vehicleRating!.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        Spacer(),
                        if (request.vehicleName != null)
                          Text(
                            '${request.vehicleName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'open':
        color = Colors.orange;
        text = 'OPEN';
        icon = Icons.pending;
        break;
      case 'inProgress':
        color = Colors.blue;
        text = 'IN PROGRESS';
        icon = Icons.directions_car;
        break;
      case 'completed':
        color = Colors.green;
        text = 'COMPLETED';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    String description;
    IconData icon;

    switch (status) {
      case 'open':
        message = 'No open requests';
        description = 'All requests have been reviewed';
        icon = Icons.pending_actions;
        break;
      case 'inProgress':
        message = 'No requests in progress';
        description = 'No requests are currently being worked on';
        icon = Icons.directions_car;
        break;
      case 'completed':
        message = 'No completed requests';
        description = 'No requests have been completed yet';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No requests available';
        description = 'Requests will appear here when submitted by employees';
        icon = Icons.assignment_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _selectedFilter != 'all') ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'all';
                  _searchController.clear();
                });
              },
              child: Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToRequestDetail(RideRequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideRequestDetailScreen(request: request),
      ),
    );
  }

  void _navigateToAssignDriverVehicle(RideRequestModel request) {
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
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showCompleteDialog(RideRequestModel request) {
    _completionReasonController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide completion notes:'),
            SizedBox(height: 16),
            CustomTextField(
              labelText: 'Completion Notes',
              hintText: 'Enter notes about completion...',
              controller: _completionReasonController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _completeRequest(request),
            child: _isCompleting
                ? CircularProgressIndicator(strokeWidth: 2)
                : Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRequest(RideRequestModel request) async {
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
      await _firestoreService.completeRideRequest(
        request.id,
        _completionReasonController.text.trim(),
        driverId: request.driverId,
        vehicleId: request.vehicleId,
      );

      Navigator.pop(context);
      setState(() => _isCompleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isCompleting = false);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Requests'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search',
            hintText: 'Enter pickup, dropoff, employee name...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Requests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('All Requests'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Today Only'),
              value: 'today',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('This Week'),
              value: 'week',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('This Month'),
              value: 'month',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

   void _showProfileDialog() {
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileItem('Name', currentUser!.name),
              _buildProfileItem('Email', currentUser!.email),
              _buildProfileItem('Role', currentUser!.role.toUpperCase()),
              _buildProfileItem(
                'Member since',
                DateFormat('dd MMMM yyyy').format(currentUser!.createdAt),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }}