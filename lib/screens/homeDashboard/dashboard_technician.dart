import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/services/statusNotifications/notif_status_helper.dart';
import 'package:masbro_inpower_app/models/maintenanceApp/task_model.dart'
    as maintenance_task;
import 'package:masbro_inpower_app/models/operasionalApp/ride_request_model.dart'
    as operasional_task;
import 'package:masbro_inpower_app/models/resourceApp/task_model.dart'
    as resource_task;
import 'package:masbro_inpower_app/models/user_model.dart';
import 'package:masbro_inpower_app/screens/technician/maintenanceApp/technician_dashboard.dart';
import 'package:masbro_inpower_app/screens/technician/operasionalApp/driver_dashboard.dart';
import 'package:masbro_inpower_app/screens/technician/resourceApp/technician_dashboard.dart';
import 'package:masbro_inpower_app/services/auth_service.dart';
import 'package:masbro_inpower_app/services/maintenanceApp/firestore_service.dart'
    as maintenance_service;
import 'package:masbro_inpower_app/services/operasionalApp/firestore_service.dart'
    as operasional_service;
import 'package:masbro_inpower_app/services/resourceApp/firestore_service.dart'
    as resource_service;
import 'package:masbro_inpower_app/screens/homeDashboard/list_notifications.dart';
import 'package:masbro_inpower_app/services/notification_list_service.dart';
import 'package:badges/badges.dart' as badges;
import 'package:masbro_inpower_app/services/user_service.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import 'package:masbro_inpower_app/services/statusNotifications/notif_status_helper.dart';
import 'package:provider/provider.dart';
import '../../../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:ui'; // Needed for ImageFilter
import 'package:rxdart/rxdart.dart';

class HomeDashboardTechnician extends StatefulWidget {
  final int initialTabIndex;

  const HomeDashboardTechnician({super.key, this.initialTabIndex = 0});

  @override
  State<HomeDashboardTechnician> createState() =>
      _HomeDashboardTechnicianState();
}

class _HomeDashboardTechnicianState extends State<HomeDashboardTechnician>
    with SingleTickerProviderStateMixin {
  UserModel? currentUser;
  final _searchController = TextEditingController();
  late TabController _tabController;

  late final NotificationListService _notificationListService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _notificationListService = NotificationListService();
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
          : NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
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
                        final delta = settings.maxExtent - settings.minExtent;
                        final opacity = (1.0 -
                                (settings.currentExtent - settings.minExtent) /
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
                                  'Technician Dashboard',
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
                        Tab(icon: Icon(Icons.list_alt)),
                        Tab(icon: Icon(Icons.apps)),
                      ],
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(width: 4.0, color: Colors.white),
                        insets: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                    ),
                  )
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  TechnicianStatusTab(currentUser: currentUser!),
                  _buildAppGrid(context),
                ],
              ),
            ),
    );
  }

  Widget _buildLoading() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0277BD),
            Color(0xFF0288D1),
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
            const Text(
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
                                'Technician Dashboard',
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
                                          'Technician since ${DateFormat('dd MMM yyyy').format(currentUser!.createdAt)}',
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
                MaterialPageRoute(builder: (context) => TechnicianDashboard()),
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
                    builder: (context) => TechnicianDashboardResource()),
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
                MaterialPageRoute(builder: (context) => DriverDashboard()),
              );
            },
          ),
          _AnimatedAppCard(
            title: 'Booking Room',
            icon: Icons.meeting_room,
            color: Colors.grey[700]!, // Greyed out color
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'This application is not available for Technicians.'),
                  backgroundColor: Colors.blueGrey,
                ),
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
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color:
  //                     Colors.white.withOpacity(0.5), // Background lebih terang
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Text(
  //                 'Open',
  //                 style: TextStyle(
  //                   fontSize: 11,
  //                   fontWeight: FontWeight.w600,
  //                   color: color, // Warna teks yang sama dengan ikon
  //                 ),
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
                'Technician since',
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

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 18),
          if (icon != null) const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}

class TechnicianStatusTab extends StatefulWidget {
  final UserModel currentUser;
  const TechnicianStatusTab({super.key, required this.currentUser});

  @override
  State<TechnicianStatusTab> createState() => _TechnicianStatusTabState();
}

class _TechnicianStatusTabState extends State<TechnicianStatusTab>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final TextEditingController _searchController = TextEditingController();
  final _completionMaintncNoteController = TextEditingController();
  final _completionResourceNoteController = TextEditingController();
  final _completionRideNoteController = TextEditingController();

  final _maintenanceFirestoreService = maintenance_service.FirestoreService();
  final _resourceFirestoreService = resource_service.FirestoreServiceResource();
  final _operasionalFirestoreService =
      operasional_service.OperasionalFirestoreService();

  String _searchQuery = '';
  List<dynamic> _combinedList = [];
  List<dynamic> _filteredList = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  bool _isSearching = false;
  final StorageService _storageService = StorageService();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  File? _afterImageFile;
  Uint8List? _afterImageBytes;
  XFile? _pickedFile;
  String? _afterImageName;
  bool _hasSelectedImage = false;

  int _currentPage = 1;
  final int _itemsPerPage = 5;

  StreamSubscription? _dataSubscription;

  // Helper function untuk memilih gambar
  Future<void> _pickImageReport() async {
    try {
      setState(() {
        _afterImageFile = null;
        _afterImageBytes = null;
        _pickedFile = null;
        _afterImageName = null;
        _hasSelectedImage = false;
      });

      final XFile? pickedImage = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _pickedFile = pickedImage;
          _afterImageName = pickedImage.name;
          _hasSelectedImage = true;
          if (!kIsWeb) {
            _afterImageFile = File(pickedImage.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper function untuk mengunggah gambar ke Firebase Storage
  Future<String?> _uploadAfterImage(String taskId) async {
    if (!_hasSelectedImage || _pickedFile == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'maintenance/tasks/$taskId/after_$timestamp.jpg';

      if (kIsWeb) {
        _afterImageBytes ??= await _pickedFile!.readAsBytes();
        return await _storageService.uploadWebFile(_afterImageBytes!, path);
      } else {
        if (_afterImageFile != null) {
          return await _storageService.uploadFile(_afterImageFile!, path);
        }
      }
      return null;
    } catch (e) {
      print('Error uploading after image: $e');
      rethrow;
    }
  }

  // Helper function untuk menampilkan preview gambar
  Widget _buildImagePreview() {
    if (!_hasSelectedImage) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey[500]),
          const SizedBox(height: 8),
          Text('Tap to add a photo',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      );
    }
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: _pickedFile!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _afterImageBytes = snapshot.data;
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      return Image.file(_afterImageFile!, fit: BoxFit.cover);
    }
  }

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 2, vsync: this);
    _listenToDataStreams();
    _searchController.addListener(_onSearchChanged);
    _statusTabController.addListener(_filterData); // Re-filter on tab change
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _statusTabController.dispose();
    _searchController.dispose();
    _completionMaintncNoteController.dispose();
    _completionResourceNoteController.dispose();
    _completionRideNoteController.dispose();
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

  Future<void> _pickImageResource(
      ImageSource source, StateSetter setStateDialog) async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setStateDialog(() {
            _selectedImage = pickedFile;
            _selectedImageBytes = bytes;
          });
        } else {
          setStateDialog(() {
            _selectedImage = pickedFile;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  Future<void> _fetchData() async {
    // Tampilkan loading, meskipun RefreshIndicator sudah punya UI sendiri
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final String technicianId = widget.currentUser.uid;

    try {
      // Ambil data terbaru satu kali dari semua sumber
      final maintenanceFuture =
          _maintenanceFirestoreService.getTasksByTechnician(technicianId).first;
      final resourceFuture =
          _resourceFirestoreService.getTasksByTechnician(technicianId).first;
      final operationalFuture = _operasionalFirestoreService
          .getRideRequestsByDriver(technicianId)
          .first;

      final results = await Future.wait([
        maintenanceFuture,
        resourceFuture,
        operationalFuture,
      ]);

      // Proses dan perbarui UI sama seperti logika sebelumnya
      if (mounted) {
        final maintenanceTasks = results[0] as List<maintenance_task.TaskModel>;
        final resourceTasks = results[1] as List<resource_task.TaskModel>;
        final operationalRequests =
            results[2] as List<operasional_task.RideRequestModel>;

        setState(() {
          _combinedList = [
            ...maintenanceTasks,
            ...resourceTasks,
            ...operationalRequests,
          ];
          _combinedList.sort((a, b) {
            DateTime dateA = a is operasional_task.RideRequestModel
                ? a.assignedAt!
                : (a as dynamic).assignedAt;
            DateTime dateB = b is operasional_task.RideRequestModel
                ? b.assignedAt!
                : (b as dynamic).assignedAt;
            return dateB.compareTo(dateA);
          });
          _filterData();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Tangani jika ada error saat refresh manual
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
    final String technicianId = widget.currentUser.uid;

    // Menggabungkan 3 stream tugas menjadi satu
    _dataSubscription = CombineLatestStream.combine3(
      _maintenanceFirestoreService.getTasksByTechnician(technicianId),
      _resourceFirestoreService.getTasksByTechnician(technicianId),
      _operasionalFirestoreService.getRideRequestsByDriver(technicianId),
      (List<maintenance_task.TaskModel> maintenance,
          List<resource_task.TaskModel> resource,
          List<operasional_task.RideRequestModel> operational) {
        // Fungsi ini akan menggabungkan hasil dari ketiga stream
        return [maintenance, resource, operational];
      },
    ).listen((data) {
      // .listen akan terpanggil setiap kali ada perubahan data
      if (!mounted) return;

      final maintenanceTasks = data[0] as List<maintenance_task.TaskModel>;
      final resourceTasks = data[1] as List<resource_task.TaskModel>;
      final operationalRequests =
          data[2] as List<operasional_task.RideRequestModel>;

      setState(() {
        _combinedList = [
          ...maintenanceTasks,
          ...resourceTasks,
          ...operationalRequests,
        ];
        _combinedList.sort((a, b) {
          DateTime dateA = a is operasional_task.RideRequestModel
              ? a.assignedAt!
              : (a as dynamic).assignedAt;
          DateTime dateB = b is operasional_task.RideRequestModel
              ? b.assignedAt!
              : (b as dynamic).assignedAt;
          return dateB.compareTo(dateA);
        });
        _filterData();
        _isLoading = false;
      });
    });
  }

  void _filterData() {
    List<dynamic> tempFiltered = _combinedList;
    final now = DateTime.now();

    // 1. Filter by Tab Status (In Progress vs. Completed)
    final isProgressTab = _statusTabController.index == 0;
    if (isProgressTab) {
      tempFiltered = tempFiltered
          .where((item) =>
              item.status == 'inProgress' || item.status == 'in_progress')
          .toList();
    } else {
      tempFiltered =
          tempFiltered.where((item) => item.status == 'completed').toList();
    }

    // 2. Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      tempFiltered = tempFiltered.where((item) {
        if (item is maintenance_task.TaskModel) {
          return item.roomName.toLowerCase().contains(_searchQuery) ||
              item.itemName.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery);
        } else if (item is resource_task.TaskModel) {
          return item.description.toLowerCase().contains(_searchQuery) ||
              (item.timeRequired?.toLowerCase().contains(_searchQuery) ??
                  false);
        } else if (item is operasional_task.RideRequestModel) {
          return item.pickupLocation.toLowerCase().contains(_searchQuery) ||
              item.dropoffLocation.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery) ||
              item.employeeName.toLowerCase().contains(_searchQuery);
        }
        return false;
      }).toList();
    }

    // 3. Filter by Time
    if (_selectedFilter != 'all') {
      tempFiltered = tempFiltered.where((item) {
        DateTime? relevantDate;
        if (item.status == 'completed' && item.completedAt != null) {
          relevantDate = item.completedAt;
        } else if ((item.status == 'inProgress' ||
                item.status == 'in_progress') &&
            item.assignedAt != null) {
          relevantDate = item.assignedAt;
        }

        if (relevantDate == null) return false;

        switch (_selectedFilter) {
          case 'today':
            return relevantDate.year == now.year &&
                relevantDate.month == now.month &&
                relevantDate.day == now.day;
          case 'week':
            return now.difference(relevantDate).inDays < 7 &&
                relevantDate.isBefore(now);
          case 'month':
            return relevantDate.year == now.year &&
                relevantDate.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    setState(() {
      _filteredList = tempFiltered;
      _currentPage = 1;
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
              'Loading your tasks...',
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
                  tabs: const [
                    Tab(text: 'In Progress'),
                    Tab(text: 'Completed'),
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
              height: MediaQuery.of(context).size.height * 0.4,
              child: _buildEmptyState(),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ...paginatedList.map((item) {
                    if (item is maintenance_task.TaskModel) {
                      return _buildUnifiedMaintenanceTaskCard(item);
                    } else if (item is resource_task.TaskModel) {
                      return _buildUnifiedResourceTaskCard(item);
                    } else if (item is operasional_task.RideRequestModel) {
                      return _buildUnifiedRideRequestCard(item);
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

  Widget _buildStatisticsCards() {
    final inProgressCount = _combinedList
        .where((item) =>
            item.status == 'inProgress' || item.status == 'in_progress')
        .length;
    final completedCount =
        _combinedList.where((item) => item.status == 'completed').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'In Progress',
              count: inProgressCount,
              icon: Icons.sync_outlined,
              color: Colors.purple.shade800,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Completed',
              count: completedCount,
              icon: Icons.check_circle_outline,
              color: Colors.green.shade800,
              backgroundColor: Colors.white,
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
                hintText: 'Find your task here...',
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

    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        text = 'IN PROGRESS';
        color = Colors.blue.shade700;
        backgroundColor = Colors.blue.withOpacity(0.1);
        break;
      case 'completed':
        text = 'COMPLETED';
        color = Colors.green.shade700;
        backgroundColor = Colors.green.withOpacity(0.1);
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

  // --- NEW UNIFIED TASK CARDS ---

  Widget _buildUnifiedMaintenanceTaskCard(maintenance_task.TaskModel task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _showTaskDetailMaintenance(task),
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.construction,
                          color: Colors.orange[700], size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Maintenance Task',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 2),
                          _buildStatusChip(task.status),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey[400]),
                  ],
                ),
                if (task.imageUrl != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FirebaseStorageImage(
                        imageUrl: task.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${task.roomName}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                _buildCompactInfoRow(
                  Icons.access_time,
                  'Assigned: ${DateFormat('dd MMM').format(task.assignedAt)}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedResourceTaskCard(resource_task.TaskModel task) {
    final bool isResourceRequest = task.request == 'resource';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _showTaskDetailResource(task),
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isResourceRequest
                            ? Icons.supervisor_account
                            : Icons.inventory,
                        size: 18,
                        color: Colors.cyan[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resource/Item Task',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 2),
                          _buildStatusChip(task.status),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 8),
                if (!isResourceRequest && task.hasValidImage()) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FirebaseStorageImage(
                        imageUrl: task.getNormalizedImageUrl(),
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: Colors.grey[200],
                          child:
                              const Center(child: CircularProgressIndicator()),
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
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                _buildCompactInfoRow(
                  Icons.person_outline,
                  'Requester: ${task.requesterName}',
                ),
                if (task.timeRequired != null && task.timeRequired!.isNotEmpty)
                  _buildCompactInfoRow(
                    Icons.calendar_today_outlined,
                    'Time: ${task.timeRequired!}',
                  ),
                _buildCompactInfoRow(
                  Icons.access_time,
                  'Assigned: ${DateFormat('dd MMM').format(task.assignedAt)}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedRideRequestCard(
      operasional_task.RideRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _showRequestDetailRide(request),
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.directions_car,
                          color: Colors.red[700], size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Operational Ride',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 2),
                          _buildStatusChip(request.status),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCompactInfoRow(
                  Icons.my_location,
                  'From: ${request.pickupLocation}',
                ),
                _buildCompactInfoRow(
                  Icons.location_on_outlined,
                  'To: ${request.dropoffLocation}',
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Requester: ${request.employeeName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                _buildCompactInfoRow(
                  Icons.event,
                  'Pickup: ${DateFormat('dd MMM, HH:mm').format(request.pickupDateTime)}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetailMaintenance(maintenance_task.TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
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
                  const Text(
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
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 20),
                    if (task.imageUrl != null) ...[
                      const Text(
                        'Issue Photo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
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
                      const SizedBox(height: 20),
                    ],
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                    if (task.status == 'completed' &&
                        task.completionNote != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Completion Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                      // Show after image if available
                      if (task.afterImageUrl != null &&
                          task.afterImageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Completion Photo:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showFullScreenImage(
                              context, task.afterImageUrl!),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                task.afterImageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.green),
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
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (task.status == 'inProgress' || task.status == 'in_progress')
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  text: 'Mark as Completed',
                  onPressed: () {
                    Navigator.pop(context);
                    _showCompleteDialogMaintenance(task);
                  },
                  backgroundColor: Colors.green,
                ),
              ),
            if (task.status == 'completed')
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_return),
                  label: const Text('Back to Tasks'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 12),
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
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

  void _showTaskDetailResource(resource_task.TaskModel task) {
    final bool isResourceRequest = task.request == 'resource';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  const Text(
                    'Task Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(
                            'Need',
                            '${task.request[0].toUpperCase()}${task.request.substring(1)}',
                            task.request == 'resource'
                                ? Icons.supervisor_account
                                : Icons.inventory,
                          ),
                          _buildDetailItem(
                              'Requester', task.requesterName, Icons.person),
                          if (task.timeRequired != null &&
                              task.timeRequired!.isNotEmpty)
                            _buildDetailItem('Time Required',
                                task.timeRequired!, Icons.calendar_today),
                          _buildDetailItem(
                            'Assigned',
                            DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                                .format(task.assignedAt),
                            Icons.access_time,
                          ),
                          if (task.status == 'completed' &&
                              task.completedAt != null)
                            _buildDetailItem(
                              'Finished',
                              DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID')
                                  .format(task.completedAt!),
                              Icons.check_circle,
                            ),
                        ],
                      ),
                    ),
                    if (!isResourceRequest && task.hasValidImage()) ...[
                      const SizedBox(height: 24),
                      const Text('Item Photo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          _showFullScreenImage(
                              context, task.getNormalizedImageUrl()!);
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FirebaseStorageImage(
                                  imageUrl: task.getNormalizedImageUrl(),
                                  fit: BoxFit.cover,
                                  placeholder: Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey[400]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.zoom_in,
                                  color: Colors.white, size: 32),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Task Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                    if (task.status == 'completed' &&
                        task.completionNote != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Your Completion Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                      if (task.afterImageUrl != null &&
                          task.afterImageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Completion Photo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showFullScreenImage(
                              context, task.afterImageUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: FirebaseStorageImage(
                                imageUrl: task.afterImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            if (task.status == 'inProgress' || task.status == 'in_progress')
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  text: 'Mark Complete',
                  onPressed: () {
                    _showCompleteDialogResource(task);
                  },
                  backgroundColor: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
            if (task.status == 'completed')
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_return),
                  label: const Text('Back to Tasks'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
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

  void _showRequestDetailRide(operasional_task.RideRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  const Text(
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
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 20),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                    if (request.status == 'completed' &&
                        request.completionNote != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Completion Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (request.status == 'inProgress' ||
                request.status == 'in_progress')
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  text: 'Mark as Completed',
                  onPressed: () {
                    Navigator.pop(context);
                    _showCompleteDialogRide(request);
                  },
                  backgroundColor: Colors.green,
                ),
              ),
            if (request.status == 'completed')
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_return),
                  label: const Text('Back to Rides'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
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

  void _showCompleteDialogMaintenance(maintenance_task.TaskModel task) {
    final _formKey = GlobalKey<FormState>();
    _completionMaintncNoteController.clear();
    setState(() {
      _afterImageFile = null;
      _afterImageBytes = null;
      _pickedFile = null;
      _afterImageName = null;
      _hasSelectedImage = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Form(
          // Tambahkan Form
          key: _formKey,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mark Task as Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Room: ${task.roomName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Details Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue[300]!),
                              ),
                              child: Text('1',
                                  style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Text('Completion Details',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800])),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('What work was done?',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        TextFormField(
                          // Ganti CustomTextField dengan TextFormField untuk validasi
                          controller: _completionMaintncNoteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Describe how you resolved the issue...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          validator: (value) {
                            // Tambahkan validator
                            if (value == null || value.trim().isEmpty) {
                              return 'Completion notes cannot be empty.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Photo Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue[300]!),
                              ),
                              child: Text('2',
                                  style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Text('Completion Photo',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Add a photo showing the completed work',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.grey[700])),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            await _pickImageReport();
                            setStateDialog(() {});
                          },
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _hasSelectedImage
                                      ? Colors.blue[400]!
                                      : Colors.grey[300]!,
                                  width: _hasSelectedImage ? 2 : 1),
                            ),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImagePreview()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[400]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _completeTaskMaintnc(task);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.white),
                          label: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white)))
                              : const Text('Mark as Completed',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16)),
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
    );
  }

  Future<void> _completeTaskMaintnc(maintenance_task.TaskModel task) async {
    // Validasi sudah dipindahkan ke tombol onPressed, namun bisa ditambahkan double check
    if (_completionMaintncNoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Completion notes cannot be empty.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!_hasSelectedImage) {
      // Confirm if they want to proceed without an image
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No Photo Added'),
          content: Text(
              'Are you sure you want to complete the task without adding a photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No, I\'ll add a photo'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes, proceed anyway'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() => _isLoading = true);
    Navigator.pop(context); // Close bottom sheet

    try {
      String? afterImageUrl;
      if (_hasSelectedImage) {
        afterImageUrl = await _uploadAfterImage(task.id);
      }

      // Gunakan service yang benar
      await _maintenanceFirestoreService.completeTaskWithImage(
        taskId: task.id,
        reportId: task.reportId,
        completionNote: _completionMaintncNoteController.text.trim(),
        afterImageUrl: afterImageUrl ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task marked as completed'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCompleteDialogResource(resource_task.TaskModel task) {
    _completionResourceNoteController.clear();
    _selectedImage = null;
    _selectedImageBytes = null;
    String? dialogErrorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Complete the Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      labelText: 'Completion Notes',
                      hintText: 'Enter task notes...',
                      controller: _completionResourceNoteController,
                      maxLines: 3,
                    ),
                    if (task.request == 'item') ...[
                      const SizedBox(height: 16),
                      Text('Item Photo (Optional)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? (_selectedImageBytes != null
                                  ? Image.memory(_selectedImageBytes!,
                                      fit: BoxFit.cover)
                                  : Center(
                                      child: Icon(
                                          Icons.photo_camera_back_outlined,
                                          color: Colors.grey[400],
                                          size: 40)))
                              : (_selectedImage != null
                                  ? Image.file(File(_selectedImage!.path),
                                      fit: BoxFit.cover)
                                  : Center(
                                      child: Icon(
                                          Icons.photo_camera_back_outlined,
                                          color: Colors.grey[400],
                                          size: 40))),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            onPressed: () => _pickImageResource(
                                ImageSource.gallery, setStateDialog),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            onPressed: () => _pickImageResource(
                                ImageSource.camera, setStateDialog),
                          ),
                        ],
                      ),
                    ],
                    if (dialogErrorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dialogErrorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ]
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
                    if (_completionResourceNoteController.text.trim().isEmpty) {
                      setStateDialog(() {
                        dialogErrorText = 'Please provide completion notes';
                      });
                    } else {
                      _completeTaskResource(task);
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
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

  Future<void> _completeTaskResource(resource_task.TaskModel task) async {
    Navigator.pop(context);
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    String? imageUrl;
    try {
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadImage(
            _selectedImage!, 'completed_items');
        if (imageUrl == null) {
          throw Exception('Failed to upload image.');
        }
      }
      await _resourceFirestoreService.updateTaskStatus(
        task.id,
        'completed',
        completionNote: _completionResourceNoteController.text.trim(),
        afterImageUrl: imageUrl,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task successfully completed!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedImage = null;
          _selectedImageBytes = null;
        });
        _fetchData();
      }
    }
  }

  void _showCompleteDialogRide(operasional_task.RideRequestModel task) {
    _completionRideNoteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Ride as Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide completion notes:'),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Completion Notes',
              hintText: 'Enter notes about the completed ride...',
              controller: _completionRideNoteController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _completionRideNoteController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _completeRequestRide(task),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  )
                : const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRequestRide(
      operasional_task.RideRequestModel task) async {
    if (_completionRideNoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide completion notes'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Navigator.pop(context); // Close dialog first

    try {
      await _operasionalFirestoreService.completeRideRequest(
        task.id,
        _completionRideNoteController.text.trim(),
        driverId: task.driverId,
        vehicleId: task.vehicleId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing ride: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fetchData(); // Refresh the list
      }
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
