import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_model.dart';
import '../../../models/maintenanceApp/report_model.dart';
import '../../../models/resourceApp/request_model.dart';
import '../../../models/operasionalApp/ride_request_model.dart';
import '../../../models/operasionalApp/vehicle_model.dart';

import '../../../screens/employee/maintenanceApp/report_detail_screen.dart';
import '../../../screens/officer/resourceApp/request_detail_screen.dart';
import '../../../screens/employee/operasionalApp/ride_request_detail_screen.dart';

enum DetailRatingType { technician, driver, vehicle }

class TaskHistoryItem {
  final String taskId;
  final String description;
  final String locationOrRequester;
  final double rating;
  final DateTime completedDate;
  final String appSource;
  final dynamic originalTaskObject;

  TaskHistoryItem({
    required this.taskId,
    required this.description,
    required this.locationOrRequester,
    required this.rating,
    required this.completedDate,
    required this.appSource,
    required this.originalTaskObject,
  });
}

class RatingDetailScreen extends StatefulWidget {
  final dynamic entity; // Bisa UserModel atau VehicleModel
  final DetailRatingType type;
  final Map<String, dynamic>? entityRatingData;

  const RatingDetailScreen({
    super.key,
    required this.entity,
    required this.type,
    this.entityRatingData,
  });

  @override
  State<RatingDetailScreen> createState() => _RatingDetailScreenState();
}

class _RatingDetailScreenState extends State<RatingDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<TaskHistoryItem>> _taskHistoryFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<TaskHistoryItem> _allTasks = [];
  List<TaskHistoryItem> _filteredTasks = [];
  bool _isSearching = false;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _taskHistoryFuture = _fetchTaskHistory();

    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredTasks = _allTasks;
      } else {
        _filteredTasks = _allTasks.where((task) {
          final searchQuery = query.toLowerCase();
          return task.description.toLowerCase().contains(searchQuery) ||
              task.locationOrRequester.toLowerCase().contains(searchQuery) ||
              task.appSource.toLowerCase().contains(searchQuery) ||
              task.rating.toString().contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<List<TaskHistoryItem>> _fetchTaskHistory() async {
    List<TaskHistoryItem> historyItems = [];
    final entity = widget.entity;

    if ((widget.type == DetailRatingType.technician ||
            widget.type == DetailRatingType.driver) &&
        entity is UserModel) {
      if (widget.type == DetailRatingType.technician) {
        final maintenanceRatingsSnap = await _firestore
            .collection('technician_ratings')
            .where('technicianId', isEqualTo: entity.uid)
            .get();
        final resourceRatingsSnap = await _firestore
            .collection('technician_ratings_resource')
            .where('technicianId', isEqualTo: entity.uid)
            .get();
        final reportIds = maintenanceRatingsSnap.docs
            .map((doc) => doc.data()['reportId'] as String)
            .toSet();
        final requestIds = resourceRatingsSnap.docs
            .map((doc) => doc.data()['requestId'] as String)
            .toSet();

        if (reportIds.isNotEmpty) {
          final reportDetailsSnap = await _firestore
              .collection('reports')
              .where(FieldPath.documentId, whereIn: reportIds.toList())
              .get();
          final reportDetails = reportDetailsSnap.docs
              .map((d) => ReportModel.fromFirestore(d))
              .toList();
          for (var report in reportDetails) {
            if (report.technicianRating != null &&
                report.completionDate != null) {
              historyItems.add(TaskHistoryItem(
                  taskId: report.id,
                  description: report.description,
                  locationOrRequester:
                      '${report.buildingName} - ${report.roomName}',
                  rating: report.technicianRating!,
                  completedDate: report.completionDate!,
                  appSource: 'maintenance',
                  originalTaskObject: report));
            }
          }
        }

        if (requestIds.isNotEmpty) {
          final requestDetailsSnap = await _firestore
              .collection('requests_resource')
              .where(FieldPath.documentId, whereIn: requestIds.toList())
              .get();
          final requestDetails = requestDetailsSnap.docs
              .map((d) => RequestModel.fromFirestore(d))
              .toList();
          for (var request in requestDetails) {
            if (request.technicianRating != null &&
                request.completionDate != null) {
              historyItems.add(TaskHistoryItem(
                  taskId: request.id,
                  description: request.description,
                  locationOrRequester: 'by ${request.employeeName}',
                  rating: request.technicianRating!,
                  completedDate: request.completionDate!,
                  appSource: 'resource',
                  originalTaskObject: request));
            }
          }
        }
      } else {
        // Driver
        final driverRatingsSnap = await _firestore
            .collection('driver_ratings')
            .where('driverId', isEqualTo: entity.uid)
            .get();
        final requestIds = driverRatingsSnap.docs
            .map((doc) => doc.data()['requestId'] as String)
            .toSet();
        if (requestIds.isNotEmpty) {
          final rideDetailsSnap = await _firestore
              .collection('ride_requests')
              .where(FieldPath.documentId, whereIn: requestIds.toList())
              .get();
          final rideDetails = rideDetailsSnap.docs
              .map((d) => RideRequestModel.fromSnapshot(d))
              .toList();
          for (var ride in rideDetails) {
            if (ride.driverRating != null && ride.completedAt != null) {
              historyItems.add(TaskHistoryItem(
                  taskId: ride.id,
                  description: 'Trip to ${ride.dropoffLocation}',
                  locationOrRequester: 'by ${ride.employeeName}',
                  rating: ride.driverRating!,
                  completedDate: ride.completedAt!,
                  appSource: 'operational',
                  originalTaskObject: ride));
            }
          }
        }
      }
    } else if (widget.type == DetailRatingType.vehicle &&
        entity is VehicleModel) {
      final vehicleRatingsSnap = await _firestore
          .collection('vehicle_ratings')
          .where('vehicleId', isEqualTo: entity.id)
          .get();
      final requestIds = vehicleRatingsSnap.docs
          .map((doc) => doc.data()['requestId'] as String)
          .toSet();

      if (requestIds.isNotEmpty) {
        final rideDetailsSnap = await _firestore
            .collection('ride_requests')
            .where(FieldPath.documentId, whereIn: requestIds.toList())
            .get();
        final rideDetails = rideDetailsSnap.docs
            .map((d) => RideRequestModel.fromSnapshot(d))
            .toList();

        for (var ride in rideDetails) {
          if (ride.vehicleRating != null && ride.completedAt != null) {
            historyItems.add(TaskHistoryItem(
                taskId: ride.id,
                description:
                    'Trip to ${ride.dropoffLocation} by ${ride.driverName}',
                locationOrRequester: 'by ${ride.employeeName}',
                rating: ride.vehicleRating!,
                completedDate: ride.completedAt!,
                appSource: 'operational',
                originalTaskObject: ride));
          }
        }
      }
    }

    // Urutkan berdasarkan tanggal selesai
    historyItems.sort((a, b) => b.completedDate.compareTo(a.completedDate));

    // Set data untuk search
    setState(() {
      _allTasks = historyItems;
      _filteredTasks = historyItems;
    });

    return historyItems;
  }

  @override
  Widget build(BuildContext context) {
    String mainTitle;
    // Tentukan judul utama berdasarkan tipe entitas
    if (widget.type == DetailRatingType.technician) {
      final technician = widget.entity as UserModel;
      mainTitle = technician.name;
    } else if (widget.type == DetailRatingType.driver) {
      final driver = widget.entity as UserModel;
      mainTitle = driver.name;
    } else if (widget.type == DetailRatingType.vehicle) {
      final vehicle = widget.entity as VehicleModel;
      mainTitle = vehicle.vehicleModel;
    } else {
      mainTitle = 'Rating Details';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 330.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.blue.shade600,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                // title: Text(
                //   mainTitle,
                //   style: const TextStyle(
                //     fontSize: 20,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.white,
                //   ),
                // ),
                // centerTitle: true,
                // titlePadding: const EdgeInsets.only(bottom: 16),
                background: _buildModernHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSearchSection(),
            ),
          ];
        },
        body: FutureBuilder<List<TaskHistoryItem>>(
          future: _taskHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final tasksToShow = _isSearching ? _filteredTasks : _allTasks;

            if (_isSearching && _filteredTasks.isEmpty) {
              return _buildNoSearchResults();
            }

            return SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: tasksToShow.length,
                  itemBuilder: (context, index) {
                    return _buildModernHistoryCard(tasksToShow[index], index);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    String mainTitle, subtitle, memberSinceText;
    double avgRating = 0.0;
    int totalRatings = 0;
    IconData avatarIcon;
    Color avatarBgColor;

    if (widget.type == DetailRatingType.vehicle) {
      final vehicle = widget.entity as VehicleModel;
      final ratingData =
          widget.entityRatingData ?? {'averageRating': 0.0, 'totalRatings': 0};

      mainTitle = vehicle.vehicleModel;
      avgRating = (ratingData['averageRating'] as num).toDouble();
      totalRatings = (ratingData['totalRatings'] as num).toInt();
      subtitle = vehicle.licensePlate;
      memberSinceText =
          'Registered since ${DateFormat('MMMM yyyy').format(vehicle.createdAt)}';
      avatarIcon = Icons.directions_car_rounded;
      avatarBgColor = Colors.white;
    } else {
      final user = widget.entity as UserModel;

      mainTitle = user.name;
      avgRating = user.averageRating ?? 0.0;
      totalRatings = user.totalRatings ?? 0;
      subtitle = user.email;
      memberSinceText =
          'Member since ${DateFormat('MMMM yyyy').format(user.createdAt)}';
      if (widget.type == DetailRatingType.technician) {
        avatarIcon = Icons.engineering_rounded;
        avatarBgColor = Colors.white;
      } else {
        avatarIcon = Icons.person_rounded;
        avatarBgColor = Colors.white;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: avatarBgColor,
                        child: Icon(avatarIcon,
                            size: 40, color: Colors.blue.shade700),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    mainTitle,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black26)
                        ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Info Rating
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${avgRating.toStringAsFixed(1)} ',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        '($totalRatings ${totalRatings == 1 ? "rating" : "ratings"})',
                        style: TextStyle(
                            fontSize: 14, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Subtitle (Email/Plat) dan Tanggal Bergabung
              SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(memberSinceText,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search tasks, ratings, locations...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.grey[400], size: 24),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon:
                            Icon(Icons.clear_rounded, color: Colors.grey[400]),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHistoryCard(TaskHistoryItem item, int index) {
    final Map<String, dynamic> config = {
      'maintenance': {
        'title': 'Maintenance',
        'icon': Icons.construction_rounded,
        'color': const Color(0xFFEF6C00),
        'bgColor': const Color(0xFFFFF3E0),
      },
      'resource': {
        'title': 'Resource/Item',
        'icon': Icons.help_outline,
        'color': const Color(0xFF0097A7),
        'bgColor': const Color(0xFFE0F2F1),
      },
      'operational': {
        'title': 'Transportation',
        'icon': Icons.directions_car_rounded,
        'color': const Color(0xFFD32F2F),
        'bgColor': const Color(0xFFFFEBEE),
      },
    }[item.appSource]!;

    IconData displayIcon = config['icon'];

    if (item.appSource == 'resource' &&
        item.originalTaskObject is RequestModel) {
      final request = item.originalTaskObject as RequestModel;
      // Tentukan ikon berdasarkan field 'request'
      if (request.request == 'item') {
        displayIcon = Icons.inventory_2_rounded;
      } else if (request.request == 'resource') {
        displayIcon = Icons.people;
      }
    }

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final taskObject = item.originalTaskObject;
                    if (taskObject is ReportModel) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReportDetailScreen(report: taskObject),
                          ));
                    } else if (taskObject is RequestModel) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestDetailScreenResource(
                                request: taskObject),
                          ));
                    } else if (taskObject is RideRequestModel) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RideRequestDetailScreen(request: taskObject),
                          ));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: config['bgColor'],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(displayIcon,
                                  color: config['color'], size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    config['title'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: config['color'],
                                        fontSize: 14),
                                  ),
                                  Text(
                                    'Task ID: ${item.taskId.substring(0, 8)}...',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            _buildRatingBadge(item.rating),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                item.appSource == 'maintenance'
                                    ? Icons.location_on_outlined
                                    : Icons.person_outline,
                                item.locationOrRequester,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Completed: ${DateFormat('d MMM yyyy, HH:mm').format(item.completedDate)}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingBadge(double rating) {
    Color badgeColor;
    IconData badgeIcon;

    if (rating >= 4.5) {
      badgeColor = Colors.green;
      badgeIcon = Icons.star_rounded;
    } else if (rating >= 3.5) {
      badgeColor = Colors.orange;
      badgeIcon = Icons.star_half_rounded;
    } else {
      badgeColor = Colors.red;
      badgeIcon = Icons.star_border_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Loading rating history...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _taskHistoryFuture = _fetchTaskHistory();
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 62, 141, 219),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: Icon(Icons.history_toggle_off_rounded,
                size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'No Rating History Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This ${widget.type.name} hasn\'t received any ratings yet.\nRatings will appear here after completed tasks.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded,
                size: 64, color: Colors.blue[300]),
          ),
          const SizedBox(height: 24),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms\nor clear the search to see all results.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            },
            icon: const Icon(Icons.clear_all_rounded),
            label: const Text('Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 62, 141, 219),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
