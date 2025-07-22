import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/resourceApp/firestore_service.dart';
import '../../../models/resourceApp/request_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';
import 'create_request_screen.dart';
import 'request_detail_screen.dart';

class EmployeeDashboardResource extends StatefulWidget {
  const EmployeeDashboardResource({super.key});

  @override
  State<EmployeeDashboardResource> createState() =>
      _EmployeeDashboardResourceState();
}

class _EmployeeDashboardResourceState extends State<EmployeeDashboardResource>
    with SingleTickerProviderStateMixin {
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();
  UserModel? currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
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
                                        Icons.person,
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
                                  'Kelola permintaan resource Anda',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<List<RequestModel>>(
                                stream: _firestoreService.getRequestsByEmployee(
                                  authService.user!.uid,
                                ),
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
                                      'Belum ada permintaan. Buat permintaan pertama Anda!',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    );
                                  }

                                  return Text(
                                    '${requests.length} all · $open open · $inProgress inProgress',
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
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateRequestScreen(),
                      ),
                    );
                  },
                  tooltip: 'Buat Permintaan',
                ),
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
                    switch (value) {
                      case 'profile':
                        _showProfileDialog();
                        break;
                      case 'logout':
                        _showLogoutDialog();
                        break;
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
                indicatorWeight: 3,
                labelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Open'),
                  Tab(text: 'Progress'),
                  Tab(text: 'Closed'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRequestScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.add_box,
          color: Colors.white,
        ),
        label: const Text('Permintaan Baru',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return StreamBuilder<List<RequestModel>>(
      stream: _firestoreService.getRequestsByEmployee(
        Provider.of<AuthService>(context, listen: false).user!.uid,
      ),
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
                title: 'All',
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
                title: 'InProgress',
                count: inProgress,
                icon: Icons.engineering,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Closed',
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

  // --- WIDGET BARU: TEMPLATE UNTUK SETIAP KARTU STATISTIK ---
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
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<List<RequestModel>>(
      stream: _firestoreService.getRequestsByEmployee(authService.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Memuat permintaan...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error memuat permintaan'),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        List<RequestModel> requests = snapshot.data ?? [];

        if (status != 'all') {
          requests = requests.where((r) => r.status == status).toList();
        }

        requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (requests.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Cukup trigger rebuild, StreamBuilder akan fetch data terbaru
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(requests[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _showRequestDetail(request);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Permintaan: ${request.description}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(request.status),
                ],
              ),
              const SizedBox(height: 12),
              if (request.timeRequired != null &&
                  request.timeRequired!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Waktu: ${request.timeRequired!}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
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
                  request.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
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
                    _getFormattedDate(request.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (request.status == 'inProgress' &&
                  request.technicianName != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.engineering,
                          color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ditugaskan ke: ${request.technicianName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
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

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Kemarin, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  Widget _buildStatusChip(String status) {
    // ... (Fungsi ini tidak perlu diubah, tetap relevan)
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
        text = 'CLOSED';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
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
        message = 'Tidak Ada Permintaan Terbuka';
        description = 'Anda tidak memiliki permintaan resource yang terbuka';
        icon = Icons.pending_actions;
        break;
      case 'inProgress':
        message = 'Tidak Ada Permintaan Sedang Diproses';
        description = 'Tidak ada permintaan Anda yang sedang ditangani';
        icon = Icons.engineering;
        break;
      case 'completed':
        message = 'Tidak Ada Permintaan Selesai';
        description = 'Belum ada permintaan Anda yang telah diselesaikan';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'Belum Ada Permintaan';
        description = 'Buat permintaan resource pertama Anda';
        icon = Icons.assignment_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
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
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateRequestScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Buat Permintaan'),
          ),
        ],
      ),
    );
  }

  void _showRequestDetail(RequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailScreen(request: request),
      ),
    );
  }

  void _showProfileDialog() {
    // ... (Fungsi ini tidak perlu diubah)
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              DateFormat('dd MMM yyyy').format(currentUser!.createdAt),
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
    // ... (Fungsi ini tidak perlu diubah)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    // ... (Fungsi ini tidak perlu diubah)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
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
