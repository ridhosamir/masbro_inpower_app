import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/resourceApp/request_model.dart';
import '../../../models/user_model.dart';
import '../../../services/resourceApp/firestore_service.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import '../../../services/user_service.dart';
import '../../../widgets/custom_button.dart';

class AssignTechnicianScreenResource extends StatefulWidget {
  final RequestModel request;
  const AssignTechnicianScreenResource({super.key, required this.request});

  @override
  State<AssignTechnicianScreenResource> createState() =>
      _AssignTechnicianScreenResourceState();
}

class _AssignTechnicianScreenResourceState
    extends State<AssignTechnicianScreenResource> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();
  final UserService _userService = UserService();
  List<UserModel> _technicians = [];
  List<UserModel> _filteredTechnicians = [];
  UserModel? _selectedTechnician;
  bool _isLoading = true;
  bool _isAssigning = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'rating';

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterAndSortTechnicians();
      });
    });
  }

  void _filterAndSortTechnicians() {
    setState(() {
      // 1. Filter berdasarkan pencarian
      if (_searchQuery.isNotEmpty) {
        _filteredTechnicians = _technicians.where((tech) {
          final nameMatches =
              tech.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final emailMatches =
              tech.email.toLowerCase().contains(_searchQuery.toLowerCase());
          return nameMatches || emailMatches;
        }).toList();
      } else {
        _filteredTechnicians = List.from(_technicians);
      }

      // 2. Urutkan hasil filter
      switch (_sortBy) {
        case 'rating':
          _filteredTechnicians.sort((a, b) {
            final ratingA = a.averageRating ?? 0.0;
            final ratingB = b.averageRating ?? 0.0;
            if (ratingA != ratingB) {
              return ratingB.compareTo(ratingA); // Rating tertinggi dulu
            }
            final totalA = a.totalRatings ?? 0;
            final totalB = b.totalRatings ?? 0;
            return totalB.compareTo(totalA); // Jumlah rating terbanyak dulu
          });
          break;
        case 'name':
          _filteredTechnicians.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'since':
          // Member tertua (pengalaman terlama) di atas
          _filteredTechnicians
              .sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
      }
    });
  }

  Future<void> _loadTechnicians() async {
    setState(() => _isLoading = true);

    try {
      // 1. Dapatkan semua pengguna dengan role 'technician' (dengan rating gabungan awal)
      final allTechnicians = await _userService.getTechnicians();

      // 2. Dapatkan semua UID dari koleksi 'drivers'
      final driversSnapshot = await _firestore.collection('drivers').get();
      final driverUIDs = driversSnapshot.docs.map((doc) => doc.id).toSet();

      // 3. Filter teknisi yang UID-nya TIDAK ADA di dalam koleksi 'drivers'
      final nonDriverTechnicians = allTechnicians.where((technician) {
        return !driverUIDs.contains(technician.uid);
      }).toList();

      // 4. Ambil rating SPESIFIK untuk ResourceApp untuk setiap teknisi yang telah difilter
      final ratingFutures = nonDriverTechnicians
          .map((tech) =>
              _firestoreService.getTechnicianRatingForResourceApp(tech.uid))
          .toList();

      final ratingsData = await Future.wait(ratingFutures);

      // 5. Buat daftar teknisi baru dengan rating yang sudah diperbarui (spesifik ResourceApp)
      final List<UserModel> techniciansWithAppSpecificRatings = [];
      for (int i = 0; i < nonDriverTechnicians.length; i++) {
        final technician = nonDriverTechnicians[i];
        final ratingMap = ratingsData[i];

        // Gunakan copyWith untuk menimpa rating gabungan dengan rating spesifik
        techniciansWithAppSpecificRatings.add(
          technician.copyWith(
            averageRating:
                (ratingMap['averageRating'] as num?)?.toDouble() ?? 0.0,
            totalRatings: (ratingMap['totalRatings'] as int?) ?? 0,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _technicians = techniciansWithAppSpecificRatings;
          // Set teknisi yang sudah ditugaskan sebelumnya jika ada
          if (widget.request.assignedTechnicianId != null) {
            try {
              _selectedTechnician = _technicians.firstWhere(
                (tech) => tech.uid == widget.request.assignedTechnicianId,
              );
            } catch (e) {
              _selectedTechnician = null;
            }
          }
          _filterAndSortTechnicians(); // Terapkan filter dan sort awal
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat teknisi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignTechnician() async {
    if (_selectedTechnician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a technician first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      await _firestoreService.assignTechnician(
        widget.request,
        _selectedTechnician!.uid,
        _selectedTechnician!.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tasks assigned to ${_selectedTechnician!.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning technician: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }

  String _getSinceText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}years ';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}months ';
    } else {
      return '${difference.inDays}days ';
    }
  }

  String _getPerformanceLabel(double rating) {
    if (rating >= 4.5) return 'EXCELLENT';
    if (rating >= 4.0) return 'GOOD';
    if (rating >= 3.5) return 'AVERAGE';
    if (rating >= 3.0) return 'FAIR';
    return 'POOR';
  }

  Widget _buildTechnicianRatingEnhanced(UserModel technician) {
    if (technician.averageRating != null &&
        technician.totalRatings != null &&
        technician.totalRatings! > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getRatingColor(technician.averageRating!).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getRatingColor(technician.averageRating!).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < (technician.averageRating ?? 0).floor()
                      ? Icons.star
                      : index < (technician.averageRating ?? 0).ceil() &&
                              (technician.averageRating ?? 0).floor() !=
                                  (technician.averageRating ?? 0).ceil()
                          ? Icons.star_half
                          : Icons.star_border,
                  color: Colors.amber,
                  size: 14,
                );
              }),
            ),
            const SizedBox(width: 4),
            Text(
              '${technician.averageRating!.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getRatingColor(technician.averageRating!),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${technician.totalRatings})',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _getRatingColor(technician.averageRating!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getPerformanceLabel(technician.averageRating!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, color: Colors.grey[400], size: 14),
          const SizedBox(width: 4),
          Text(
            'Belum ada rating',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetapkan Teknisi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Ringkasan Permintaan ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryItem(
                            'Pemohon', widget.request.employeeName),
                        _buildSummaryItem(
                          'Kebutuhan',
                          '${widget.request.request[0].toUpperCase()}${widget.request.request.substring(1)}',
                        ),
                        if (widget.request.request != 'resource' &&
                            widget.request.hasValidImage()) ...[
                          Text(
                            'Foto Barang:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showFullScreenImage(context,
                                widget.request.getNormalizedImageUrl()!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: FirebaseStorageImage(
                                imageUrl:
                                    widget.request.getNormalizedImageUrl(),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  height: 150,
                                  color: Colors.blue[100],
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: Container(
                                  height: 150,
                                  color: Colors.blue[100],
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.blue[300],
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (widget.request.timeRequired != null &&
                            widget.request.timeRequired!.isNotEmpty)
                          _buildSummaryItem(
                            'Dibutuhkan',
                            widget.request.timeRequired!,
                          ),
                        _buildSummaryItem(
                            'Deskripsi', widget.request.description),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  'Urgensi:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                              _buildUrgencyChip(widget.request.requestType),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Daftar Teknisi Tersedia ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Teknisi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      // Sort dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            icon: const Icon(Icons.sort, size: 18),
                            isDense: true,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sortBy = newValue;
                                });
                                _filterAndSortTechnicians();
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'rating',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        size: 16, color: Colors.amber),
                                    SizedBox(width: 4),
                                    Text('Rating',
                                        style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'name',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sort_by_alpha, size: 16),
                                    SizedBox(width: 4),
                                    Text('Nama',
                                        style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'since',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: 16),
                                    SizedBox(width: 4),
                                    Text('Sejak',
                                        style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Temukan Teknisi...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Memuat...'),
                        ],
                      ),
                    ))
                  else if (_filteredTechnicians.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.engineering,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Teknisi tidak ditemukan.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada teknisi yang cocok dengan pencarian.'
                                  : 'Tidak ada teknisi (non-pengemudi) yang tersedia.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredTechnicians.length,
                      itemBuilder: (context, index) {
                        final technician = _filteredTechnicians[index];
                        final isSelected =
                            _selectedTechnician?.uid == technician.uid;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTechnician =
                                    isSelected ? null : technician;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? Colors.blue[50] : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue[300]!
                                      : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue[100]
                                              : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Icon(
                                          Icons.engineering,
                                          color: isSelected
                                              ? Colors.blue[700]
                                              : Colors.grey[600],
                                          size: 28,
                                        ),
                                      ),
                                      if (technician.averageRating != null &&
                                          technician.totalRatings != null &&
                                          technician.totalRatings! > 0)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getRatingColor(
                                                  technician.averageRating!),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 2),
                                            ),
                                            child: Text(
                                              technician.averageRating!
                                                  .toStringAsFixed(1),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                technician.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? Colors.blue[700]
                                                      : Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              isSelected
                                                  ? Icons.check_circle
                                                  : Icons
                                                      .radio_button_unchecked,
                                              color: isSelected
                                                  ? Colors.blue[700]
                                                  : Colors.grey[400],
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          technician.email,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildTechnicianRatingEnhanced(
                                            technician),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time,
                                                size: 12,
                                                color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Teknisi Sejak ${DateFormat('MMM yyyy').format(technician.createdAt)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(Icons.timeline,
                                                size: 12,
                                                color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              _getSinceText(
                                                  technician.createdAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
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
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          if (!_isLoading && _technicians.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: CustomButton(
                text: 'Tugaskan Teknisi',
                onPressed: _assignTechnician,
                isLoading: _isAssigning,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Lebar label agar rapi
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
              style: TextStyle(color: Colors.blue[600]),
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
                fit: BoxFit.contain,
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

  Widget _buildUrgencyChip(String requestType) {
    Color color;
    String text;
    IconData icon;

    switch (requestType) {
      case 'Rendah':
        color = Colors.green;
        text = 'Rendah';
        icon = Icons.keyboard_arrow_down;
        break;
      case 'Tinggi':
        color = Colors.red;
        text = 'Tinggi';
        icon = Icons.keyboard_arrow_up;
        break;
      case 'Sedang':
      default:
        color = Colors.orange;
        text = 'Sedang';
        icon = Icons.remove;
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
