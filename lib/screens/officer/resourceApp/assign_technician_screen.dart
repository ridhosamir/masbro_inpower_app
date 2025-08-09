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
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();
  final UserService _userService = UserService();
  List<UserModel> _technicians = [];
  List<UserModel> _filteredTechnicians = [];
  UserModel? _selectedTechnician;
  bool _isLoading = true;
  bool _isAssigning = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'default';

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
      // 1. Filter berdasarkan pencarian (search)
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

      // 2. Urutkan (sort) hasil filter
      switch (_sortBy) {
        case 'rating':
          _filteredTechnicians.sort((a, b) {
            final ratingA = a.averageRating ?? 0.0;
            final ratingB = b.averageRating ?? 0.0;
            final totalRatingsA = a.totalRatings ?? 0;
            final totalRatingsB = b.totalRatings ?? 0;

            // Teknisi tanpa rating selalu di paling bawah
            if (totalRatingsA == 0 && totalRatingsB > 0) return 1;
            if (totalRatingsB == 0 && totalRatingsA > 0) return -1;

            // Urutkan berdasarkan rating tertinggi
            int ratingCompare = ratingB.compareTo(ratingA);
            if (ratingCompare != 0) return ratingCompare;

            // Jika rating sama, urutkan berdasarkan jumlah rating terbanyak
            return totalRatingsB.compareTo(totalRatingsA);
          });
          break;
        case 'name':
          _filteredTechnicians.sort((a, b) => a.name.compareTo(b.name));
          break;
        default:
          _filteredTechnicians.sort((a, b) {
            if (widget.request.assignedTechnicianId != null) {
              final assignedId = widget.request.assignedTechnicianId;
              if (a.uid == assignedId) return -1;
              if (b.uid == assignedId) return 1;
            }
            return 0;
          });
          break;
      }
    });
  }

  Future<void> _loadTechnicians() async {
    try {
      final technicians = await _userService.getTechnicians();
      final ratingFutures = technicians
          .map((tech) =>
              _firestoreService.getTechnicianRatingForResourceApp(tech.uid))
          .toList();

      final ratingsData = await Future.wait(ratingFutures);
      for (int i = 0; i < technicians.length; i++) {
        final ratingMap = ratingsData[i];
        _technicians.add(technicians[i].copyWith(
          averageRating:
              (ratingMap['averageRating'] as num?)?.toDouble() ?? 0.0,
          totalRatings: (ratingMap['totalRatings'] as int?) ?? 0,
        ));
      }

      if (mounted) {
        setState(() {
          _filterAndSortTechnicians();
          _isLoading = false;
          if (widget.request.assignedTechnicianId != null) {
            try {
              _selectedTechnician = _technicians.firstWhere(
                (tech) => tech.uid == widget.request.assignedTechnicianId,
              );
            } catch (e) {
              _selectedTechnician = null;
            }
          }
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
          content: Text('Silakan pilih teknisi terlebih dahulu'),
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
            content: Text('Tugas ditugaskan ke ${_selectedTechnician!.name}'),
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
            content: Text('Error menugaskan teknisi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRatingStars(double rating, int totalRatings) {
    if (totalRatings == 0) {
      return Text(
        'Belum ada rating',
        style: TextStyle(
            fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          '($totalRatings)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugaskan Resource'),
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
                            'Item Permintaan:',
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
                            'Waktu Dibutuhkan',
                            widget.request.timeRequired!,
                          ),
                        _buildSummaryItem(
                            'Deskripsi', widget.request.description),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Daftar Teknisi Tersedia ---
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pilih Teknisi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      // Tombol Dropdown untuk Filter
                      DropdownButton<String>(
                        value: _sortBy,
                        icon: const Icon(Icons.sort, size: 20),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'default',
                            child:
                                Text('Default', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'rating',
                            child: Text('Rating Tertinggi',
                                style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('Nama (A-Z)',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                              _filterAndSortTechnicians();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari teknisi...',
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
                      child: CircularProgressIndicator(),
                    ))
                  else if (_filteredTechnicians.isEmpty)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Tidak ada teknisi yang cocok.'),
                    ))
                  else
                    Column(
                      children: _filteredTechnicians.map((technician) {
                        final isSelected =
                            _selectedTechnician?.uid == technician.uid;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue[300]!
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: _firestoreService
                                .getTechnicianRatingForResourceApp(
                                    technician.uid),
                            builder: (context, snapshot) {
                              double averageRating = 0.0;
                              int totalRatings = 0;
                              Widget ratingWidget = const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2));

                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                averageRating =
                                    (snapshot.data!['averageRating'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                totalRatings =
                                    (snapshot.data!['totalRatings'] as int?) ??
                                        0;
                                ratingWidget = _buildRatingStars(
                                    averageRating, totalRatings);
                              } else if (snapshot.hasError) {
                                ratingWidget = const Text('Error',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12));
                              }

                              return ListTile(
                                onTap: () {
                                  setState(() {
                                    _selectedTechnician =
                                        isSelected ? null : technician;
                                  });
                                },
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? Colors.blue[100]
                                      : Colors.grey[200],
                                  child: Icon(
                                    Icons.engineering,
                                    color: isSelected
                                        ? Colors.blue[700]
                                        : Colors.grey[600],
                                  ),
                                ),
                                title: Text(
                                  technician.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.blue[800]
                                        : Colors.grey[800],
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(technician.email),
                                    const SizedBox(height: 4),
                                    ratingWidget,
                                  ],
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle,
                                        color: Colors.blue[700])
                                    : const Icon(Icons.radio_button_unchecked),
                              );
                            },
                          ),
                        );
                      }).toList(),
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
                text: 'Tugaskan',
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Colors.blue[700],
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
}
