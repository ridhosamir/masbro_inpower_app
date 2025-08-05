import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/bookingroomApp/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/bookingroomApp/firestore_service.dart';
import '../../../services/user_service.dart';
import 'create_booking_screen.dart';
import 'booking_detail_screen.dart';

class EmployeeDashboardBookingRoom extends StatefulWidget {
  const EmployeeDashboardBookingRoom({super.key});

  @override
  State<EmployeeDashboardBookingRoom> createState() =>
      _EmployeeDashboardBookingRoomState();
}

class _EmployeeDashboardBookingRoomState
    extends State<EmployeeDashboardBookingRoom>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  UserModel? currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
    _searchController.addListener(_onSearchChanged);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _clearSearch() {
    _searchController.clear();
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
    final authService = Provider.of<AuthService>(context);
    if (authService.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).primaryColor,
              flexibleSpace: _buildHeader(authService.user!.uid),
              actions: [
                _buildPopupMenu(),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Open'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
          ];
        },
        body: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildStatisticsCards(authService.user!.uid),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchAndFilter(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(authService.user!.uid, 'all'),
                  _buildBookingsList(authService.user!.uid, 'open'),
                  _buildBookingsList(authService.user!.uid, 'approved'),
                  _buildBookingsList(authService.user!.uid, 'cancelled'),
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
                builder: (context) => const CreateBookingScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Booking Baru', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  String _formatBookingDuration(DateTime start, DateTime end) {
    // Cek apakah booking dalam satu hari yang sama
    final isSingleDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (isSingleDay) {
      // Format untuk booking harian: Senin, 28 Jul 2025, 09:00 - 11:30
      final date = DateFormat('E, d MMM yyyy', 'id_ID').format(start);
      final startTime = DateFormat('HH:mm').format(start);
      final endTime = DateFormat('HH:mm').format(end);
      return '$date, $startTime - $endTime';
    } else {
      // Format untuk booking beberapa hari: Senin, 28 Jul 2025 s/d Rabu, 30 Jul 2025
      final startDate = DateFormat('E, d MMM yyyy', 'id_ID').format(start);
      final endDate = DateFormat('E, d MMM yyyy', 'id_ID').format(end);
      return '$startDate s/d $endDate';
    }
  }

  // UI Widgets

  Widget _buildHeader(String uid) {
    return FlexibleSpaceBar(
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentUser != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentUser!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Kelola pemesanan ruangan Anda',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<BookingModel>>(
                      stream: _firestoreService.getBookingsByEmployee(uid),
                      builder: (context, snapshot) {
                        final bookings = snapshot.data ?? [];
                        final pending =
                            bookings.where((b) => b.status == 'open').length;
                        final approved = bookings
                            .where((b) => b.status == 'approved')
                            .length;
                        return Text(
                          '${bookings.length} total · $pending pending · $approved approved',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12),
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
    );
  }

  Widget _buildStatisticsCards(String uid) {
    return StreamBuilder<List<BookingModel>>(
      stream: _firestoreService.getBookingsByEmployee(uid),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final pending = bookings.where((b) => b.status == 'open').length;
        final approved = bookings.where((b) => b.status == 'approved').length;
        final cancelled = bookings.where((b) => b.status == 'cancelled').length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: _buildStatCard(
                    title: 'All',
                    count: bookings.length,
                    icon: Icons.collections_bookmark,
                    color: Colors.blue)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatCard(
                    title: 'Open',
                    count: pending,
                    icon: Icons.pending,
                    color: Colors.orange)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatCard(
                    title: 'Approved',
                    count: approved,
                    icon: Icons.check_circle,
                    color: Colors.green)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatCard(
                    title: 'Cancelled',
                    count: cancelled,
                    icon: Icons.cancel,
                    color: Colors.red)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      {required String title,
      required int count,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari agenda atau ruangan...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
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
          ),
          child: IconButton(
            onPressed: _showFilterDialog,
            icon:
                Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
            tooltip: 'Filter Waktu',
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(String uid, String status) {
    return StreamBuilder<List<BookingModel>>(
      stream: _firestoreService.getBookingsByEmployee(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<BookingModel> bookings = snapshot.data ?? [];

        // Filter by Tab status
        if (status != 'all') {
          bookings = bookings.where((b) => b.status == status).toList();
        }

        // Filter by Search Query
        if (_searchQuery.isNotEmpty) {
          bookings = bookings.where((b) {
            final query = _searchQuery.toLowerCase();
            return b.eventAgenda.toLowerCase().contains(query) ||
                b.roomName.toLowerCase().contains(query);
          }).toList();
        }

        // Filter by Time (today, week, month)
        if (_selectedFilter != 'all') {
          final now = DateTime.now();
          bookings = bookings.where((b) {
            final createdAt = b.createdAt;
            switch (_selectedFilter) {
              case 'today':
                return createdAt.year == now.year &&
                    createdAt.month == now.month &&
                    createdAt.day == now.day;
              case 'week':
                return now.difference(createdAt).inDays < 7;
              case 'month':
                return createdAt.year == now.year &&
                    createdAt.month == now.month;
              default:
                return true;
            }
          }).toList();
        }

        bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (bookings.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return _buildEmptySearchState();
          }
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _buildBookingCard(bookings[index]);
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
            'Tidak ada laporan yang cocok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coba dengan kata kunci lain atau hapus filter pencarian',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          TextButton.icon(
            onPressed: _clearSearch,
            icon: Icon(Icons.clear, color: Colors.blue),
            label:
                Text('Hapus Pencarian', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BookingDetailScreen(booking: booking)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Ruangan: ${booking.roomName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  booking.eventAgenda,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Waktu: ${_formatBookingDuration(booking.usageStartDate, booking.usageEndDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    booking.status == 'approved' &&
                            booking.completionDate != null
                        ? 'Disetujui: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(booking.completionDate!)}'
                        : booking.status == 'cancelled' &&
                                booking.completionDate != null
                            ? 'Dibatalkan: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(booking.completionDate!)}'
                            : 'Dibuat: ${_getTimeAgo(booking.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: booking.status == 'approved'
                          ? Colors.green[800]
                          : booking.status == 'cancelled'
                              ? Colors.red[800]
                              : Colors.grey[600],
                      fontWeight: booking.status == 'open'
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
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
      case 'approved':
        color = Colors.green;
        text = 'APPROVED';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'CANCELLED';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
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

  // Dialogs & Popups

  PopupMenuButton<String> _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
      ),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'profile') _showProfileDialog();
        if (value == 'logout') _showLogoutDialog();
        if (value == 'back') Navigator.of(context).pop();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(leading: Icon(Icons.person), title: Text('Profil')),
        ),
        PopupMenuItem(
          value: 'back',
          child: ListTile(
              leading: Icon(Icons.arrow_back, color: Colors.blueGrey),
              title: Text('Back to Home',
                  style: TextStyle(color: Colors.blueGrey))),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Keluar', style: TextStyle(color: Colors.red))),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    String description;
    IconData icon;

    switch (status) {
      case 'open':
        message = 'Tidak Ada Pemesanan Ruangan';
        description = 'Anda tidak memiliki pemesanan ruangan yang terbuka';
        icon = Icons.pending_actions;
        break;
      case 'approved':
        message = 'Tidak Ada Pemesanan Yang Disetujui';
        description = 'Tidak ada pemesanan Anda yang disetujui';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        message = 'Tidak Ada Pemesanan Yang Dibatalkan';
        description = 'Tidak ada pemesanan Anda yang dibatalkan';
        icon = Icons.cancel;
        break;
      default:
        message = 'Belum Ada Pemesanan';
        description = 'Buat Pemesanan Ruangan pertama Anda';
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
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateBookingScreen(),
                ),
              );
            },
            icon: Icon(Icons.add),
            label: Text('Create Booking'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Berdasarkan Waktu',
            style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Semua'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Hari Ini'),
              value: 'today',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Minggu Ini'),
              value: 'week',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Bulan Ini'),
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
        title: const Text('Informasi Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('Nama', currentUser!.name),
            _buildProfileItem('Email', currentUser!.email),
            _buildProfileItem('Peran', currentUser!.role.toUpperCase()),
            _buildProfileItem('Anggota Sejak',
                DateFormat('dd MMM yyyy').format(currentUser!.createdAt)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
