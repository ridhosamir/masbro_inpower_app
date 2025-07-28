import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/operasionalApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../models/operasionalApp/ride_request_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class DriverDashboard extends StatefulWidget {
  @override
  _DriverDashboardState createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  final OperasionalFirestoreService _firestoreService =
      OperasionalFirestoreService();
  final _completionNoteController = TextEditingController();
  UserModel? currentUser;
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _completionNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (authService.user != null) {
      final userData = await userService.getUserData(authService.user!.uid);
      setState(() {
        currentUser = userData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

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
                                        Icons.directions_car,
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
                                  'Manage your assigned rides',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              SizedBox(height: 8),
                              StreamBuilder<List<RideRequestModel>>(
                                stream:
                                    _firestoreService.getRideRequestsByDriver(
                                  authService.user!.uid,
                                ),
                                builder: (context, snapshot) {
                                  final requests = snapshot.data ?? [];
                                  final inProgress = requests
                                      .where((r) => r.status == 'inProgress')
                                      .length;

                                  if (requests.isEmpty) {
                                    return Text(
                                      'No rides assigned yet',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    );
                                  }

                                  return Text(
                                    '${requests.length} total rides · $inProgress in progress',
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

            // Requests List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
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
      stream: _firestoreService.getRideRequestsByDriver(
        Provider.of<AuthService>(context, listen: false).user!.uid,
      ),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        final inProgress =
            requests.where((r) => r.status == 'inProgress').length;
        final completed = requests.where((r) => r.status == 'completed').length;
        final today = DateTime.now();
        final todayRequests = requests
            .where((r) =>
                r.pickupDateTime.year == today.year &&
                r.pickupDateTime.month == today.month &&
                r.pickupDateTime.day == today.day)
            .length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Rides',
                count: requests.length,
                icon: Icons.directions_car,
                color: Colors.blue,
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
                title: 'Completed',
                count: completed,
                icon: Icons.check_circle,
                color: Colors.green,
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
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<List<RideRequestModel>>(
      stream: _firestoreService.getRideRequestsByDriver(authService.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading rides...'),
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
                Text('Error loading rides'),
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
        requests = requests.where((r) => r.status == status).toList();

        // Sort requests by pickup date (nearest first for in progress, most recent completion for completed)
        if (status == 'inProgress') {
          requests.sort((a, b) => a.pickupDateTime.compareTo(b.pickupDateTime));
        } else {
          requests.sort((a, b) {
            if (a.completedAt == null && b.completedAt == null) return 0;
            if (a.completedAt == null) return 1;
            if (b.completedAt == null) return -1;
            return b.completedAt!.compareTo(a.completedAt!);
          });
        }

        if (requests.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showRequestDetail(request),
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
              SizedBox(height: 12),

              // Pickup time and passenger info
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 8),
                  Text(
                    'Pickup: ${DateFormat('MMM dd, HH:mm').format(request.pickupDateTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 8),
                  Text(
                    'Passengers: ${request.passengerCapacity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 8),
                  Text(
                    'Requester: ${request.employeeName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (request.vehicleName != null) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.directions_car,
                        size: 16, color: Colors.grey[500]),
                    SizedBox(width: 8),
                    Text(
                      'Vehicle: ${request.vehicleName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
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

              // Return trip info if available
              if (request.returnDateTime != null) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available,
                          color: Colors.amber[700], size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Return trip scheduled for ${DateFormat('MMM dd, HH:mm').format(request.returnDateTime!)}',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action button for in-progress tasks
              if (request.status == 'inProgress') ...[
                SizedBox(height: 16),
                CustomButton(
                  text: 'Mark as Completed',
                  onPressed: () => _showCompleteDialog(request),
                  backgroundColor: Colors.green,
                ),
              ],

              // Show completion notes for completed tasks
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
                      ),
                      if (request.completedAt != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Completed on: ${DateFormat('MMM dd, HH:mm').format(request.completedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      case 'inProgress':
        message = 'No Rides In Progress';
        description = 'You don\'t have any rides currently in progress';
        icon = Icons.directions_car;
        break;
      case 'completed':
        message = 'No Completed Rides';
        description = 'You haven\'t completed any rides yet';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No Rides';
        description = 'You don\'t have any rides';
        icon = Icons.directions_car_outlined;
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
        ],
      ),
    );
  }

  void _showRequestDetail(RideRequestModel request) {
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
            if (request.status == 'inProgress')
              Padding(
                padding: EdgeInsets.all(16),
                child: CustomButton(
                  text: 'Mark as Completed',
                  onPressed: () {
                    Navigator.pop(context);
                    _showCompleteDialog(request);
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

  void _showCompleteDialog(RideRequestModel request) {
    _completionNoteController.clear();

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
              controller: _completionNoteController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _completionNoteController.clear();
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _completeRequest(request),
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

  Future<void> _completeRequest(RideRequestModel request) async {
    if (_completionNoteController.text.trim().isEmpty) {
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

    try {
      await _firestoreService.completeRideRequest(
        request.id,
        _completionNoteController.text.trim(),
        driverId: request.driverId,
        vehicleId: request.vehicleId,
      );

      Navigator.pop(context); // Close dialog

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      Navigator.pop(context); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing ride: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
