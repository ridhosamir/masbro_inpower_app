import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import '../../../services/resourceApp/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/resourceApp/request_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_text_field.dart';
import 'request_detail_screen.dart';
import 'assign_technician_screen.dart';

class OfficerDashboardResource extends StatefulWidget {
  const OfficerDashboardResource({super.key});

  @override
  State<OfficerDashboardResource> createState() =>
      _OfficerDashboardResourceState();
}

class _OfficerDashboardResourceState extends State<OfficerDashboardResource>
    with TickerProviderStateMixin {
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? currentUser;
  late TabController _tabController;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _completionReasonController = TextEditingController();
  bool _isCompleting = false;
  final UserService _userService = UserService();
  List<UserModel> _technicians = [];
  bool _loadingTechnicians = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
    _loadTechnicians();
    _searchController.addListener(_onSearchChanged);
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // Fungsi baru untuk memuat daftar teknisi
  Future<void> _loadTechnicians() async {
    setState(() {
      _loadingTechnicians = true;
    });

    try {
      // 1. Dapatkan semua pengguna dengan role 'technician'
      final allTechnicians = await _userService.getTechnicians();

      // 2. Dapatkan semua UID dari koleksi 'drivers'
      final driversSnapshot = await _firestore.collection('drivers').get();
      final driverUIDs = driversSnapshot.docs.map((doc) => doc.id).toSet();

      // 3. Filter teknisi yang UID-nya TIDAK ADA di dalam koleksi 'drivers'
      final nonDriverTechnicians = allTechnicians.where((technician) {
        return !driverUIDs.contains(technician.uid);
      }).toList();

      if (mounted) {
        setState(() {
          _technicians = nonDriverTechnicians;
          _loadingTechnicians = false;
        });
      }
    } catch (e) {
      print('Error loading technicians: $e');
      if (mounted) {
        setState(() {
          _loadingTechnicians = false;
        });
      }
    }
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
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 50),
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
                                    child: const Center(
                                      child: Icon(
                                        Icons.supervisor_account,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                                        const SizedBox(height: 2),
                                        Text(
                                          currentUser!.name,
                                          style: const TextStyle(
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
                                padding:
                                    const EdgeInsets.only(top: 16, left: 4),
                                child: Text(
                                  'Manage and approve resource requests',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<List<RequestModel>>(
                                stream: _firestoreService.getRequests(),
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
                                      'There are no requests for review yet',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return Text(
                                    '${requests.length} total request · $open open · $inProgress in progress',
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
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert,
                        color: Colors.white, size: 18),
                  ),
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == 'profile') _showProfileDialog();
                    if (value == 'logout') _showLogoutDialog();
                    if (value == 'back') {
                      Navigator.of(context).pop();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Profil'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'back',
                      child: ListTile(
                        leading: Icon(Icons.arrow_back, color: Colors.blueGrey),
                        title: Text('Back to Home',
                            style: TextStyle(color: Colors.blueGrey)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title:
                            Text('Keluar', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: const [
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
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildStatisticsCards(),
            ),
            _buildQuickActionButtons(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Kolom Pencarian
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search Request...',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: Colors.grey[600]),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _showFilterDialog,
                      icon: Icon(
                        Icons.filter_list,
                        color: Theme.of(context).primaryColor,
                      ),
                      tooltip: 'Request Filter',
                    ),
                  ),
                ],
              ),
            ),
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
    return StreamBuilder<List<RequestModel>>(
      stream: _firestoreService.getRequests(),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        final open = requests.where((r) => r.status == 'open').length;
        final inProgress =
            requests.where((r) => r.status == 'inProgress').length;
        final completed = requests.where((r) => r.status == 'completed').length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'All Request',
                count: requests.length,
                icon: Icons.assignment,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Open',
                count: open,
                icon: Icons.pending,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'In Progress',
                count: inProgress,
                icon: Icons.engineering,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
    return StreamBuilder<List<RequestModel>>(
      stream: _firestoreService.getRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<RequestModel> requests = snapshot.data ?? [];

        if (status != 'all') {
          requests = requests.where((r) => r.status == status).toList();
        }

        if (_searchQuery.isNotEmpty) {
          requests = requests
              .where((r) =>
                  r.employeeName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  r.description
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  (r.timeRequired
                          ?.toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ??
                      false))
              .toList();
        }

        if (_selectedFilter != 'all') {
          final now = DateTime.now();
          requests = requests.where((r) {
            final createdAt = r.createdAt;
            switch (_selectedFilter) {
              case 'today':
                return createdAt.year == now.year &&
                    createdAt.month == now.month &&
                    createdAt.day == now.day;
              case 'week':
                // Filter untuk 7 hari terakhir
                return now.difference(createdAt).inDays < 7;
              case 'month':
                return createdAt.year == now.year &&
                    createdAt.month == now.month;
              default:
                return true;
            }
          }).toList();
        }

        requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (requests.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return _buildEmptySearchState();
          }
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(requests[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No matching reports',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try with another keyword or clear the search filter',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          TextButton.icon(
            onPressed: _clearSearch,
            icon: Icon(Icons.clear, color: Colors.red),
            label: Text('Clear Search', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    final bool isResourceRequest = request.request == 'resource';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToRequestDetail(request),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isResourceRequest
                              ? Icons.supervisor_account
                              : Icons.inventory,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Need: ${request.request[0].toUpperCase()}${request.request.substring(1)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                        child: const Center(child: CircularProgressIndicator()),
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
                'Request:',
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
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    'By: ${request.employeeName}',
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
                        // Jika selesai: tampilkan tanggal selesai
                        ? 'Completed on: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(request.completionDate!)}'
                        // Jika belum: tampilkan waktu yang lalu
                        : 'Created at: ${_getTimeAgo(request.createdAt)}',
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
                        onPressed: () => _navigateToAssignTechnician(request),
                        icon: const Icon(Icons.engineering, size: 16),
                        label: Text(request.assignedTechnicianId == null
                            ? 'Assign'
                            : 'Change Technician'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCompleteDialog(request),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Complete'),
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
        icon = Icons.engineering;
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
        icon = Icons.engineering;
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

  void _navigateToRequestDetail(RequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailScreenResource(request: request),
      ),
    );
  }

  void _navigateToAssignTechnician(RequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTechnicianScreenResource(request: request),
      ),
    );
  }

  void _showCompleteDialog(RequestModel request) {
    final formKey = GlobalKey<FormState>();
    _completionReasonController.clear();

    showDialog(
      context: context,
      barrierDismissible: !_isCompleting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _isCompleting
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            _completeRequest(request);
                          }
                        },
                  child: _isCompleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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

  Future<void> _completeRequest(RequestModel request) async {
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

    if (currentUser == null) return;

    setState(() => _isCompleting = true);

    try {
      await _firestoreService.completeRequest(
        request.id,
        _completionReasonController.text.trim(),
        technicianId: currentUser!.uid,
        technicianName: currentUser!.name,
      );

      if (mounted) {
        Navigator.pop(context);
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request marked as completed'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing request: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // // Fungsi untuk mendapatkan data rating teknisi (semua aplikasi)
  // Future<Map<String, dynamic>> _getTechnicianRating(String technicianId) async {
  //   try {
  //     return await _firestoreService.getTechnicianRatingData(technicianId);
  //   } catch (e) {
  //     print('Error getting technician rating for $technicianId: $e');
  //     return {'averageRating': 0.0, 'totalRatings': 0};
  //   }
  // }

  // Fungsi untuk mendapatkan data rating teknisi (aplikasi resource)
  Future<Map<String, dynamic>> _getTechnicianRating(String technicianId) async {
    try {
      return await _firestoreService
          .getTechnicianRatingForResourceApp(technicianId);
    } catch (e) {
      print('Error getting technician rating for $technicianId: $e');
      return {'averageRating': 0.0, 'totalRatings': 0};
    }
  }

  void _showTechniciansRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Technician Ratings'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _loadingTechnicians
                ? const Center(child: CircularProgressIndicator())
                : _technicians.isEmpty
                    ? const Center(child: Text('Tidak ada teknisi ditemukan.'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _technicians.length,
                        itemBuilder: (context, index) {
                          final technician = _technicians[index];
                          return _buildTechnicianRatingItem(technician);
                        },
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Widget untuk menampilkan item teknisi dengan ratingnya
  Widget _buildTechnicianRatingItem(UserModel technician) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getTechnicianRating(technician.uid),
      builder: (context, snapshot) {
        double averageRating = 0.0;
        int totalRatings = 0;

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          averageRating =
              (snapshot.data!['averageRating'] as num?)?.toDouble() ?? 0.0;
          totalRatings = (snapshot.data!['totalRatings'] as int?) ?? 0;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.engineering, color: Colors.blue[700], size: 20),
            ),
            title: Text(technician.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text(technician.email, style: const TextStyle(fontSize: 12)),
            trailing: snapshot.connectionState == ConnectionState.waiting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($totalRatings)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
            onTap: () {
              if (snapshot.connectionState == ConnectionState.done) {
                _showTechnicianDetailDialog(
                    technician, averageRating, totalRatings);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.star,
            label: 'Technician Ratings',
            color: Colors.amber,
            onTap: _showTechniciansRatingDialog,
          ),
        ],
      ),
    );
  }

  // Helper untuk tombol Quick Action (buat jika belum ada)
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  // Dialog untuk menampilkan detail teknisi
  void _showTechnicianDetailDialog(
      UserModel technician, double averageRating, int totalRatings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Technician Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.engineering,
                    color: Colors.blue[700],
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  technician.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  technician.email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),

              // Tampilan Peringkat
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRatingColor(averageRating).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getRatingColor(averageRating).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Performance Rating',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRatingColor(averageRating),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < (averageRating).floor()
                                ? Icons.star
                                : index < (averageRating).ceil() &&
                                        (averageRating).floor() !=
                                            (averageRating).ceil()
                                    ? Icons.star_half
                                    : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          );
                        }),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${averageRating.toStringAsFixed(1)} out of 5.0',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getRatingColor(averageRating),
                        ),
                      ),
                      Text(
                        'Based on $totalRatings ${totalRatings == 1 ? "rating" : "ratings"}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (totalRatings > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRatingColor(averageRating),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPerformanceLabel(averageRating),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                'Member Since',
                DateFormat('dd MMM yyyy', 'id_ID').format(technician.createdAt),
                Icons.date_range,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }

  String _getPerformanceLabel(double rating) {
    if (rating >= 4.5) return 'EXCELLENT';
    if (rating >= 4.0) return 'GOOD';
    if (rating >= 3.5) return 'AVERAGE';
    if (rating >= 3.0) return 'FAIR';
    return 'NEEDS IMPROVEMENT';
  }

  String _getExperienceText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'tahun' : 'tahun'}';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'bulan' : 'bulan'}';
    } else {
      return '${difference.inDays} ${difference.inDays == 1 ? 'hari' : 'hari'}';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Filter Berdasarkan Waktu',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout??'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
