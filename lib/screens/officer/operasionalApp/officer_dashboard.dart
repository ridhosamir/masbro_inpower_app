import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/operasionalApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../models/operasionalApp/ride_request_model.dart';
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
  final OperasionalFirestoreService _firestoreService = OperasionalFirestoreService();
  UserModel? currentUser;
  late TabController _tabController;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _completionReasonController = TextEditingController();
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
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
                    // Gradient background
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

                    // Decorative pattern
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

                    // User info content
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentUser != null) ...[
                              Row(
                                children: [
                                  // User avatar
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

                                  // User details
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

                              // Quick stats
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
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.more_vert, color: Colors.white, size: 18),
                  ),
                  offset: Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        _showProfileDialog();
                        break;
                      case 'back':
                        Navigator.pop(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Profile'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'back',
                      child: ListTile(
                        leading: Icon(Icons.arrow_back, color: Colors.red),
                        title: Text('Back to Home',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
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
            Container(
              padding: EdgeInsets.all(16),
              child: _buildStatisticsCards(),
            ),

            // Quick Action Buttons
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  // Helper method for action button
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
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
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

        return Row(
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

        // Filter requests based on status
        if (status != 'all') {
          requests = requests.where((r) => r.status == status).toList();
        }

        // Apply search filter
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

        // Apply additional filter
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

        // Sort requests by creation date (newest first)
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
              // Header with pickup location and status
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

              // Reporter and date info
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

              // Pickup and Return Time
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
                    Icon(Icons.event_available, size: 16, color: Colors.grey[500]),
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

              // Description
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

              // Action buttons for open requests
              if (request.status == 'open') ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToAssignDriverVehicle(request),
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

              // Show driver and vehicle info for inProgress requests
              if (request.status == 'inProgress') ...[
                SizedBox(height: 16),
                if (request.driverName != null && request.vehicleName != null)
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                            Icon(Icons.person, color: Colors.blue[700], size: 16),
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
                            Icon(Icons.directions_car, color: Colors.blue[700], size: 16),
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

              // Show completion notes for completed requests
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
    // Check if request already has an assigned driver and vehicle
    if (request.driverId != null && request.vehicleId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'This request already has assigned driver and vehicle'),
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
    );
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

      Navigator.pop(context); // Close dialog

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

      Navigator.pop(context); // Close dialog

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
      builder: (context) => AlertDialog(
        title: Text('Profile Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('Name', currentUser!.name),
            _buildProfileItem('Email', currentUser!.email),
            _buildProfileItem('Role', currentUser!.role.toUpperCase()),
            _buildProfileItem(
              'Member Since',
              DateFormat('dd MMM yyyy').format(currentUser!.createdAt),
            ),
          ],
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

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
    }