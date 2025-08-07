import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/maintenanceApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../models/maintenanceApp/task_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class TechnicianDashboard extends StatefulWidget {
  @override
  _TechnicianDashboardState createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final _completionNoteController = TextEditingController();
  UserModel? currentUser;
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
              expandedHeight: 220, // Increased height to accommodate rating
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
                                        Icons.engineering,
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

                              // Rating Display Section
                              Padding(
                                padding: EdgeInsets.only(top: 16, left: 4),
                                child: _buildRatingSection(),
                              ),

                              // Quick stats
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 8, left: 4), // Reduced top padding
                                child: Column(
                                  mainAxisSize: MainAxisSize.min, // Important
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manage your maintenance tasks',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    SizedBox(height: 4), // Reduced spacing
                                    StreamBuilder<List<TaskModel>>(
                                      stream: _firestoreService
                                          .getTasksByTechnician(
                                        authService.user!.uid,
                                      ),
                                      builder: (context, snapshot) {
                                        final tasks = snapshot.data ?? [];
                                        final inProgress = tasks
                                            .where((t) =>
                                                t.status == 'inProgress' ||
                                                t.status == 'in_progress')
                                            .length;

                                        if (tasks.isEmpty) {
                                          return Text(
                                            'No tasks assigned yet',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          );
                                        }

                                        return Text(
                                          '${tasks.length} total tasks · $inProgress in progress',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
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
                  Tab(text: 'All Tasks'),
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

            // Tasks List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTasksList('all'),
                  _buildTasksList('inProgress'),
                  _buildTasksList('completed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    if (currentUser == null) return SizedBox();

    final hasRating = currentUser!.averageRating != null &&
        currentUser!.totalRatings != null &&
        currentUser!.totalRatings! > 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.amber[300],
            size: 18,
          ),
          SizedBox(width: 6),
          if (hasRating) ...[
            Text(
              '${currentUser!.averageRating!.toStringAsFixed(1)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '(${currentUser!.totalRatings} ${currentUser!.totalRatings! > 1 ? 'ratings' : 'rating'})',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ] else ...[
            Text(
              'No ratings yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<List<TaskModel>>(
      stream: _firestoreService.getTasksByTechnician(authService.user!.uid),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        // Count tasks with either inProgress or in_progress status
        final inProgress = tasks
            .where((t) => t.status == 'inProgress' || t.status == 'in_progress')
            .length;
        final completed = tasks.where((t) => t.status == 'completed').length;
        final today = DateTime.now();
        final todayTasks = tasks
            .where((t) =>
                t.assignedAt.year == today.year &&
                t.assignedAt.month == today.month &&
                t.assignedAt.day == today.day)
            .length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Tasks',
                count: tasks.length,
                icon: Icons.assignment,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'In Progress',
                count: inProgress,
                icon: Icons.engineering,
                color: Colors.blue,
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
            SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Today',
                count: todayTasks,
                icon: Icons.today,
                color: Colors.purple,
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

  Widget _buildTasksList(String tabStatus) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<List<TaskModel>>(
      stream: _firestoreService.getTasksByTechnician(authService.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading tasks...'),
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
                Text('Error loading tasks'),
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

        List<TaskModel> tasks = snapshot.data ?? [];

        // Filter tasks based on status (handle both old and new status formats)
        if (tabStatus != 'all') {
          tasks = tasks.where((t) {
            if (tabStatus == 'inProgress') {
              return t.status == 'inProgress' || t.status == 'in_progress';
            } else {
              return t.status == tabStatus;
            }
          }).toList();
        }

        // Sort tasks by assignment date (newest first)
        tasks.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));

        if (tasks.isEmpty) {
          return _buildEmptyState(tabStatus);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _buildTaskCard(tasks[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTaskDetail(task),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with room name and status
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
                            Icons.room,
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
                                task.roomName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              if (task.itemName.isNotEmpty)
                                Text(
                                  'Item: ${task.itemName}',
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
                  _buildStatusChip(task.status),
                ],
              ),
              SizedBox(height: 12),

              // Image if available
              if (task.imageUrl != null) ...[
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      task.imageUrl!,
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

              // Description
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: 12),

              // Date info
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 6),
                  Text(
                    'Assigned ${_getFormattedDate(task.assignedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (task.status == 'completed' &&
                      task.completedAt != null) ...[
                    SizedBox(width: 12),
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.green[500]),
                    SizedBox(width: 6),
                    Text(
                      'Completed ${_getFormattedDate(task.completedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ]
                ],
              ),

              // Action button for in-progress tasks
              if (task.status == 'inProgress' ||
                  task.status == 'in_progress') ...[
                SizedBox(height: 16),
                CustomButton(
                  text: 'Mark as Completed',
                  onPressed: () => _showCompleteDialog(task),
                  backgroundColor: Colors.green,
                ),
              ],

              // Show completion notes for completed tasks
              if (task.status == 'completed' &&
                  task.completionNote != null) ...[
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
                        task.completionNote!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
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

    // Support both old and new status formats
    if (status == 'inProgress' || status == 'in_progress') {
      color = Colors.blue;
      text = 'IN PROGRESS';
      icon = Icons.engineering;
    } else if (status == 'completed') {
      color = Colors.green;
      text = 'COMPLETED';
      icon = Icons.check_circle;
    } else {
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
        message = 'No Tasks In Progress';
        description = 'You don\'t have any tasks currently in progress';
        icon = Icons.engineering;
        break;
      case 'completed':
        message = 'No Completed Tasks';
        description = 'You haven\'t completed any tasks yet';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No Tasks Assigned';
        description = 'Tasks will appear here when assigned by officers';
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
        ],
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
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

  void _showTaskDetail(TaskModel task) {
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
                    _showCompleteDialog(task);
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

  void _showCompleteDialog(TaskModel task) {
    _completionNoteController.clear();

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
            onPressed: () => _completeTask(task),
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

  Future<void> _completeTask(TaskModel task) async {
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
      await _firestoreService.updateTaskStatus(
        task.id,
        'completed',
        completionNote: _completionNoteController.text.trim(),
      );

      Navigator.pop(context); // Close dialog

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      Navigator.pop(context); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing task: $e'),
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
            // Add rating information to profile
            if (currentUser!.averageRating != null &&
                currentUser!.totalRatings != null &&
                currentUser!.totalRatings! > 0) ...[
              Divider(height: 20),
              Text(
                'Performance Rating',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.amber[800],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  // Star rating display
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (currentUser!.averageRating ?? 0).floor()
                            ? Icons.star
                            : index <
                                        (currentUser!.averageRating ?? 0)
                                            .ceil() &&
                                    (currentUser!.averageRating ?? 0).floor() !=
                                        (currentUser!.averageRating ?? 0).ceil()
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${currentUser!.averageRating!.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Based on ${currentUser!.totalRatings} ${currentUser!.totalRatings! > 1 ? 'ratings' : 'rating'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              Divider(height: 20),
              Text(
                'Performance Rating',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No ratings received yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthService>(context, listen: false).signOut();
            },
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
