import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import '../../../models/bookingroomApp/booking_model.dart';
import '../../../models/bookingroomApp/room_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/bookingroomApp/firestore_service.dart';
import '../../../services/user_service.dart';
import 'booking_detail_screen.dart';
import 'room_manage_screen.dart';

enum BookingType { harian, beberapaHari }

class OfficerDashboardBookingRoom extends StatefulWidget {
  const OfficerDashboardBookingRoom({super.key});

  @override
  State<OfficerDashboardBookingRoom> createState() =>
      _OfficerDashboardBookingRoomState();
}

class _OfficerDashboardBookingRoomState
    extends State<OfficerDashboardBookingRoom> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  final _rejectionReasonController = TextEditingController();
  UserModel? currentUser;
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
    _searchController.addListener(_onSearchChanged);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
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

  @override
  Widget build(BuildContext context) {
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
              flexibleSpace: _buildHeader(),
              actions: [_buildPopupMenu(), const SizedBox(width: 8)],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
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
              child: Column(
                children: [
                  _buildStatisticsCards(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchAndFilter(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList('all'),
                  _buildBookingsList('open'),
                  _buildBookingsList('approved'),
                  _buildBookingsList('cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets Utama --- //

  Widget _buildHeader() {
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
                          child: const Icon(Icons.supervisor_account,
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
                              Text(
                                currentUser!.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
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
                      'Kelola dan setujui pemesanan ruangan',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<BookingModel>>(
                      stream: _firestoreService.getBookings(),
                      builder: (context, snapshot) {
                        final bookings = snapshot.data ?? [];
                        final pending =
                            bookings.where((b) => b.status == 'open').length;
                        final approved = bookings
                            .where((b) => b.status == 'approved')
                            .length;
                        if (bookings.isEmpty) {
                          return Text(
                            'Belum ada pemesanan untuk ditinjau',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          );
                        }
                        return Text(
                          '${bookings.length} total pemesanan · $pending perlu persetujuan · $approved disetujui',
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

  Widget _buildStatisticsCards() {
    return StreamBuilder<List<BookingModel>>(
      stream: _firestoreService.getBookings(),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final pending = bookings.where((b) => b.status == 'open').length;
        final approved = bookings.where((b) => b.status == 'approved').length;
        final cancelled = bookings.where((b) => b.status == 'cancelled').length;

        return Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    title: 'All Bookings',
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage Room',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RoomBookingManagementScreen()));
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.meeting_room, color: Colors.purple, size: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Manajemen Ruangan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.purple, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(String status) {
    return StreamBuilder<List<BookingModel>>(
      stream: _firestoreService.getBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        var bookings = snapshot.data ?? [];
        if (status != 'all') {
          bookings = bookings.where((b) => b.status == status).toList();
        }

        if (_searchQuery.isNotEmpty) {
          bookings = bookings.where((b) {
            final query = _searchQuery.toLowerCase();
            return b.eventAgenda.toLowerCase().contains(query) ||
                b.roomName.toLowerCase().contains(query) ||
                b.employeeName.toLowerCase().contains(query);
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

        bookings.sort((a, b) {
          if (a.status == 'approved' && b.status == 'approved') {
            if (a.completionDate != null && b.completionDate != null) {
              return b.completionDate!.compareTo(a.completionDate!);
            }
          }
          if (a.status == 'cancelled' && b.status == 'cancelled') {
            if (a.completionDate != null && b.completionDate != null) {
              return b.completionDate!.compareTo(a.completionDate!);
            }
          }
          return b.createdAt.compareTo(a.createdAt);
        });

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
            itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailScreen(booking: booking),
          ),
        ),
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
                          Icons.meeting_room_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Ruangan: ${booking.roomName}',
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
              _buildInfoRow(
                  Icons.person_outline, 'Oleh: ${booking.employeeName}'),
              const SizedBox(height: 6),
              _buildInfoRow(
                  Icons.calendar_today_outlined,
                  _formatDateRange(
                      booking.usageStartDate, booking.usageEndDate)),
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
                        icon:
                            const Icon(Icons.edit_calendar_outlined, size: 16),
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
              if (booking.status == 'approved' &&
                  DateTime.now().isBefore(booking.usageEndDate)) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showManageBookingSheet(booking),
                        icon: const Icon(Icons.edit_note_outlined, size: 16),
                        label: const Text('Edit Jadwal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
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
    );
  }

  // --- Widgets Pendukung --- //

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
                offset: const Offset(0, 2))
          ]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(count.toString(),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center),
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
              hintText: 'Cari agenda, ruangan, nama...',
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
                  borderSide: BorderSide.none),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final (color, text, icon) = switch (status) {
      'open' => (Colors.orange, 'OPEN', Icons.pending),
      'approved' => (Colors.green, 'APPROVED', Icons.check_circle),
      'cancelled' => (Colors.red, 'CANCELLED', Icons.cancel),
      _ => (Colors.grey, status.toUpperCase(), Icons.help),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
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

  // --- Aksi & Dialog --- //

  void _showManageBookingSheet(BookingModel booking) {
    final formKey = GlobalKey<FormState>();

    // State untuk UI
    RoomModel? selectedRoom;
    final notesController =
        TextEditingController(text: booking.completionReason);

    // State untuk tipe booking & waktu (diadaptasi dari create_booking_screen.dart)
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

            // Widget builder untuk input waktu (diadaptasi dari create_booking_screen)
            Widget _buildSingleDayInputs(
                BuildContext context,
                StateSetter setState,
                DateTime? currentDate,
                TimeOfDay? currentTime,
                TimeOfDay? endTime,
                {required Function(DateTime) onDateChanged,
                required Function(TimeOfDay) onStartTimeChanged,
                required Function(TimeOfDay) onEndTimeChanged}) {
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
                              context, 'Jam Mulai', currentTime, (time) {
                        setState(() {
                          onStartTimeChanged(time);
                          // Reset end time if it's before new start time
                          if (endTime != null &&
                              (endTime.hour * 60 + endTime.minute) <=
                                  (time.hour * 60 + time.minute)) {
                            onEndTimeChanged(TimeOfDay(
                                hour: time.hour + 1, minute: time.minute));
                          }
                        });
                      })),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTimePicker(
                              context, 'Jam Selesai', endTime, (time) {
                        setState(() => onEndTimeChanged(time));
                      }, startTimeFilter: currentTime)),
                    ],
                  )
                ],
              );
            }

            Widget _buildMultiDayInputs(
                BuildContext context,
                StateSetter setState,
                DateTime? currentStartDate,
                DateTime? currentEndDate,
                {required Function(DateTime) onStartDateChanged,
                required Function(DateTime) onEndDateChanged}) {
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
                  _buildDatePicker(context, 'Tanggal Selesai', currentEndDate,
                      (date) {
                    setState(() => onEndDateChanged(date));
                  }, firstDate: currentStartDate),
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    // Header
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
                    // Content
                    Expanded(
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Box info statis
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
                                          .withOpacity(0.2)),
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
                                    _buildDetailItem(
                                        Icons.groups_3_outlined,
                                        'Jumlah Peserta',
                                        booking.numberOfParticipants
                                            .toString()),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // --- Form Edit ---
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

                                  // Inisialisasi 'selectedRoom' jika belum ada
                                  if (selectedRoomId != null &&
                                      selectedRoom == null) {
                                    try {
                                      selectedRoom = rooms.firstWhere(
                                          (r) => r.id == selectedRoomId);
                                    } catch (e) {
                                      // Handle jika room yang tersimpan sudah dihapus
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

                              // Input Waktu Baru
                              SegmentedButton<BookingType>(
                                segments: const <ButtonSegment<BookingType>>[
                                  ButtonSegment(
                                      value: BookingType.harian,
                                      label: Text('Harian'),
                                      icon: Icon(Icons.access_time)),
                                  ButtonSegment(
                                      value: BookingType.beberapaHari,
                                      label: Text('Beberapa Hari'),
                                      icon: Icon(Icons.date_range)),
                                ],
                                selected: <BookingType>{bookingType},
                                onSelectionChanged:
                                    (Set<BookingType> newSelection) =>
                                        setModalState(() =>
                                            bookingType = newSelection.first),
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
                              CustomTextField(
                                labelText: 'Catatan Tambahan',
                                hintText: 'Tambahkan catatan untuk pemesan...',
                                controller: notesController,
                                maxLines: 3,
                                prefixIcon: Icons.note_alt_outlined,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Footer Buttons
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
                                  foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
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
    _rejectionReasonController.clear();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Booking'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _rejectionReasonController,
            decoration: const InputDecoration(
              labelText: 'Alasan Penolakan',
              hintText: 'Berikan alasan penolakan booking',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _firestoreService.updateBookingStatus(
                  booking.id,
                  'cancelled',
                  reason: 'Ditolak: ${_rejectionReasonController.text.trim()}',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Booking berhasil ditolak.'),
                  backgroundColor: Colors.orange,
                ));
              }
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  PopupMenuButton<String> _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
      ),
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
          child: const ListTile(
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
