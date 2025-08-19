import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/services/statusNotifications/notif_status_helper.dart';
import 'package:masbro_inpower_app/models/maintenanceApp/report_model.dart';
import 'package:masbro_inpower_app/models/resourceApp/request_model.dart';
import 'package:masbro_inpower_app/models/operasionalApp/ride_request_model.dart';
import 'package:masbro_inpower_app/models/bookingroomApp/booking_model.dart';
import 'package:masbro_inpower_app/models/user_model.dart';
import 'package:masbro_inpower_app/screens/employee/bookingroomApp/employee_dashboard.dart';
import 'package:masbro_inpower_app/screens/employee/maintenanceApp/employee_dashboard.dart';
import 'package:masbro_inpower_app/screens/employee/operasionalApp/employee_dashboard.dart';
import 'package:masbro_inpower_app/screens/employee/resourceApp/employee_dashboard.dart';
import 'package:masbro_inpower_app/screens/employee/maintenanceApp/report_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/resourceApp/request_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/operasionalApp/ride_request_detail_screen.dart';
import 'package:masbro_inpower_app/screens/employee/bookingroomApp/booking_detail_screen.dart';
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
import 'dart:ui';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class HomeDashboardUser extends StatefulWidget {
  const HomeDashboardUser({super.key});

  @override
  State<HomeDashboardUser> createState() => _HomeDashboardUserState();
}

class _HomeDashboardUserState extends State<HomeDashboardUser>
    with SingleTickerProviderStateMixin {
  UserModel? currentUser;
  final _searchController = TextEditingController();
  late TabController _tabController;
  late ScrollController _scrollController;
  double _headerHeight = 300.0;
  bool _showFloatingSearchBar = false;

  late final NotificationListService _notificationListService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _notificationListService = NotificationListService();
    _loadUserData();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.offset > 60 && !_showFloatingSearchBar) {
        setState(() {
          _showFloatingSearchBar = true;
        });
      } else if (_scrollController.offset <= 60 && _showFloatingSearchBar) {
        setState(() {
          _showFloatingSearchBar = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
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
      extendBodyBehindAppBar: true,
      body: currentUser == null
          ? _buildLoading()
          : Stack(
              children: [
                NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return <Widget>[
                      SliverAppBar(
                        backgroundColor: const Color(0xFF0277BD),
                        expandedHeight: 350.0,
                        floating: false,
                        pinned: true,
                        automaticallyImplyLeading: false,
                        stretch: true,
                        title: LayoutBuilder(
                          builder: (context, constraints) {
                            final settings =
                                context.dependOnInheritedWidgetOfExactType<
                                    FlexibleSpaceBarSettings>()!;
                            final delta =
                                settings.maxExtent - settings.minExtent;
                            final opacity = (1.0 -
                                    (settings.currentExtent -
                                            settings.minExtent) /
                                        delta)
                                .clamp(0.0, 1.0);

                            return Opacity(
                              opacity: opacity,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      'Home Dashboard',
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
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(48.0),
                          child: TabBar(
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
                            ],
                            indicator: const UnderlineTabIndicator(
                              borderSide:
                                  BorderSide(width: 4.0, color: Colors.white),
                              insets: EdgeInsets.symmetric(horizontal: 16.0),
                            ),
                          ),
                        ),
                      )
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      StatusTab(currentUser: currentUser!),
                      _buildAppGrid(context),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoading() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0277BD),
            const Color(0xFF0288D1),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Loading Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait a moment',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<int>(
          stream: _notificationListService.getUnreadCountStream(),
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
            Color.fromARGB(255, 25, 115, 184), // Darker blue
            Color(0xFF0288D1), // Material blue
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circle elements
          Positioned(
            right: -60,
            top: -30,
            child: Container(
              width: 220,
              height: 220,
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
            left: -80,
            bottom: -40,
            child: Container(
              width: 180,
              height: 180,
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
            right: 40,
            bottom: 100,
            child: Container(
              width: 40,
              height: 40,
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

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                        // Header with title and profile
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
                                'Home Dashboard',
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
                        const SizedBox(height: 30),

                        // User welcome section with glass effect
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
                                      fontSize: 28,
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
                                          'Member since ${DateFormat('dd MMM yyyy').format(currentUser!.createdAt)}',
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

                        // Search bar
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
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
      padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
      child: GridView.count(
        padding: const EdgeInsets.fromLTRB(6, 30, 6, 30),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _AnimatedAppCard(
            title: 'Maintenance',
            icon: Icons.construction,
            color: Colors.orange[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmployeeDashboard()),
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
                    builder: (context) => EmployeeDashboardResource()),
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
                    builder: (context) => EmployeeDashboardOprational()),
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
                    builder: (context) => EmployeeDashboardBookingRoom()),
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
  //   // Buat versi lebih terang dari warna utama untuk background card
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
  //           // Gunakan warna solid (bukan gradasi)
  //           color: bgColor, // Warna solid yang sesuai dengan tema card
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
  //                 color: Colors.white
  //                     .withOpacity(0.7), // Background putih semi-transparan
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
  //                 color: color.withOpacity(0.9), // Warna teks yang sesuai
  //                 letterSpacing: 0.5,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Container(
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //                 child: Icon(
  //                   Icons.open_in_new,
  //                   size: 16,
  //                   color: color,
  //                 )),
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
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  size: 40,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Logout Confirmation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to log out of this account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Provider.of<AuthService>(context, listen: false)
                          .signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusTab extends StatefulWidget {
  final UserModel currentUser;
  const StatusTab({super.key, required this.currentUser});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  List<dynamic> _combinedList = [];
  List<dynamic> _filteredList = [];
  bool _isLoading = true;
  bool _isSearching = false;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 2, vsync: this);
    _listenToDataStreams();
    _searchController.addListener(_onSearchChanged);
    _statusTabController.addListener(_filterByStatus);
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _statusTabController.dispose();
    _searchController.dispose();
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.filter_list,
                        color: Colors.blue[700], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filter By Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFilterOption('All Time', 'all'),
              _buildFilterOption('Today', 'today'),
              _buildFilterOption('This Week', 'week'),
              _buildFilterOption('This Month', 'month'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, String value) {
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = value);
        _filterData();
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              _selectedFilter == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _selectedFilter == value
                  ? Theme.of(context).primaryColor
                  : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                fontWeight: _selectedFilter == value
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchData() async {
    // Fungsi ini sekarang hanya untuk refresh manual (tarik ke bawah)
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

      final reportsFuture =
          maintenanceService.getReportsByEmployee(widget.currentUser.uid).first;
      final requestsFuture =
          resourceService.getRequestsByEmployee(widget.currentUser.uid).first;
      final operationalFuture = operasionalService
          .getRideRequestsByEmployee(widget.currentUser.uid)
          .first;
      final bookingFuture =
          bookingService.getBookingsByEmployee(widget.currentUser.uid).first;

      final results = await Future.wait([
        reportsFuture,
        requestsFuture,
        operationalFuture,
        bookingFuture,
      ]);

      if (mounted) {
        final reports = results[0] as List<ReportModel>;
        final requests = results[1] as List<RequestModel>;
        final operationalRequests = results[2] as List<RideRequestModel>;
        final bookingRequests = results[3] as List<BookingModel>;

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
    setState(() => _isLoading = true);

    final maintenanceService = maintenance_service.FirestoreService();
    final resourceService = resource_service.FirestoreServiceResource();
    final operasionalService =
        operasional_service.OperasionalFirestoreService();
    final bookingService = booking_service.FirestoreService();

    _dataSubscription = CombineLatestStream.combine4(
      maintenanceService.getReportsByEmployee(widget.currentUser.uid),
      resourceService.getRequestsByEmployee(widget.currentUser.uid),
      operasionalService.getRideRequestsByEmployee(widget.currentUser.uid),
      bookingService.getBookingsByEmployee(widget.currentUser.uid),
      (List<ReportModel> reports, List<RequestModel> requests,
          List<RideRequestModel> operational, List<BookingModel> bookings) {
        return [reports, requests, operational, bookings];
      },
    ).listen((data) {
      if (!mounted) return;

      final reports = data[0] as List<ReportModel>;
      final requests = data[1] as List<RequestModel>;
      final operationalRequests = data[2] as List<RideRequestModel>;
      final bookingRequests = data[3] as List<BookingModel>;

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
        _filterData();
        _isLoading = false;
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
              item.description.toLowerCase().contains(_searchQuery);
        } else if (item is RequestModel) {
          return item.description.toLowerCase().contains(_searchQuery) ||
              (item.timeRequired?.toLowerCase().contains(_searchQuery) ??
                  false);
        } else if (item is RideRequestModel) {
          return item.pickupLocation.toLowerCase().contains(_searchQuery) ||
              item.dropoffLocation.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery);
        } else if (item is BookingModel) {
          return item.roomName.toLowerCase().contains(_searchQuery) ||
              item.eventAgenda.toLowerCase().contains(_searchQuery);
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

  void _navigateToDetail(dynamic item) {
    if (item is ReportModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportDetailScreen(report: item),
        ),
      );
    } else if (item is RequestModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequestDetailScreen(request: item),
        ),
      );
    } else if (item is RideRequestModel) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RideRequestDetailScreen(request: item)));
    } else if (item is BookingModel) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BookingDetailScreen(booking: item)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedList =
        _filteredList.take(_currentPage * _itemsPerPage).toList();

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your requests...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: Theme.of(context).primaryColor,
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
                  TextButton.icon(
                    onPressed: _clearSearch,
                    icon: Icon(Icons.clear, color: Colors.blue[700], size: 16),
                    label: Text(
                      'Clear',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedFilter != 'all')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.purple.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.purple[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Filtered by: ${_getFilterName(_selectedFilter)}',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _clearTimeFilter,
                    icon:
                        Icon(Icons.clear, color: Colors.purple[700], size: 16),
                    label: Text(
                      'Clear',
                      style: TextStyle(color: Colors.purple[700]),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      return _buildUnifiedReportCard(item);
                    } else if (item is RequestModel) {
                      return _buildUnifiedRequestCard(item);
                    } else if (item is RideRequestModel) {
                      return _buildUnifiedOperasionalCard(item);
                    } else if (item is BookingModel) {
                      return _buildUnifiedBookingCard(item);
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
                          label: const Text('Load More'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Theme.of(context).primaryColor,
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

  String _getFilterName(String filterValue) {
    switch (filterValue) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      default:
        return 'All Time';
    }
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
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
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'In Progress',
              count: inProgressCount,
              icon: Icons.sync_outlined,
              color: Colors.purple.shade800,
              backgroundColor: Colors.white,
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Find the latest status here...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
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
        // Filter Button
        Container(
          decoration: BoxDecoration(
            color: _selectedFilter != 'all'
                ? Colors.purple.withOpacity(0.1)
                : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: _selectedFilter != 'all'
                  ? Colors.purple[700]
                  : Theme.of(context).primaryColor,
            ),
            tooltip: 'Filter By Time',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (actionButton != null) actionButton,
        ],
      ),
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
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2), // Reduced padding
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8), // Smaller border radius
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9, // Smaller font
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUnifiedReportCard(ReportModel report) {
    return _AnimatedListItem(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => _navigateToDetail(report),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.orange.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Added to minimize height
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.construction,
                            color: Colors.orange[700],
                            size: 18), // Smaller icon
                      ),
                      const SizedBox(width: 8), // Reduced spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Report Maintenance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Smaller font
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 2), // Reduced spacing
                            _buildStatusChip(report.status),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey[400]), // Smaller icon
                    ],
                  ),

                  // Optional image with fixed height
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

                  const SizedBox(height: 8), // Reduced spacing

                  // Location info
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey[600]), // Smaller icon
                      const SizedBox(width: 4), // Reduced spacing
                      Expanded(
                        child: Text(
                          '${report.buildingName} - ${report.roomName}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // Smaller font
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6), // Reduced spacing

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      report.description,
                      style: TextStyle(
                        fontSize: 12, // Smaller font
                        color: Colors.grey[700],
                        height: 1.2, // Reduced line height
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 6), // Reduced spacing

                  // Creation time
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey[500]), // Smaller icon
                      const SizedBox(width: 4), // Reduced spacing
                      Expanded(
                        child: Text(
                          'Created: ${DateFormat('dd MMM').format(report.createdAt)}', // Shorter date
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600]), // Smaller font
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Replace the _buildUnifiedRequestCard method with this more compact version:
  Widget _buildUnifiedRequestCard(RequestModel request) {
    final bool isResourceRequest = request.request == 'resource';

    return _AnimatedListItem(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => _navigateToDetail(request),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.cyan.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Added to minimize height
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isResourceRequest
                              ? Icons.supervisor_account
                              : Icons.inventory,
                          size: 18, // Smaller icon
                          color: Colors.cyan[700],
                        ),
                      ),
                      const SizedBox(width: 8), // Reduced spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Request Resource/Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Smaller font
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 2), // Reduced spacing
                            _buildStatusChip(request.status),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey[400]), // Smaller icon
                    ],
                  ),

                  const SizedBox(height: 8), // Reduced spacing

                  // Optional image with fixed height
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

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      request.description,
                      style: TextStyle(
                        fontSize: 12, // Smaller font
                        color: Colors.grey[700],
                        height: 1.2, // Reduced line height
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 6), // Reduced spacing

                  // Info row in two columns
                  Row(
                    children: [
                      // First column
                      Expanded(
                        child: request.request == 'resource'
                            ? _buildCompactInfoRow(
                                Icons.supervisor_account, 'Resource')
                            : _buildCompactInfoRow(Icons.inventory, 'Item'),
                      ),
                      // Second column
                      Expanded(
                        child: _buildCompactInfoRow(
                          Icons.access_time,
                          'Created: ${DateFormat('dd MMM').format(request.createdAt)}', // Shorter date
                        ),
                      ),
                    ],
                  ),

                  // Optional time required
                  if (request.timeRequired != null &&
                      request.timeRequired!.isNotEmpty)
                    _buildCompactInfoRow(
                      Icons.calendar_today_outlined,
                      request.timeRequired!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Replace the _buildUnifiedOperasionalCard method with this more compact version:
  Widget _buildUnifiedOperasionalCard(RideRequestModel request) {
    return _AnimatedListItem(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => _navigateToDetail(request),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.red.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Added to minimize height
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.directions_car,
                            color: Colors.red[700], size: 18), // Smaller icon
                      ),
                      const SizedBox(width: 8), // Reduced spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Request Operasional',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Smaller font
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 2), // Reduced spacing
                            _buildStatusChip(request.status),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey[400]), // Smaller icon
                    ],
                  ),

                  const SizedBox(height: 8), // Reduced spacing

                  // Locations in compact layout
                  Row(
                    children: [
                      // Pickup location
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.my_location,
                                size: 12,
                                color: Colors.grey[600]), // Smaller icon
                            const SizedBox(width: 4), // Reduced spacing
                            Expanded(
                              child: Text(
                                'From: ${request.pickupLocation}',
                                style: TextStyle(
                                  fontSize: 11, // Smaller font
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8), // Reduced spacing
                      // Dropoff location
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12,
                                color: Colors.grey[600]), // Smaller icon
                            const SizedBox(width: 4), // Reduced spacing
                            Expanded(
                              child: Text(
                                'To: ${request.dropoffLocation}',
                                style: TextStyle(
                                  fontSize: 11, // Smaller font
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8), // Reduced spacing

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      request.description,
                      style: TextStyle(
                        fontSize: 12, // Smaller font
                        color: Colors.grey[700],
                        height: 1.2, // Reduced line height
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 6), // Reduced spacing

                  // Dates in two columns
                  Row(
                    children: [
                      // Pickup date
                      Expanded(
                        child: _buildCompactInfoRow(
                          Icons.event,
                          'Pickup: ${DateFormat('dd MMM').format(request.pickupDateTime)}', // Shorter date
                        ),
                      ),
                      // Return date
                      Expanded(
                        child: _buildCompactInfoRow(
                          Icons.event_available,
                          'Return: ${DateFormat('dd MMM').format(request.pickupDateTime)}', // Shorter date
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Replace the _buildUnifiedBookingCard method with this more compact version:
  Widget _buildUnifiedBookingCard(BookingModel booking) {
    return _AnimatedListItem(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => _navigateToDetail(booking),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.teal.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Added to minimize height
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.meeting_room,
                            color: Colors.teal[700], size: 18), // Smaller icon
                      ),
                      const SizedBox(width: 8), // Reduced spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Booking Room',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Smaller font
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 2), // Reduced spacing
                            _buildStatusChip(booking.status),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey[400]), // Smaller icon
                    ],
                  ),

                  const SizedBox(height: 8), // Reduced spacing

                  // Room info in compact layout
                  Row(
                    children: [
                      Icon(Icons.meeting_room_outlined,
                          size: 14, color: Colors.teal[700]), // Smaller icon
                      const SizedBox(width: 6), // Reduced spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.roomName.isEmpty
                                  ? 'Room not specified'
                                  : booking.roomName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12, // Smaller font
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatCompactBookingDuration(
                                booking.usageStartDate,
                                booking.usageEndDate,
                              ),
                              style: TextStyle(
                                fontSize: 11, // Smaller font
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8), // Reduced spacing

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      booking.eventAgenda,
                      style: TextStyle(
                        fontSize: 12, // Smaller font
                        color: Colors.grey[700],
                        height: 1.2, // Reduced line height
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 6), // Reduced spacing

                  // Creation date
                  _buildCompactInfoRow(
                    Icons.access_time,
                    'Created: ${DateFormat('dd MMM').format(booking.createdAt)}', // Shorter date
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Add these new helper methods:

// Helper for compact info rows
  Widget _buildCompactInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]), // Smaller icon
        const SizedBox(width: 4), // Reduced spacing
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 11, color: Colors.grey[600]), // Smaller font
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

// Helper for more compact booking duration format
  String _formatCompactBookingDuration(DateTime start, DateTime end) {
    final isSingleDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (isSingleDay) {
      // Format for single day: "4 Aug, 09:00-11:30"
      final date = DateFormat('d MMM', 'id_ID').format(start);
      final startTime = DateFormat('HH:mm').format(start);
      final endTime = DateFormat('HH:mm').format(end);
      return '$date, $startTime-$endTime';
    } else {
      // Format for multi-day: "4 Aug-6 Aug"
      final startDate = DateFormat('d MMM', 'id_ID').format(start);
      final endDate = DateFormat('d MMM', 'id_ID').format(end);
      return '$startDate to $endDate';
    }
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

class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  const _AnimatedListItem({required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.96 : 1.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.fastOutSlowIn,
        child: widget.child,
      ),
    );
  }
}
