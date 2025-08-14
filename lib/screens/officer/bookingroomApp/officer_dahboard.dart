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
      {DateTime? firstDate, String? errorText}) {
    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: value ?? firstDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime(2035),
        );
        if (pickedDate != null) onPicked(pickedDate);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          errorText: errorText,
          helperText: errorText == null ? ' ' : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value == null
                ? 'Select Date'
                : DateFormat('EEEE, d MMM yyyy', 'id_ID').format(value)),
            const Icon(Icons.calendar_month),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, TimeOfDay? value,
      Function(TimeOfDay?) onPicked,
      {TimeOfDay? startTimeFilter, DateTime? selectedDate}) {
    List<TimeOfDay> times = List.generate(48, (index) {
      final hour = index ~/ 2;
      final minute = (index % 2) * 30;
      return TimeOfDay(hour: hour, minute: minute);
    });

    if (label == 'Start Time' && selectedDate != null) {
      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      if (isToday) {
        final nowInMinutes = now.hour * 60 + now.minute;
        times = times.where((time) {
          final timeInMinutes = time.hour * 60 + time.minute;
          return timeInMinutes >= nowInMinutes;
        }).toList();

        if (value != null && !times.contains(value)) {
          value = null;
        }
      }
    }

    if (startTimeFilter != null) {
      final startTimeInMinutes =
          startTimeFilter.hour * 60 + startTimeFilter.minute;
      times = times.where((time) {
        final currentTimeInMinutes = time.hour * 60 + time.minute;
        return currentTimeInMinutes > startTimeInMinutes;
      }).toList();

      if (value != null && !times.contains(value)) {
        value = null;
      }
    }

    return DropdownButtonFormField<TimeOfDay>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        helperText: ' ',
      ),
      menuMaxHeight: 200,
      hint: times.isEmpty ? const Text('Select Start Time') : null,
      items: times.map((time) {
        return DropdownMenuItem<TimeOfDay>(
          value: time,
          child: Text(time.format(context)),
        );
      }).toList(),
      onChanged: (newValue) {
        onPicked(newValue);
      },
      validator: (val) {
        if (val == null) {
          return 'Required fields';
        }

        if (selectedDate != null) {
          final now = DateTime.now();
          final isToday = selectedDate.year == now.year &&
              selectedDate.month == now.month &&
              selectedDate.day == now.day;

          if (isToday) {
            final selectedTimeInMinutes = val.hour * 60 + val.minute;
            final nowInMinutes = now.hour * 60 + now.minute;

            if (selectedTimeInMinutes < nowInMinutes) {
              return 'The selected time has passed';
            }
          }
        }
        return null;
      },
    );
  }

  // Method untuk menentukan warna berdasarkan nilai rating
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.amber;
    if (rating >= 4.0) return Colors.amber[600]!;
    if (rating >= 3.5) return Colors.orange[700]!;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }

  // Method untuk menentukan label teks berdasarkan nilai rating
  String _getRatingLabel(double rating) {
    if (rating >= 4.5) return 'VERY GOOD';
    if (rating >= 4.0) return 'GOOD';
    if (rating >= 3.5) return 'ENOUGH';
    if (rating >= 3.0) return 'NOT ENOUGH';
    return 'NEEDS IMPROVEMENT';
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
                      'Manage and approve room bookings',
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
                            'There are no bookings to review yet',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          );
                        }
                        return Text(
                          '${bookings.length} total booking · $pending need approval · $approved approved',
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
                    'Room Management',
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
            'No matching orders found',
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
                            'Room: ${booking.roomName}',
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
                'Event Agenda:',
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
                  Icons.person_outline, 'by: ${booking.employeeName}'),
              const SizedBox(height: 6),
              _buildInfoRow(
                  Icons.calendar_today_outlined,
                  _formatDateRange(
                      booking.usageStartDate, booking.usageEndDate)),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.access_time,
                  'Created: ${_getTimeAgo(booking.createdAt)}'),
              if (booking.rating != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRatingColor(booking.rating!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getRatingColor(booking.rating!).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: _getRatingColor(booking.rating!),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rating: ${booking.rating!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              _getRatingColor(booking.rating!).withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRatingColor(booking.rating!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getRatingLabel(booking.rating!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (booking.status == 'open') ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showManageBookingSheet(booking),
                        icon:
                            const Icon(Icons.edit_calendar_outlined, size: 16),
                        label: const Text('Manage Booking'),
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
                        label: const Text('Reject Booking'),
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
                        label: const Text('Update Schedule'),
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
              hintText: 'Search agenda, room, name...',
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
            tooltip: 'Time Filter',
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

    // State untuk tipe booking & waktu (sekarang nullable)
    BookingType bookingType =
        DateUtils.isSameDay(booking.usageStartDate, booking.usageEndDate)
            ? BookingType.harian
            : BookingType.beberapaHari;

    // State untuk durasi Harian
    DateTime? selectedDate = booking.usageStartDate;
    TimeOfDay? startTime = TimeOfDay.fromDateTime(booking.usageStartDate);
    TimeOfDay? endTime = TimeOfDay.fromDateTime(booking.usageEndDate);

    // State untuk durasi Beberapa Hari
    DateTime? startDateMulti = booking.usageStartDate;
    DateTime? endDateMulti =
        DateUtils.isSameDay(booking.usageStartDate, booking.usageEndDate)
            ? null
            : booking.usageEndDate;

    // Variabel untuk menandai jika jadwal sudah lewat
    bool isOutdated = false;

    // --- Logika untuk mereset tanggal yang sudah lewat ---
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (booking.usageStartDate.isBefore(today)) {
      isOutdated = true;
      selectedDate = null;
      startTime = null;
      endTime = null;
      startDateMulti = null;
      endDateMulti = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String? selectedRoomId =
            booking.roomName == 'Not specified' ? null : booking.roomId;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> handleFinalApproval() async {
              if (!formKey.currentState!.validate()) return;
              DateTime finalStartDate;
              DateTime finalEndDate;

              if (bookingType == BookingType.harian) {
                finalStartDate = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    startTime!.hour,
                    startTime!.minute);
                finalEndDate = DateTime(selectedDate!.year, selectedDate!.month,
                    selectedDate!.day, endTime!.hour, endTime!.minute);
              } else {
                finalStartDate = startDateMulti!;
                finalEndDate = endDateMulti!;
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
                            Text('Schedule Conflict!'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unable to approve booking due to schedule conflict with other approved agenda:',
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
                                                      'View Details',
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
                                            '  Orderer: ${conflictBooking.employeeName}',
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
                              'Please select another schedule or room.',
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
                    title: const Text('Confirmation of Approval'),
                    content: const Text(
                        'Are you sure you want to accept this booking?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Yes, agree',
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
                  content: Text('Booking successfully approved.'),
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
                      content: Text('There is an error: ${e.toString()}'),
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
                required Function(TimeOfDay?) onStartTimeChanged,
                required Function(TimeOfDay?) onEndTimeChanged}) {
              return Column(
                children: [
                  FormField<DateTime>(
                    initialValue: currentDate,
                    validator: (value) {
                      if (value == null) {
                        return 'Event date is required';
                      }
                      return null;
                    },
                    builder: (FormFieldState<DateTime> state) {
                      return _buildDatePicker(
                          context, 'Select Event Date', state.value, (date) {
                        setState(() {
                          onDateChanged(date);
                          state.didChange(date);
                          final now = DateTime.now();
                          final isToday = date.year == now.year &&
                              date.month == now.month &&
                              date.day == now.day;

                          // Logika tambahan untuk reset jam mulai jika sudah lewat
                          if (isToday && currentTime != null) {
                            final nowInMinutes = now.hour * 60 + now.minute;
                            final startTimeInMinutes =
                                currentTime.hour * 60 + currentTime.minute;
                            if (startTimeInMinutes < nowInMinutes) {
                              // Jika jam mulai yang dipilih sudah lewat, reset keduanya
                              onStartTimeChanged(null);
                              onEndTimeChanged(null);
                            }
                          }
                          // Logika tambahan untuk reset jam selesai jika sudah lewat
                          if (isToday && endTime != null) {
                            final nowInMinutes = now.hour * 60 + now.minute;
                            final endTimeInMinutes =
                                endTime.hour * 60 + endTime.minute;
                            if (endTimeInMinutes < nowInMinutes) {
                              onEndTimeChanged(null);
                            }
                          }
                        });
                      }, errorText: state.errorText);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTimePicker(
                              context, 'Start Time', currentTime,
                              (newStartTime) {
                        setState(() {
                          onStartTimeChanged(newStartTime);
                          // Reset end time if it's before new start time
                          if (newStartTime != null) {
                            // Jika jam selesai lebih awal dari jam mulai baru, kosongkan jam selesai
                            if (endTime != null &&
                                (endTime.hour * 60 + endTime.minute) <=
                                    (newStartTime.hour * 60 +
                                        newStartTime.minute)) {
                              onEndTimeChanged(null);
                            }
                          } else {
                            // Jika jam mulai dikosongkan, jam selesai juga harus kosong
                            onEndTimeChanged(null);
                          }
                        });
                      }, selectedDate: currentDate)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTimePicker(context, 'End Time', endTime,
                              (newEndTime) {
                        setState(() => onEndTimeChanged(newEndTime));
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
                required Function(DateTime?) onEndDateChanged}) {
              return Column(
                children: [
                  FormField<DateTime>(
                    initialValue: currentStartDate,
                    validator: (value) {
                      if (value == null) {
                        return 'Start date is required';
                      }
                      if (currentEndDate != null &&
                          (value.isAfter(currentEndDate) ||
                              DateUtils.isSameDay(value, currentEndDate))) {
                        return 'Start date must be before event end date!';
                      }
                      return null;
                    },
                    builder: (FormFieldState<DateTime> state) {
                      return _buildDatePicker(
                          context, 'Start Date', state.value, (date) {
                        setState(() {
                          onStartDateChanged(date);
                          state.didChange(date);
                        });
                      }, errorText: state.errorText);
                    },
                  ),
                  const SizedBox(height: 16),
                  FormField<DateTime>(
                    key: ValueKey(currentEndDate),
                    initialValue: currentEndDate,
                    validator: (value) {
                      if (value == null) {
                        return 'The end date is required';
                      }
                      return null;
                    },
                    builder: (FormFieldState<DateTime> state) {
                      return _buildDatePicker(context, 'End Date', state.value,
                          (date) {
                        setState(() {
                          onEndDateChanged(date);
                          state.didChange(date);
                        });
                      },
                          firstDate:
                              currentStartDate?.add(const Duration(days: 1)) ??
                                  DateTime.now().add(const Duration(days: 1)),
                          errorText: state.errorText);
                    },
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
                          const Text('Manage Booking',
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
                                        'Event Agenda', booking.eventAgenda),
                                    _buildDetailItem(
                                        Icons.local_activity_outlined,
                                        'Activity Type',
                                        booking.activityType),
                                    _buildDetailItem(Icons.person_outline,
                                        'Booker', booking.employeeName),
                                    _buildDetailItem(Icons.add_box_outlined,
                                        'Needs', booking.needs),
                                    _buildDetailItem(
                                        Icons.groups_3_outlined,
                                        'Number of Participants',
                                        booking.numberOfParticipants
                                            .toString()),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // --- Form Edit ---
                              _buildSectionTitle('Room Configuration & Time'),
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
                                        'Error: No rooms available.');
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
                                      labelText: 'Select Room',
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
                                                    'Capacity: ${room.capacity} people',
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
                                        ? 'A room must be selected'
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Peringatan jika jadwal sudah lewat
                              if (isOutdated) ...[
                                const SizedBox(height: 12),
                                _buildWarningBox(
                                    'The schedule has passed, please re-enter.'),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 16),

                              // Input Waktu Baru
                              SegmentedButton<BookingType>(
                                segments: const <ButtonSegment<BookingType>>[
                                  ButtonSegment(
                                      value: BookingType.harian,
                                      label: Text('One-Day'),
                                      icon: Icon(Icons.access_time)),
                                  ButtonSegment(
                                      value: BookingType.beberapaHari,
                                      label: Text('Multi-Day'),
                                      icon: Icon(Icons.date_range)),
                                ],
                                selected: <BookingType>{bookingType},
                                onSelectionChanged:
                                    (Set<BookingType> newSelection) {
                                  setModalState(() {
                                    final newType = newSelection.first;
                                    if (newType == bookingType) return;

                                    final oldType = bookingType;
                                    bookingType = newType;

                                    // Logic perpindahan dari Beberapa Hari ke Harian
                                    if (oldType == BookingType.beberapaHari &&
                                        newType == BookingType.harian &&
                                        startDateMulti != null) {
                                      selectedDate = startDateMulti;

                                      // Cek apakah tanggal sudah kadaluarsa
                                      final now = DateTime.now();
                                      final today = DateTime(
                                          now.year, now.month, now.day);

                                      if (selectedDate!.isBefore(today)) {
                                        // Jika sudah kadaluarsa, reset semua
                                        selectedDate = null;
                                        startTime = null;
                                        endTime = null;
                                      } else {
                                        // Cek apakah booking asli adalah harian atau multi-day
                                        if (DateUtils.isSameDay(
                                            booking.usageStartDate,
                                            booking.usageEndDate)) {
                                          // Jika booking asli adalah harian, kembalikan jam dari booking asli
                                          startTime = TimeOfDay.fromDateTime(
                                              booking.usageStartDate);
                                          endTime = TimeOfDay.fromDateTime(
                                              booking.usageEndDate);
                                        } else {
                                          // Jika booking asli adalah multi-day, kosongkan jam
                                          startTime = null;
                                          endTime = null;
                                        }
                                      }
                                    }
                                    // Logic perpindahan dari Harian ke Beberapa Hari
                                    else if (oldType == BookingType.harian &&
                                        newType == BookingType.beberapaHari &&
                                        selectedDate != null) {
                                      startDateMulti = selectedDate;

                                      // Kembalikan endDateMulti jika sebelumnya ada data _buildMultiDayInputs
                                      if (DateUtils.isSameDay(
                                          booking.usageStartDate,
                                          booking.usageEndDate)) {
                                        // Jika booking asli adalah harian, kosongkan endDateMulti
                                        endDateMulti = null;
                                      } else {
                                        // Jika booking asli adalah multi-day, kembalikan data endDateMulti
                                        endDateMulti = booking.usageEndDate;
                                      }

                                      // Cek apakah tanggal sudah kadaluarsa
                                      final now = DateTime.now();
                                      final today = DateTime(
                                          now.year, now.month, now.day);

                                      if (startDateMulti!.isBefore(today)) {
                                        // Jika sudah kadaluarsa, reset semua
                                        startDateMulti = null;
                                        endDateMulti = null;
                                      }
                                    }
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
                                  onStartDateChanged: (d) {
                                    startDateMulti = d;
                                    if (endDateMulti != null &&
                                        (d.isAfter(endDateMulti!) ||
                                            DateUtils.isSameDay(
                                                d, endDateMulti!))) {
                                      endDateMulti = null;
                                    }
                                  },
                                  onEndDateChanged: (d) => endDateMulti = d,
                                ),

                              const SizedBox(height: 24),
                              _buildSectionTitle('Additional Notes (Optional)'),
                              CustomTextField(
                                labelText: 'Additional Notes',
                                hintText: 'Add a note for the room orderer...',
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
                              label: const Text('Cancel'),
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
                              label: const Text('Approve'),
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
        title: const Text('Reject Booking'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _rejectionReasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for Rejection',
              hintText: 'Please provide a reason for rejecting the booking',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Reason cannot be empty';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _firestoreService.updateBookingStatus(
                  booking.id,
                  'cancelled',
                  reason: 'Rejected: ${_rejectionReasonController.text.trim()}',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Booking successfully rejected.'),
                  backgroundColor: Colors.orange,
                ));
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
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
        // if (value == 'logout') _showLogoutDialog();
        if (value == 'back') Navigator.of(context).pop();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 25, 115, 184).withOpacity(0.1),
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
          value: 'back',
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.blueGrey[600],
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Back to Home',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey[600],
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
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
        message = 'No Room Bookings Open';
        description = 'You have no open room bookings';
        icon = Icons.pending_actions;
        break;
      case 'approved':
        message = 'No Approved Bookings';
        description = 'No room bookings approved';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        message = 'No Cancelled Bookings';
        description = 'No room bookings canceled';
        icon = Icons.cancel;
        break;
      default:
        message = 'No Room Booking Yet';
        description = 'The employee has not yet submitted their room booking';
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
        title: const Text('Filter By Time', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Today'),
              value: 'today',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('This Week'),
              value: 'week',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('This Month'),
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

  // Widget baru untuk menampilkan pesan peringatan
  Widget _buildWarningBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Colors.red[700],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
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
