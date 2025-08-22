import 'dart:async';
import 'dart:ui';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/services/statusNotifications/notif_status_helper.dart';
import 'package:masbro_inpower_app/models/maintenanceApp/report_model.dart';
import 'package:masbro_inpower_app/models/operasionalApp/driver_model.dart';
import 'package:masbro_inpower_app/models/operasionalApp/vehicle_model.dart';
import 'package:masbro_inpower_app/models/resourceApp/request_model.dart';
import 'package:masbro_inpower_app/models/operasionalApp/ride_request_model.dart';
import 'package:masbro_inpower_app/models/bookingroomApp/booking_model.dart';
import 'package:masbro_inpower_app/models/bookingroomApp/room_model.dart';
import 'package:masbro_inpower_app/models/user_model.dart';
import 'package:masbro_inpower_app/screens/employee/maintenanceApp/report_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/operasionalApp/ride_request_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/resourceApp/request_detail_screen.dart';
import 'package:masbro_inpower_app/screens/homeDashboard/detailRating/rating_detail_screen.dart';
import 'package:masbro_inpower_app/screens/officer/bookingroomApp/booking_detail_screen.dart';
import 'package:masbro_inpower_app/screens/officer/bookingroomApp/officer_dahboard.dart';
import 'package:masbro_inpower_app/screens/officer/maintenanceApp/assign_technician_screen.dart';
import 'package:masbro_inpower_app/screens/officer/maintenanceApp/officer_dashboard.dart';
import 'package:masbro_inpower_app/screens/officer/operasionalApp/assign_driver_vehicle_screen.dart';
import 'package:masbro_inpower_app/screens/officer/operasionalApp/officer_dashboard.dart';
import 'package:masbro_inpower_app/screens/officer/resourceApp/assign_technician_screen.dart';
import 'package:masbro_inpower_app/screens/officer/resourceApp/officer_dashboard.dart';
import 'package:masbro_inpower_app/screens/officer/resourceApp/request_detail_screen.dart';
import 'package:masbro_inpower_app/services/auth_service.dart';
import 'package:masbro_inpower_app/services/maintenanceApp/firestore_service.dart'
    as maintenance_service;
import 'package:masbro_inpower_app/services/resourceApp/firestore_service.dart'
    as resource_service;
import 'package:masbro_inpower_app/services/operasionalApp/firestore_service.dart'
    as operasional_service;
import 'package:masbro_inpower_app/services/bookingroomApp/firestore_service.dart'
    as booking_service;
import 'package:masbro_inpower_app/screens/homeDashboard/list_notifications.dart';
import 'package:masbro_inpower_app/services/notification_list_service.dart';
import 'package:badges/badges.dart' as badges;
import 'package:masbro_inpower_app/services/user_service.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import 'package:provider/provider.dart';

enum BookingType { harian, beberapaHari }

class HomeDashboardOfficer extends StatefulWidget {
  const HomeDashboardOfficer({super.key});

  @override
  State<HomeDashboardOfficer> createState() => _HomeDashboardOfficerState();
}

class _HomeDashboardOfficerState extends State<HomeDashboardOfficer>
    with SingleTickerProviderStateMixin {
  UserModel? currentUser;
  final _searchController = TextEditingController();
  final _rejectionReasonController = TextEditingController();
  late TabController _tabController;
  late booking_service.FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _firestoreService = booking_service.FirestoreService();
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

        if (currentUser != null) {
          // Inisialisasi notifikasi dan simpan/update FCM token ke Firestore
          final notificationService =
              Provider.of<NotificationService>(context, listen: false);
          notificationService.initNotifications(currentUser!.uid);
        }
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
              length: 3,
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      backgroundColor: const Color(0xFF0277BD),
                      expandedHeight: 360.0,
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
                                    'Dashboard Officer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                _buildProfileButton(),
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
                          Tab(icon: Icon(Icons.update)),
                          Tab(icon: Icon(Icons.apps)),
                          Tab(icon: Icon(Icons.star_rate)),
                        ],
                      ),
                    )
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    OfficerStatusTab(currentUser: currentUser!),
                    _buildAppGrid(context),
                    const OfficerRatingTab(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileButton() {
    final notificationListService =
        Provider.of<NotificationListService>(context, listen: false);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<int>(
          stream: notificationListService.getUnreadCountStream(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return badges.Badge(
              position: badges.BadgePosition.topEnd(top: -4, end: -4),
              showBadge: unreadCount > 0,
              badgeContent: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationListScreen(),
                      ),
                    );
                  },
                  tooltip: 'Notifications',
                ),
              ),
            );
          },
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 25, 115, 184), // SAMA DENGAN USER: Darker blue
            Color(0xFF0288D1), // SAMA DENGAN USER: Material blue
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0], // SAMA DENGAN USER
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ELEMEN DEKORATIF LINGKARAN - SAMA DENGAN USER
          Positioned(
            right: -60, // SAMA dengan User
            top: -30, // SAMA dengan User
            child: Container(
              width: 220, // SAMA dengan User
              height: 220, // SAMA dengan User
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
            left: -80, // SAMA dengan User
            bottom: -40, // SAMA dengan User
            child: Container(
              width: 180, // SAMA dengan User
              height: 180, // SAMA dengan User
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  Colors.white.withOpacity(0.07),
                  Colors.white.withOpacity(0.03),
                  Colors.transparent,
                ]),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40, // SAMA dengan User
            bottom: 100, // SAMA dengan User
            child: Container(
              width: 40, // SAMA dengan User
              height: 40, // SAMA dengan User
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
                ]),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // CONTENT dengan glassmorphism effect - SAMA DENGAN USER
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 10, 20, 0), // SAMA dengan User
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final settings = context.dependOnInheritedWidgetOfExactType<
                      FlexibleSpaceBarSettings>()!;
                  final delta = settings.maxExtent - settings.minExtent;
                  final opacity =
                      ((settings.currentExtent - settings.minExtent) / delta)
                          .clamp(0.0, 1.0);

                  return Opacity(
                    opacity: opacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header dengan title dan profile - SAMA DENGAN USER
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
                                'Dashboard Officer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            _buildProfileButton(), // Gunakan method yang sudah ada
                          ],
                        ),
                        const SizedBox(height: 30), // SAMA dengan User

                        // GLASSMORPHISM WELCOME CARD - SAMA DENGAN USER
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.waving_hand,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Welcome back,',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    currentUser!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28, // SAMA dengan User
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 8.0,
                                          color: Colors.black26,
                                          offset: Offset(0, 3.0),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Officer since ${DateFormat('dd MMM yyyy').format(currentUser!.createdAt)}',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'profile') {
          _showProfileDialog();
        } else if (value == 'logout') {
          _showLogoutDialog();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_outline,
                    color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text('My Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout, color: Colors.red[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Logout', style: TextStyle(color: Colors.red)),
            ],
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
        padding: const EdgeInsets.all(0),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _AnimatedAppCard(
            title: 'Maintenance',
            icon: Icons.construction,
            color: Colors.orange[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OfficerDashboard()),
              );
            },
          ),
          _AnimatedAppCard(
            title: 'Resource/Item',
            icon: Icons.people_alt_outlined,
            color: Colors.cyan[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OfficerDashboardResource()),
              );
            },
          ),
          _AnimatedAppCard(
            title: 'Operational',
            icon: Icons.directions_car,
            color: Colors.red[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OfficerDashboardOprational()),
              );
            },
          ),
          _AnimatedAppCard(
            title: 'Booking Room',
            icon: Icons.meeting_room,
            color: Colors.teal[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OfficerDashboardBookingRoom()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget _buildAppCard({
  //   required BuildContext context,
  //   required String title,
  //   required IconData icon,
  //   required Color color,
  //   required VoidCallback onTap,
  // }) {
  //   // Create a lighter background color, same as in HomeDashboardUser
  //   Color bgColor = Color.lerp(Colors.white, color, 0.30)!;

  //   return Card(
  //     elevation: 0,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(24),
  //       child: Container(
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(24),
  //           color: bgColor, // Use the light solid color
  //           boxShadow: [
  //             BoxShadow(
  //               color: color.withOpacity(0.15),
  //               blurRadius: 20,
  //               spreadRadius: 0,
  //               offset: const Offset(5, 10),
  //             ),
  //           ],
  //           border: Border.all(
  //             color: color.withOpacity(0.3),
  //             width: 1.5,
  //           ),
  //         ),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 // Semi-transparent white background for the icon
  //                 color: Colors.white.withOpacity(0.7),
  //                 shape: BoxShape.circle,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: color.withOpacity(0.1),
  //                     blurRadius: 10,
  //                     spreadRadius: 0,
  //                     offset: const Offset(0, 5),
  //                   ),
  //                 ],
  //               ),
  //               child: Icon(icon, size: 32, color: color),
  //             ),
  //             const SizedBox(height: 16),
  //             Text(
  //               title,
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 color: color.withOpacity(0.9),
  //                 letterSpacing: 0.5,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Container(
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withOpacity(0.5),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 Icons.open_in_new,
  //                 size: 16,
  //                 color: color,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout Confirmation'),
        content:
            const Text('Are you sure you want to log out of this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthService>(context, listen: false).signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class OfficerStatusTab extends StatefulWidget {
  final UserModel currentUser;
  const OfficerStatusTab({super.key, required this.currentUser});

  @override
  State<OfficerStatusTab> createState() => _OfficerStatusTabState();
}

class _OfficerStatusTabState extends State<OfficerStatusTab>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _completionReasonController =
      TextEditingController();
  bool _isCompleting = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  List<dynamic> _combinedList = [];
  List<dynamic> _filteredList = [];
  bool _isLoading = true;
  bool _isSearching = false;

  int _currentPage = 1;
  final int _itemsPerPage = 5;
  late booking_service.FirestoreService _firestoreService;

  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 2, vsync: this);
    _firestoreService = booking_service.FirestoreService();
    _listenToDataStreams();
    _searchController.addListener(_onSearchChanged);
    _statusTabController.addListener(_filterByStatus);
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _statusTabController.dispose();
    _searchController.dispose();
    _completionReasonController.dispose();
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
        title: const Text('Filter by Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All Time'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Today'),
              value: 'today',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('This Week'),
              value: 'week',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _filterData();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('This Month'),
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
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }

  Future<void> _fetchData() async {
    // Fungsi ini dipanggil oleh RefreshIndicator untuk refresh manual
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final maintenanceService = maintenance_service.FirestoreService();
      final resourceService = resource_service.FirestoreServiceResource();
      final operasionalService =
          operasional_service.OperasionalFirestoreService();
      final bookingService = booking_service.FirestoreService();

      // Mengambil data terbaru satu kali dari semua sumber
      final reportsSnapshot = await maintenanceService.getReports().first;
      final requestsSnapshot = await resourceService.getRequests().first;
      final operationalSnapshot =
          await operasionalService.getRideRequests().first;
      final bookingSnapshot = await bookingService.getBookings().first;

      if (mounted) {
        // Proses dan perbarui UI sama seperti logika di listener
        final openAndInProgressReports = reportsSnapshot
            .where((r) => r.status == 'open' || r.status == 'inProgress')
            .toList();
        final openAndInProgressRequests = requestsSnapshot
            .where((r) => r.status == 'open' || r.status == 'inProgress')
            .toList();
        final openAndInProgressOperational = operationalSnapshot
            .where((r) => r.status == 'open' || r.status == 'inProgress')
            .toList();
        final openAndInProgressBooking = bookingSnapshot
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to refresh data: $e")),
        );
      }
    }
  }

  void _listenToDataStreams() {
    setState(() {
      _isLoading = true;
    });

    final maintenanceService = maintenance_service.FirestoreService();
    final resourceService = resource_service.FirestoreServiceResource();
    final operasionalService =
        operasional_service.OperasionalFirestoreService();
    final bookingService = booking_service.FirestoreService();

    // Menggabungkan 4 stream menjadi satu menggunakan RxDart
    _dataSubscription = CombineLatestStream.combine4(
      maintenanceService.getReports(),
      resourceService.getRequests(),
      operasionalService.getRideRequests(),
      bookingService.getBookings(),
      (List<ReportModel> reports, List<RequestModel> requests,
          List<RideRequestModel> operational, List<BookingModel> bookings) {
        // Fungsi ini akan menggabungkan hasil dari keempat stream
        return [reports, requests, operational, bookings];
      },
    ).listen((data) {
      // .listen akan terpanggil setiap kali ada perubahan data di salah satu stream
      if (!mounted) return;

      final reports = data[0] as List<ReportModel>;
      final requests = data[1] as List<RequestModel>;
      final operationalRequests = data[2] as List<RideRequestModel>;
      final bookingRequests = data[3] as List<BookingModel>;

      // Logika pemfilteran dan penggabungan data, sama seperti sebelumnya
      final openAndInProgressReports = reports
          .where((r) => r.status == 'open' || r.status == 'inProgress')
          .toList();
      final openAndInProgressRequests = requests
          .where((r) => r.status == 'open' || r.status == 'inProgress')
          .toList();
      final openAndInProgressOperational = operationalRequests
          .where((r) => r.status == 'open' || r.status == 'inProgress')
          .toList();
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
        _filterData(); // Memfilter ulang data berdasarkan tab dan pencarian
        _isLoading = false; // Matikan loading setelah data pertama diterima
      });
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
              item.description.toLowerCase().contains(_searchQuery) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
        } else if (item is RequestModel) {
          return item.description.toLowerCase().contains(_searchQuery) ||
              (item.timeRequired?.toLowerCase().contains(_searchQuery) ??
                  false) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
        } else if (item is RideRequestModel) {
          return item.pickupLocation.toLowerCase().contains(_searchQuery) ||
              item.dropoffLocation.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
        } else if (item is BookingModel) {
          return item.roomName.toLowerCase().contains(_searchQuery) ||
              item.eventAgenda.toLowerCase().contains(_searchQuery) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
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
                    'Search results for "${_searchController.text}"',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredList.length} results',
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
                      return _buildReportCard(item);
                    } else if (item is RequestModel) {
                      return _buildRequestCard(item);
                    } else if (item is RideRequestModel) {
                      return _buildRideRequestCard(item);
                    } else if (item is BookingModel) {
                      return _buildBookingCard(item);
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
                          label: const Text('See more'),
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
                hintText: 'Find the latest status here...',
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
            tooltip: 'Filter by Time',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final bool isSearchActive = _searchQuery.isNotEmpty;
    final bool isTimeFilterActive = _selectedFilter != 'all';

    IconData icon = Icons.inbox_outlined;
    String title = 'Nothing Found';
    String description = 'There are no tasks with this status at this time.';
    Widget? actionButton;

    if (isSearchActive) {
      icon = Icons.search_off;
      title = 'Search Not Found';
      description = 'No data matches the keyword "${_searchController.text}".';
      actionButton = TextButton.icon(
        onPressed: _clearSearch,
        icon: const Icon(Icons.clear, color: Colors.red),
        label: const Text(
          'Clear Search',
          style: TextStyle(color: Colors.red),
        ),
      );
    } else if (isTimeFilterActive) {
      icon = Icons.filter_alt_off_outlined;
      title = 'Data Not Found';
      description = 'There is no data in the selected time range.';
      actionButton = TextButton.icon(
        onPressed: _clearTimeFilter,
        icon: const Icon(Icons.clear, color: Colors.red),
        label: const Text(
          'Clear Filter',
          style: TextStyle(color: Colors.red),
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
      hint: times.isEmpty ? const Text('Start Time') : null,
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

  Widget _buildReportCard(ReportModel report) {
    return Container(
      // Use Container to apply decoration
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1.5),
        ),
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _navigateToDetail(report),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: Icon(Icons.construction,
                          color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Maintenance Report',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('by ${report.employeeName}',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    _buildStatusChip(report.status),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.location_on_outlined,
                    '${report.buildingName} - ${report.roomName}',
                    isBold: true),
                const SizedBox(height: 8),
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
                if (report.imageUrl != null && report.hasValidImage()) ...[
                  const SizedBox(height: 8), // Reduced spacing
                  SizedBox(
                    height: 100, // Reduced height
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FirebaseStorageImage(
                        imageUrl: report.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                        Icons.access_time, _getTimeAgo(report.createdAt)),
                    const Spacer(),
                    if (report.status == 'open')
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _navigateToAssignTechnicianReport(report),
                          icon:
                              const Icon(Icons.engineering_outlined, size: 16),
                          label: const Text('Assign'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[500],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    if (report.status == 'inProgress')
                      SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _navigateToAssignTechnicianReport(report),
                          icon:
                              const Icon(Icons.engineering_outlined, size: 16),
                          label: Text(report.technicianName ?? 'Assign'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              side: BorderSide(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5))),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    final bool isResourceRequest = request.request == 'resource';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyan.withOpacity(0.3), width: 1.5),
        ),
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _navigateToDetail(request),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.cyan.withOpacity(0.1),
                      child: Icon(Icons.groups_outlined,
                          color: Colors.cyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resource Request',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('by ${request.employeeName}',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    _buildStatusChip(request.status),
                  ],
                ),
                const Divider(height: 24),
                if (!isResourceRequest && request.hasValidImage()) ...[
                  SizedBox(
                    height: 100, // Reduced height
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FirebaseStorageImage(
                        imageUrl: request.getNormalizedImageUrl(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 20, // Smaller spinner
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[400],
                              size: 30, // Smaller icon
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8), // Reduced spacing
                ],
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
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                        Icons.access_time, _getTimeAgo(request.createdAt)),
                    const Spacer(),
                    if (request.status == 'open')
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _navigateToAssignTechnicianRequest(request),
                          icon:
                              const Icon(Icons.engineering_outlined, size: 16),
                          label: const Text('Assign'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan[500],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    if (request.status == 'inProgress')
                      SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _navigateToAssignTechnicianRequest(request),
                          icon:
                              const Icon(Icons.engineering_outlined, size: 16),
                          label: Text(request.technicianName ?? 'Assign'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              side: BorderSide(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5))),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRideRequestCard(RideRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1.5),
        ),
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _navigateToDetail(request),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      child: Icon(Icons.directions_car_outlined,
                          color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Operational Request',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('by ${request.employeeName}',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    _buildStatusChip(request.status),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(
                    Icons.my_location, 'From: ${request.pickupLocation}',
                    isBold: true),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.location_on_outlined,
                    'To: ${request.dropoffLocation}',
                    isBold: true),
                const SizedBox(height: 12),
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
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                        Icons.event,
                        DateFormat('d MMM, HH:mm')
                            .format(request.pickupDateTime)),
                    const Spacer(),
                    if (request.status == 'open')
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _navigateToAssignDriverVehicle(request),
                          icon: const Icon(Icons.assignment_ind_outlined,
                              size: 16),
                          label: const Text('Assign'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    if (request.status == 'inProgress')
                      SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _navigateToAssignDriverVehicle(request),
                          icon: const Icon(Icons.assignment_ind_outlined,
                              size: 16),
                          label: Text(request.driverName ?? 'Assign'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              side: BorderSide(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5))),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.teal.withOpacity(0.3), width: 1.5),
        ),
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _navigateToDetail(booking),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.1),
                      child: Icon(Icons.meeting_room_outlined,
                          color: Colors.teal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Booking Request',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('by ${booking.employeeName}',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    _buildStatusChip(booking.status),
                  ],
                ),
                const Divider(height: 24),
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
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Room: ${booking.roomName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                    Icons.person_outline, 'by: ${booking.employeeName}'),
                const SizedBox(height: 6),
                _buildInfoRow(
                    Icons.calendar_today_outlined,
                    _formatDateRange(
                        booking.usageStartDate, booking.usageEndDate)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                        Icons.access_time, _getTimeAgo(booking.createdAt)),
                    const Spacer(),
                    if (booking.status == 'open')
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () => _showManageBookingSheet(booking),
                          icon: const Icon(Icons.edit_calendar_outlined,
                              size: 16),
                          label: const Text('Manage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text,
      {bool isBold = false, int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines, // Menggunakan parameter maxLines
            overflow: TextOverflow.ellipsis, // Menambahkan overflow handling
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

  void _navigateToAssignTechnicianReport(ReportModel report) async {
    if (report.assignedTechnicianId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'This report already has an assigned technician: ${report.technicianName}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTechnicianScreen(report: report),
      ),
    );
    // Jika result tidak null dan bernilai true, refresh data
    if (result == true && mounted) {
      _fetchData();
    }
  }

  void _navigateToAssignTechnicianRequest(RequestModel request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTechnicianScreenResource(request: request),
      ),
    );
    // Jika result tidak null dan bernilai true, refresh data
    if (result == true && mounted) {
      _fetchData();
    }
  }

  void _navigateToAssignDriverVehicle(RideRequestModel request) async {
    // Check if request already has an assigned driver and vehicle
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

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignDriverVehicleScreen(request: request),
      ),
    );
    // Jika result tidak null dan bernilai true, refresh data
    if (result == true && mounted) {
      _fetchData();
    }
  }

  void _showCompleteDialogMaintenance(ReportModel report) {
    _completionReasonController.clear();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: !_isCompleting,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Report'),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _completeReportMaintenance(report);
              }
            },
            child: _isCompleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeReportMaintenance(ReportModel report) async {
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
      final maintenanceService = maintenance_service.FirestoreService();
      await maintenanceService.completeReport(
        report.id,
        _completionReasonController.text.trim(),
        technicianId: report.assignedTechnicianId ?? 'officer',
        technicianName: report.technicianName ?? 'Office Management',
      );

      // Pop the dialog on success
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchData();
    } catch (e) {
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing report: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  void _showCompleteDialogResource(RequestModel request) {
    _completionReasonController.clear();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: !_isCompleting,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _completeRequestResource(request);
              }
            },
            child: _isCompleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRequestResource(RequestModel request) async {
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

    if (widget.currentUser == null) return;

    setState(() => _isCompleting = true);

    try {
      final resourceService = resource_service.FirestoreServiceResource();
      await resourceService.completeRequest(
        request.id,
        _completionReasonController.text.trim(),
        technicianId: request.assignedTechnicianId ?? widget.currentUser!.uid,
        technicianName: request.technicianName ?? widget.currentUser!.name,
      );

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchData();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  void _showCompleteDialogOperasional(RideRequestModel request) {
    _completionReasonController.clear();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: !_isCompleting,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Ride Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provide completion notes (optional):'),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _completeRequestOperasional(request);
              }
            },
            child: _isCompleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRequestOperasional(RideRequestModel request) async {
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

    setState(() => _isCompleting = true);

    try {
      final operasionalService =
          operasional_service.OperasionalFirestoreService();
      await operasionalService.completeRideRequest(
        request.id,
        _completionReasonController.text.trim(),
        driverId: request.driverId,
        vehicleId: request.vehicleId,
      );

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride request marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchData();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  void _showManageBookingSheet(BookingModel booking) {
    final formKey = GlobalKey<FormState>();

    RoomModel? selectedRoom;
    final notesController =
        TextEditingController(text: booking.completionReason);

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
            booking.roomName == 'Not Specified' ? null : booking.roomId;

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
                _fetchData();
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

            Widget _buildSingleDayInputs(
              BuildContext context,
              StateSetter setState,
              DateTime? currentDate,
              TimeOfDay? currentTime,
              TimeOfDay? endTime, {
              required Function(DateTime) onDateChanged,
              required Function(TimeOfDay?) onStartTimeChanged,
              required Function(TimeOfDay?) onEndTimeChanged,
            }) {
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
              DateTime? currentEndDate, {
              required Function(DateTime) onStartDateChanged,
              required Function(DateTime?) onEndDateChanged,
            }) {
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
                          context, 'Start Time', state.value, (date) {
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
                    Expanded(
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                        .withOpacity(0.2),
                                  ),
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
                              _buildSectionTitle('Room Configuration & Time'),
                              const SizedBox(height: 12),
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
                                  if (selectedRoomId != null &&
                                      selectedRoom == null) {
                                    try {
                                      selectedRoom = rooms.firstWhere(
                                          (r) => r.id == selectedRoomId);
                                    } catch (_) {
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
                              TextFormField(
                                controller: notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Additional Notes',
                                  hintText:
                                      'Add a note for the room orderer...',
                                  prefixIcon: Icon(Icons.note_alt_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
    final _rejectionReasonController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // Instantiating the correct service from the aliased import
                final bookingService = booking_service.FirestoreService();

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  await bookingService.updateBookingStatus(
                    booking.id,
                    'cancelled',
                    reason:
                        'Rejected: ${_rejectionReasonController.text.trim()}',
                  );

                  // Pop loading dialog
                  if (mounted) Navigator.pop(context);
                  // Pop reject dialog
                  if (mounted) Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Booking successfully rejected.'),
                    backgroundColor: Colors.orange,
                  ));

                  // Refresh the data list
                  _fetchData();
                } catch (e) {
                  // Pop loading dialog on error
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to reject booking: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Booking',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((_) => _rejectionReasonController.dispose());
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

  void _navigateToDetail(dynamic item) {
    if (item is ReportModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ReportDetailScreen(report: item)),
      );
    } else if (item is RequestModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RequestDetailScreenResource(request: item)),
      );
    } else if (item is RideRequestModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RideRequestDetailScreen(request: item)),
      );
    } else if (item is BookingModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => BookingDetailScreen(booking: item)),
      );
    }
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

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} last year';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} last month';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} last days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} last hours';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} last minutes';
    } else {
      return 'just now';
    }
  }
}

enum RatingType { teknisi, kendaraan, ruangan }

class OfficerRatingTab extends StatefulWidget {
  const OfficerRatingTab({super.key});

  @override
  State<OfficerRatingTab> createState() => _OfficerRatingTabState();
}

class _OfficerRatingTabState extends State<OfficerRatingTab>
    with TickerProviderStateMixin {
  late TabController _ratingTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final UserService _userService = UserService();
  bool _isLoading = true;
  List<UserModel> _allTechnicians = [];
  List<UserModel> _filteredTechnicians = [];
  String _technicianSortBy = 'rating';
  String _driverSortBy = 'rating';
  String _vehicleSortBy = 'rating';
  String _roomSortBy = 'ratingDate';

  final operasional_service.OperasionalFirestoreService _operasionalService =
      operasional_service.OperasionalFirestoreService();
  List<UserModel> _allDrivers = [];
  List<DriverModel> _driverDetails = [];
  List<UserModel> _filteredDrivers = [];

  List<VehicleModel> _allVehicles = [];
  List<VehicleModel> _filteredVehicles = [];
  Map<String, Map<String, dynamic>> _vehicleRatings = {};

  final booking_service.FirestoreService _bookingService =
      booking_service.FirestoreService();
  List<RoomModel> _allRooms = [];
  List<BookingModel> _allRatedBookings = [];
  List<BookingModel> _filteredRatedBookings = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _ratingTabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _ratingTabController.addListener(() {
      if (mounted) {
        setState(() {
          // Panggil filter yang sesuai saat tab diganti
          if (_ratingTabController.index == 0) {
            _filterAndSortTechnicians();
          } else if (_ratingTabController.index == 1) {
            _filterAndSortDrivers();
          } else if (_ratingTabController.index == 2) {
            _filterAndSortVehicles();
          } else if (_ratingTabController.index == 3) {
            _filterAndSortRatedBookings();
          }
        });
      }
    });
    _fetchTechnicianData();
    _fetchDriverData();
    _fetchVehicleData();
    _fetchRoomData();
  }

  @override
  void dispose() {
    _ratingTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_ratingTabController.index == 0) {
        _filterAndSortTechnicians();
      } else if (_ratingTabController.index == 1) {
        _filterAndSortDrivers();
      } else if (_ratingTabController.index == 2) {
        _filterAndSortVehicles();
      } else if (_ratingTabController.index == 3) {
        _filterAndSortRatedBookings();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  Future<void> _fetchTechnicianData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Ambil semua user dengan role 'technician'
      final allTechnicianUsers = await _userService.getTechnicians();

      // 2. Ambil SEMUA driver dari koleksi 'drivers' (bukan hanya yg available)
      final driverDocs = await _userService.getAllDrivers();
      final driverUids = driverDocs.map((d) => d['uid']).toSet();

      // 3. Filter untuk mendapatkan teknisi murni (yang UID-nya TIDAK ADA di koleksi drivers)
      // Ini memperbaiki bug di mana driver masih muncul di list teknisi
      final pureTechnicians = allTechnicianUsers.where((tech) {
        return !driverUids.contains(tech.uid);
      }).toList();

      if (mounted) {
        setState(() {
          _allTechnicians = pureTechnicians;
          _filterAndSortTechnicians();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching technicians: $e')),
        );
      }
    }
  }

  void _filterAndSortTechnicians() {
    List<UserModel> tempTechnicians = List.from(_allTechnicians);

    // Filter berdasarkan pencarian
    if (_searchQuery.isNotEmpty) {
      tempTechnicians = tempTechnicians.where((tech) {
        final nameLower = tech.name.toLowerCase();
        final emailLower = tech.email.toLowerCase();
        return nameLower.contains(_searchQuery) ||
            emailLower.contains(_searchQuery);
      }).toList();
    }

    // Urutkan berdasarkan pilihan
    switch (_technicianSortBy) {
      case 'rating':
        tempTechnicians.sort((a, b) =>
            (b.averageRating ?? 0.0).compareTo(a.averageRating ?? 0.0));
        break;
      case 'name':
        tempTechnicians.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'since':
        tempTechnicians.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    setState(() {
      _filteredTechnicians = tempTechnicians;
    });
  }

  Future<void> _fetchDriverData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Ambil semua dokumen dari koleksi 'drivers' secara langsung
      final driverSnapshot = await _firestore.collection('drivers').get();

      if (driverSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _allDrivers = [];
            _filteredDrivers = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Simpan detail driver (termasuk isAvailable, averageRating, totalRatings)
      // dari koleksi 'drivers' ke dalam sebuah Map untuk akses cepat.
      final Map<String, Map<String, dynamic>> driverDataMap = {
        for (var doc in driverSnapshot.docs) doc.id: doc.data(),
      };

      _driverDetails = driverSnapshot.docs
          .map((doc) => DriverModel.fromSnapshot(doc))
          .toList();

      final driverUids = driverSnapshot.docs.map((doc) => doc.id).toList();

      // 2. Ambil data user yang sesuai dengan UID driver dari koleksi 'users'
      final userSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: driverUids)
          .get();

      final baseUserModels =
          userSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // 3. Gabungkan data dari 'users' dan 'drivers'
      List<UserModel> mergedDrivers = [];
      for (var user in baseUserModels) {
        final driverData = driverDataMap[user.uid];
        if (driverData != null) {
          mergedDrivers.add(
            user.copyWith(
              // Ambil rating dari data driver, bukan dari data user
              averageRating:
                  (driverData['averageRating'] as num?)?.toDouble() ?? 0.0,
              totalRatings: driverData['totalRatings'] as int? ?? 0,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _allDrivers = mergedDrivers;
          _filterAndSortDrivers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching drivers: $e')),
        );
      }
    }
  }

  void _filterAndSortDrivers() {
    List<UserModel> tempDrivers = List.from(_allDrivers);

    // Filter berdasarkan pencarian
    if (_searchQuery.isNotEmpty) {
      tempDrivers = tempDrivers.where((driver) {
        final nameLower = driver.name.toLowerCase();
        final emailLower = driver.email.toLowerCase();
        return nameLower.contains(_searchQuery) ||
            emailLower.contains(_searchQuery);
      }).toList();
    }

    // Urutkan berdasarkan pilihan (menggunakan _sortBy yang sama dengan teknisi)
    switch (_driverSortBy) {
      case 'rating':
        tempDrivers.sort((a, b) =>
            (b.averageRating ?? 0.0).compareTo(a.averageRating ?? 0.0));
        break;
      case 'name':
        tempDrivers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'since':
        tempDrivers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    setState(() {
      _filteredDrivers = tempDrivers;
    });
  }

  Future<void> _fetchVehicleData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Ambil semua dokumen dari koleksi 'vehicles'
      final vehicleDocs = await _operasionalService.getVehicles().first;

      // 2. Ambil semua data rating dari 'vehicle_ratings'
      final ratingSnapshot =
          await _firestore.collection('vehicle_ratings').get();

      // 3. Proses dan kelompokkan rating berdasarkan vehicleId
      final Map<String, List<double>> ratingsMap = {};
      for (var doc in ratingSnapshot.docs) {
        final data = doc.data();
        final vehicleId = data['vehicleId'] as String?;
        final rating = (data['rating'] as num?)?.toDouble();
        if (vehicleId != null && rating != null) {
          ratingsMap.putIfAbsent(vehicleId, () => []).add(rating);
        }
      }

      // 4. Hitung rata-rata dan total rating untuk setiap kendaraan
      _vehicleRatings.clear();
      ratingsMap.forEach((vehicleId, ratings) {
        final double average = ratings.reduce((a, b) => a + b) / ratings.length;
        _vehicleRatings[vehicleId] = {
          'averageRating': average,
          'totalRatings': ratings.length,
        };
      });

      if (mounted) {
        setState(() {
          _allVehicles = vehicleDocs;
          _filterAndSortVehicles();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching vehicles: $e')),
        );
      }
    }
  }

  void _filterAndSortVehicles() {
    List<VehicleModel> tempVehicles = List.from(_allVehicles);

    if (_searchQuery.isNotEmpty) {
      tempVehicles = tempVehicles.where((v) {
        return v.displayName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Urutkan berdasarkan pilihan (_sortBy yang sama)
    switch (_vehicleSortBy) {
      case 'rating':
        tempVehicles.sort((a, b) {
          final ratingA =
              (_vehicleRatings[a.id]?['averageRating'] as double?) ?? 0.0;
          final ratingB =
              (_vehicleRatings[b.id]?['averageRating'] as double?) ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'name':
        tempVehicles.sort((a, b) => a.vehicleModel.compareTo(b.vehicleModel));
        break;
    }

    setState(() {
      _filteredVehicles = tempVehicles;
    });
  }

  Future<void> _fetchRoomData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Ambil semua data ruangan untuk statistik jumlah ruangan
      final roomDocs = await _bookingService.getRooms().first;

      // 2. Ambil semua data booking untuk mencari yang sudah diberi rating
      final allBookings = await _bookingService.getBookings().first;

      // 3. Filter booking: status harus 'approved' dan sudah memiliki rating
      final ratedBookings = allBookings.where((booking) {
        return booking.status == 'approved' && booking.rating != null;
      }).toList();

      if (mounted) {
        setState(() {
          _allRooms = roomDocs; // Untuk statistik
          _allRatedBookings = ratedBookings; // Untuk daftar
          _filterAndSortRatedBookings(); // Panggil fungsi filter dan sort
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching room data: $e')),
        );
      }
    }
  }

  void _filterAndSortRatedBookings() {
    List<BookingModel> tempBookings = List.from(_allRatedBookings);

    if (_searchQuery.isNotEmpty) {
      tempBookings = tempBookings.where((b) {
        final query = _searchQuery.toLowerCase();
        return b.eventAgenda.toLowerCase().contains(query) ||
            b.roomName.toLowerCase().contains(query) ||
            b.employeeName.toLowerCase().contains(query);
      }).toList();
    }

    // Urutkan berdasarkan pilihan (_sortBy yang sama, namun dengan logika berbeda)
    switch (_roomSortBy) {
      case 'rating': // Rating tertinggi
        tempBookings
            .sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
        break;
      case 'name': // Nama ruangan A-Z
        tempBookings.sort((a, b) => a.roomName.compareTo(b.roomName));
        break;
      case 'ratingDate': // Rating terbaru
        tempBookings.sort((a, b) => (b.ratingDate ?? b.createdAt)
            .compareTo(a.ratingDate ?? a.createdAt));
        break;
    }

    setState(() {
      _filteredRatedBookings = tempBookings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildStatisticsCards(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSearchAndFilterBar(),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _ratingTabController,
            isScrollable: false, // Membuat tab simetris
            indicatorSize:
                TabBarIndicatorSize.tab, // Indikator sesuai lebar tab
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: 'Technician'),
              Tab(text: 'Driver'),
              Tab(text: 'Vehicle'),
              Tab(text: 'Room'),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

        // Konten Tab akan ditampilkan di sini
        [
          _buildTechnicianTabContent(),
          _buildDriverTabContent(),
          _buildVehicleTabContent(),
          _buildRoomTabContent(),
        ][_ratingTabController.index]
      ],
    );
  }

  Widget _buildEmptyTabContent(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Technician',
                  rating: _allTechnicians.length.toDouble(),
                  icon: Icons.engineering,
                  color: Colors.orange.shade800,
                  backgroundColor: Colors.orange.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Driver',
                  rating: _allDrivers.length.toDouble(),
                  icon: Icons.person_3,
                  color: Colors.blue.shade800,
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Vehicle',
                  rating: _allVehicles.length.toDouble(),
                  icon: Icons.directions_car,
                  color: Colors.red.shade800,
                  backgroundColor: Colors.red.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Room',
                  rating: _allRooms.length.toDouble(),
                  icon: Icons.meeting_room,
                  color: Colors.teal.shade800,
                  backgroundColor: Colors.teal.shade50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double rating,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rating.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 13,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianTabContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        // --- Header dengan Judul dan Tombol Sort ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Technicians (${_filteredTechnicians.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String newValue) {
                  setState(() {
                    _technicianSortBy = newValue;
                  });
                  _filterAndSortTechnicians();
                },
                icon: Icon(Icons.filter_list, color: Colors.grey[800]),
                tooltip: 'Sort By',
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'rating',
                    child: Text('Rating'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'name',
                    child: Text('Name'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'since',
                    child: Text('Since'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- Daftar Teknisi atau Pesan Kosong ---
        _filteredTechnicians.isEmpty
            ? _buildEmptyStateForList()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredTechnicians.length,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  final technician = _filteredTechnicians[index];
                  return _buildTechnicianCard(technician);
                },
              ),
      ],
    );
  }

  /// Widget untuk setiap kartu teknisi, sesuai desain
  Widget _buildTechnicianCard(UserModel technician) {
    final avgRating = technician.averageRating ?? 0.0;
    final totalRatings = technician.totalRatings ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RatingDetailScreen(
                  entity: technician,
                  type: DetailRatingType.technician,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.engineering_outlined,
                              size: 28, color: Colors.grey[600]),
                        ),
                        if (totalRatings > 0)
                          Positioned(
                            top: -4,
                            left: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRatingChipColor(avgRating)
                                    .withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technician.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            technician.email,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildRatingStars(avgRating),
                    const SizedBox(width: 4),
                    Text(
                      '${avgRating.toStringAsFixed(1)} ($totalRatings)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    if (totalRatings > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _getRatingChipColor(avgRating).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getRatingText(avgRating),
                          style: TextStyle(
                              color: _getRatingChipColor(avgRating),
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.calendar_today_outlined,
                        'Member since ${DateFormat('MMM yyyy').format(technician.createdAt)}'),
                    _buildInfoChip(
                        Icons.trending_up, _getSinceText(technician.createdAt)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget utama untuk konten tab driver
  Widget _buildDriverTabContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        // --- Header dengan Judul dan Tombol Sort ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Drivers (${_filteredDrivers.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String newValue) {
                  setState(() {
                    _driverSortBy = newValue;
                  });
                  _filterAndSortDrivers();
                },
                icon: Icon(Icons.filter_list, color: Colors.grey[800]),
                tooltip: 'Sort By',
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'rating',
                    child: Text('Rating'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'name',
                    child: Text('Name'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'since',
                    child: Text('Since'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- Daftar Driver atau Pesan Kosong ---
        _filteredDrivers.isEmpty
            ? _buildEmptyStateForList(isDriver: true)
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredDrivers.length,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  final driverUser = _filteredDrivers[index];
                  // Cari detail driver untuk mendapatkan status isAvailable
                  final driverDetail = _driverDetails.firstWhere(
                    (d) => d.id == driverUser.uid,
                    orElse: () => DriverModel(
                        id: '',
                        name: '',
                        createdAt: DateTime.now(),
                        isAvailable: true),
                  );
                  return _buildDriverCard(driverUser, driverDetail);
                },
              ),
      ],
    );
  }

  /// Widget untuk setiap kartu driver
  Widget _buildDriverCard(UserModel driverUser, DriverModel driverDetail) {
    final avgRating = driverUser.averageRating ?? 0.0;
    final totalRatings = driverUser.totalRatings ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RatingDetailScreen(
                  entity: driverUser,
                  type: DetailRatingType.driver,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue[100],
                          child: Icon(Icons.person_outline,
                              size: 28, color: Colors.blue[800]),
                        ),
                        if (totalRatings > 0)
                          Positioned(
                            top: -4,
                            left: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRatingChipColor(avgRating)
                                    .withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Text(avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driverUser.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(driverUser.email,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: driverDetail.isAvailable
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              size: 8,
                              color: driverDetail.isAvailable
                                  ? Colors.green
                                  : Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            driverDetail.isAvailable ? 'Available' : 'On Duty',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: driverDetail.isAvailable
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildRatingStars(avgRating),
                    const SizedBox(width: 4),
                    Text('${avgRating.toStringAsFixed(1)} (${totalRatings})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    if (totalRatings > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _getRatingChipColor(avgRating).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_getRatingText(avgRating),
                            style: TextStyle(
                                color: _getRatingChipColor(avgRating),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.calendar_today_outlined,
                        'Member since ${DateFormat('MMM yyyy').format(driverUser.createdAt)}'),
                    _buildInfoChip(
                        Icons.trending_up, _getSinceText(driverUser.createdAt)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget utama untuk konten tab vehicle
  Widget _buildVehicleTabContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
            padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Vehicles (${_filteredVehicles.length})',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
              PopupMenuButton<String>(
                onSelected: (String newValue) {
                  setState(() {
                    _vehicleSortBy = newValue;
                  });
                  _filterAndSortVehicles();
                },
                icon: Icon(Icons.filter_list, color: Colors.grey[800]),
                tooltip: 'Sort By',
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'rating',
                    child: Text('Rating'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'name',
                    child: Text('Name'),
                  ),
                ],
              ),
            ],
          ),
        ),
        _filteredVehicles.isEmpty
            ? _buildEmptyStateForList(isVehicle: true)
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredVehicles.length,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  final vehicle = _filteredVehicles[index];
                  return _buildVehicleCard(vehicle);
                },
              ),
      ],
    );
  }

  /// Widget untuk setiap kartu kendaraan
  Widget _buildVehicleCard(VehicleModel vehicle) {
    final ratingInfo = _vehicleRatings[vehicle.id] ??
        {'averageRating': 0.0, 'totalRatings': 0};
    final avgRating = ratingInfo['averageRating'] as double;
    final totalRatings = ratingInfo['totalRatings'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RatingDetailScreen(
                  entity: vehicle,
                  entityRatingData: ratingInfo,
                  type: DetailRatingType.vehicle,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.red[100],
                      child: Icon(Icons.directions_car_outlined,
                          size: 28, color: Colors.red[800]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vehicle.vehicleModel}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vehicle.licensePlate,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: vehicle.isAvailable
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              size: 8,
                              color: vehicle.isAvailable
                                  ? Colors.green
                                  : Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.isAvailable ? 'Available' : 'In Use',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: vehicle.isAvailable
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildRatingStars(avgRating),
                    const SizedBox(width: 4),
                    Text(
                      '${avgRating.toStringAsFixed(1)} ($totalRatings)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    if (totalRatings > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _getRatingChipColor(avgRating).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getRatingText(avgRating),
                          style: TextStyle(
                              color: _getRatingChipColor(avgRating),
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
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

  /// Widget utama untuk konten tab room
  Widget _buildRoomTabContent() {
    if (_isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rated Bookings (${_filteredRatedBookings.length})',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
              PopupMenuButton<String>(
                onSelected: (String newValue) {
                  setState(() {
                    _roomSortBy = newValue;
                  });
                  _filterAndSortRatedBookings();
                },
                icon: Icon(Icons.filter_list, color: Colors.grey[800]),
                tooltip: 'Sort By',
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'rating',
                    child: Text('Rating'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'name',
                    child: Text('Room Name'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ratingDate',
                    child: Text('Recent'),
                  ),
                ],
              ),
            ],
          ),
        ),
        _filteredRatedBookings.isEmpty
            ? _buildEmptyStateForList(isRoom: true)
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredRatedBookings.length,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  final booking = _filteredRatedBookings[index];
                  return _buildRatedBookingCard(booking);
                },
              ),
      ],
    );
  }

  /// Widget untuk setiap kartu booking yang sudah di-rate
  Widget _buildRatedBookingCard(BookingModel booking) {
    final rating = booking.rating ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.teal.withOpacity(0.3), width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailScreen(booking: booking),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.teal[100],
                      child: Icon(Icons.meeting_room_outlined,
                          size: 28, color: Colors.teal[800]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.roomName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Agenda: ${booking.eventAgenda}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRatingChipColor(rating).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text('Rated by ${booking.employeeName}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700])),
                      const Spacer(),
                      _buildRatingStars(rating),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _getRatingChipColor(rating)),
                      ),
                    ],
                  ),
                ),
                if (booking.ratingDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Rated on: ${DateFormat('d MMM yyyy').format(booking.ratingDate!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper untuk membuat bintang rating
  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  /// Helper untuk info di bagian bawah kartu
  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
        ),
      ],
    );
  }

  /// Helper untuk mendapatkan warna chip rating
  Color _getRatingChipColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.blue;
    if (rating >= 2.5) return Colors.orange;
    return Colors.red;
  }

  /// Helper untuk mendapatkan teks rating
  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'EXCELLENT';
    if (rating >= 3.5) return 'GOOD';
    if (rating >= 2.5) return 'AVERAGE';
    return 'POOR';
  }

  /// Helper untuk menghitung pengalaman
  String _getSinceText(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;

    if (years > 0) {
      return '$years yr ${months > 0 ? '$months mo ' : ''}';
    } else if (months > 0) {
      return '$months mo';
    } else {
      return '${difference.inDays} d';
    }
  }

  /// Widget untuk menampilkan state kosong pada list
  Widget _buildEmptyStateForList(
      {bool isDriver = false, bool isVehicle = false, bool isRoom = false}) {
    String title = 'No Technicians Found';
    String description = 'There are no technicians available.';
    IconData icon = Icons.engineering_outlined;

    if (isDriver) {
      title = 'No Drivers Found';
      description = 'There are no drivers available.';
      icon = Icons.person_off_outlined;
    } else if (isVehicle) {
      title = 'No Vehicles Found';
      description = 'There are no vehicles available.';
      icon = Icons.no_transfer_outlined;
    } else if (isRoom) {
      title = 'No Rated Bookings';
      description = 'No room bookings have been rated yet.';
      icon = Icons.rate_review_outlined;
    }

    if (_searchQuery.isNotEmpty) {
      description = 'No data matches your search query.';
      icon = Icons.search_off;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
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
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedAppCard extends StatefulWidget {
  const _AnimatedAppCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_AnimatedAppCard> createState() => _AnimatedAppCardState();
}

class _AnimatedAppCardState extends State<_AnimatedAppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.95 : 1.0;
    final bgColor = Color.lerp(Colors.white, widget.color, 0.30)!;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 150),
      curve: Curves.fastOutSlowIn,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (isHighlighted) {
            setState(() {
              _isPressed = isHighlighted;
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(5, 10),
                ),
              ],
              border: Border.all(
                color: widget.color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, size: 32, color: widget.color),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.color.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: widget.color,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
