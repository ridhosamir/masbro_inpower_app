import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/resourceApp/firestore_service.dart';
import '../../../models/resourceApp/task_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import '../../../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class TechnicianDashboardResource extends StatefulWidget {
  const TechnicianDashboardResource({super.key});

  @override
  State<TechnicianDashboardResource> createState() =>
      _TechnicianDashboardResourceState();
}

class _TechnicianDashboardResourceState
    extends State<TechnicianDashboardResource> with TickerProviderStateMixin {
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();
  final _completionNoteController = TextEditingController();
  final StorageService _storageService = StorageService();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  UserModel? currentUser;
  late TabController _tabController;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
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
      if (mounted) {
        setState(() {
          currentUser = userData;
        });
      }
    }
  }

  Future<void> _pickImage(
      ImageSource source, StateSetter setStateDialog) async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        // Jika platformnya web, baca data bytes untuk preview
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setStateDialog(() {
            _selectedImage = pickedFile;
            _selectedImageBytes = bytes;
          });
        } else {
          // Jika mobile, cukup simpan filenya
          setStateDialog(() {
            _selectedImage = pickedFile;
          });
        }
      }
    } catch (e) {
      print('Gagal memilih gambar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
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
              automaticallyImplyLeading: false,
              pinned: true,
              backgroundColor: Theme.of(context).primaryColor,
              flexibleSpace: FlexibleSpaceBar(
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
                                  CircleAvatar(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.2),
                                    radius: 24,
                                    child: const Icon(
                                      Icons.engineering,
                                      color: Colors.white,
                                      size: 26,
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
                                  'Kelola tugas resource Anda',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<List<TaskModel>>(
                                stream: _firestoreService.getTasksByTechnician(
                                  authService.user!.uid,
                                ),
                                builder: (context, snapshot) {
                                  final tasks = snapshot.data ?? [];
                                  final inProgress = tasks
                                      .where((t) => t.status == 'inProgress')
                                      .length;
                                  if (tasks.isEmpty) {
                                    return Text(
                                      'Belum ada tugas yang ditugaskan',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return Text(
                                    '${tasks.length} total tugas · $inProgress sedang dikerjakan',
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
                  Tab(text: 'All Task'),
                  Tab(text: 'In Progress'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
          ];
        },
        body: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildStatisticsCards(),
            ),
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
                          hintText: 'Cari permintaan...',
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
                      tooltip: 'Filter Permintaan',
                    ),
                  ),
                ],
              ),
            ),
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

  // --- WIDGET STATISTIK ---
  Widget _buildStatisticsCards() {
    final authService = Provider.of<AuthService>(context, listen: false);
    return StreamBuilder<List<TaskModel>>(
      stream: _firestoreService.getTasksByTechnician(authService.user!.uid),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final inProgress = tasks.where((t) => t.status == 'inProgress').length;
        final completed = tasks.where((t) => t.status == 'completed').length;
        final todayTasks = tasks.where((t) {
          final today = DateTime.now();
          return t.assignedAt.year == today.year &&
              t.assignedAt.month == today.month &&
              t.assignedAt.day == today.day;
        }).length;
        return Row(
          children: [
            Expanded(
                child: _buildStatCard(
              title: 'All Task',
              count: tasks.length,
              icon: Icons.assignment,
              color: Colors.blue,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatCard(
              title: 'In Progress',
              count: inProgress,
              icon: Icons.engineering,
              color: Colors.purple,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatCard(
              title: 'Completed',
              count: completed,
              icon: Icons.check_circle,
              color: Colors.green,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatCard(
              title: 'Today',
              count: todayTasks,
              icon: Icons.today,
              color: Colors.orange,
            )),
          ],
        );
      },
    );
  }

  // --- WIDGET DAFTAR TUGAS ---
  Widget _buildTasksList(String tabStatus) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return StreamBuilder<List<TaskModel>>(
      stream: _firestoreService.getTasksByTechnician(authService.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        List<TaskModel> tasks = snapshot.data ?? [];
        if (tabStatus != 'all') {
          tasks = tasks.where((t) => t.status == tabStatus).toList();
        }

        if (_searchQuery.isNotEmpty) {
          tasks = tasks
              .where((r) =>
                  r.requesterName
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
          tasks = tasks.where((r) {
            final assignedAt = r.assignedAt;
            switch (_selectedFilter) {
              case 'today':
                return assignedAt.year == now.year &&
                    assignedAt.month == now.month &&
                    assignedAt.day == now.day;
              case 'week':
                // Filter untuk 7 hari terakhir
                return now.difference(assignedAt).inDays < 7;
              case 'month':
                return assignedAt.year == now.year &&
                    assignedAt.month == now.month;
              default:
                return true;
            }
          }).toList();
        }

        tasks.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));

        if (tasks.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return _buildEmptySearchState();
          }
          return _buildEmptyState(tabStatus);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _buildTaskCard(tasks[index]);
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

  void _showTaskDetail(TaskModel task) {
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
                    'Detail Tugas',
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
                            'Kebutuhan',
                            '${task.request[0].toUpperCase()}${task.request.substring(1)}',
                            task.request == 'resource'
                                ? Icons.supervisor_account
                                : Icons.inventory,
                          ),
                          _buildDetailItem(
                              'Pemohon', task.requesterName, Icons.person),
                          if (task.timeRequired != null &&
                              task.timeRequired!.isNotEmpty)
                            _buildDetailItem('Waktu Dibutuhkan',
                                task.timeRequired!, Icons.calendar_today),
                          _buildDetailItem(
                            'Ditugaskan',
                            DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                                .format(task.assignedAt),
                            Icons.access_time,
                          ),
                          if (task.status == 'completed' &&
                              task.completedAt != null)
                            _buildDetailItem(
                              'Selesai',
                              DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID')
                                  .format(task.completedAt!),
                              Icons.check_circle,
                            ),
                        ],
                      ),
                    ),
                    // Tampilkan foto jika ini adalah permintaan item
                    if (!isResourceRequest && task.hasValidImage()) ...[
                      const SizedBox(height: 24),
                      const Text('Foto Item',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          // Panggil fungsi untuk menampilkan gambar fullscreen
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
                      'Deskripsi Tugas',
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
                        'Catatan Penyelesaian Anda',
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
                    ],
                  ],
                ),
              ),
            ),
            if (task.status == 'inProgress')
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  text: 'Tandai Selesai',
                  onPressed: () => _showCompleteDialog(task),
                  backgroundColor: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -- Helper Widgets  --
  Widget _buildTaskCard(TaskModel task) {
    final bool isResourceRequest = task.request == 'resource';
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTaskDetail(task),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   task.description,
              //   style:
              //       const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //   maxLines: 2,
              //   overflow: TextOverflow.ellipsis,
              // ),
              _buildInfoRow(
                isResourceRequest ? Icons.supervisor_account : Icons.inventory,
                'Kebutuhan',
                '${task.request[0].toUpperCase()}${task.request.substring(1)}',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.person_pin_circle_outlined, 'Pemohon',
                  task.requesterName),
              if (task.timeRequired != null && task.timeRequired!.isNotEmpty)
                _buildInfoRow(
                    Icons.calendar_today, 'Waktu', task.timeRequired!),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (task.status == 'completed' && task.completedAt != null)
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.green[700]),
                  if (task.status != 'completed')
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    task.status == 'completed' && task.completedAt != null
                        ? 'Selesai: ${_getTimeAgo(task.completedAt!)}'
                        : 'Ditugaskan: ${_getTimeAgo(task.assignedAt)}',
                    style: TextStyle(
                      color: task.status == 'completed'
                          ? Colors.green[700]
                          : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: task.status == 'completed'
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(task.status),
                ],
              ),
              if (task.status == 'inProgress') ...[
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Tandai Selesai',
                  onPressed: () => _showCompleteDialog(task),
                  backgroundColor: Colors.green,
                  icon: Icons.check_circle,
                ),
              ],
            ],
          ),
        ),
      ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey[800])),
          Expanded(
              child: Text(value, style: TextStyle(color: Colors.grey[700]))),
        ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                      fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: Colors.blue[800], fontSize: 14),
                ),
              ],
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
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: FirebaseStorageImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain, // Agar seluruh gambar terlihat saat dibuka
                placeholder: const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    if (status == 'inProgress') {
      color = Colors.blue;
      text = 'IN PROGRESS';
    } else if (status == 'completed') {
      color = Colors.green;
      text = 'COMPLETED';
    } else {
      color = Colors.grey;
      text = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} hari yang lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam yang lalu';
    if (difference.inMinutes > 0)
      return '${difference.inMinutes} menit yang lalu';
    return 'Baru saja';
  }

  void _showCompleteDialog(TaskModel task) {
    _completionNoteController.clear();
    _selectedImage = null;
    _selectedImageBytes = null;
    String? dialogErrorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Selesaikan Tugas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      labelText: 'Catatan Penyelesaian',
                      hintText: 'Masukkan catatan pekerjaan...',
                      controller: _completionNoteController,
                      maxLines: 3,
                    ),
                    if (task.request == 'item') ...[
                      const SizedBox(height: 16),
                      Text('Foto Item (Opsional)',
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
                            label: const Text('Galeri'),
                            onPressed: () =>
                                _pickImage(ImageSource.gallery, setStateDialog),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Kamera'),
                            onPressed: () =>
                                _pickImage(ImageSource.camera, setStateDialog),
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
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    if (_completionNoteController.text.trim().isEmpty) {
                      setStateDialog(() {
                        dialogErrorText = 'Harap berikan catatan penyelesaian';
                      });
                    } else {
                      _completeTask(task);
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Selesaikan',
                          style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _completeTask(TaskModel task) async {
    // Tutup keyboard jika terbuka
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    String? imageUrl;
    try {
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadImage(
            _selectedImage!, 'completed_items');
        if (imageUrl == null) {
          throw Exception('Gagal mengunggah gambar.');
        }
      }
      await _firestoreService.updateTaskStatus(
        task.id,
        'completed',
        completionNote: _completionNoteController.text.trim(),
        afterImageUrl: imageUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tugas berhasil diselesaikan!'),
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
      }
    }
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
            ));
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

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w600)),
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
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
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
