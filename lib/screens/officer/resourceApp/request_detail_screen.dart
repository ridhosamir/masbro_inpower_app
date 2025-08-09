import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/resourceApp/request_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';
import '../../../services/resourceApp/firestore_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'assign_technician_screen.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestDetailScreenResource extends StatefulWidget {
  final RequestModel request;

  const RequestDetailScreenResource({super.key, required this.request});

  @override
  State<RequestDetailScreenResource> createState() =>
      _RequestDetailScreenResourceState();
}

class _RequestDetailScreenResourceState
    extends State<RequestDetailScreenResource> {
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();
  final _completionReasonController = TextEditingController();
  bool _isLoading = false;
  bool _isCompleting = false;
  UserModel? currentUser;
  late RequestModel _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _loadUserData();
  }

  @override
  void dispose() {
    _completionReasonController.dispose();
    super.dispose();
  }

  void _navigateToAssignTechnician() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AssignTechnicianScreenResource(request: _currentRequest),
      ),
    );

    if (result == true && mounted) {
      _refreshRequestData();
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }

  String _getPerformanceLabel(double rating) {
    if (rating >= 4.5) return 'EXCELLENT';
    if (rating >= 4.0) return 'GOOD';
    if (rating >= 3.5) return 'AVERAGE';
    if (rating >= 3.0) return 'FAIR';
    return 'NEEDS IMPROVEMENT';
  }

  void _showCompleteDialog(RequestModel request) {
    final formKey = GlobalKey<FormState>();
    _completionReasonController.clear();

    showDialog(
      context: context,
      barrierDismissible: !_isCompleting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _isCompleting
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            _completeRequest(request);
                          }
                        },
                  child: _isCompleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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

  Future<void> _completeRequest(RequestModel request) async {
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

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data officer belum termuat, silakan coba lagi.')),
      );
      return;
    }

    setState(() => _isCompleting = true);

    try {
      await _firestoreService.completeRequest(
        _currentRequest.id,
        _completionReasonController.text.trim(),
        technicianId: currentUser!.uid,
        technicianName: currentUser!.name,
      );

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan berhasil diselesaikan'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _refreshRequestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('requests_resource')
          .doc(_currentRequest.id)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _currentRequest = RequestModel.fromFirestore(doc);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data terbaru: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isResourceRequest = _currentRequest.request == 'resource';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Permintaan'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _currentRequest.getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _currentRequest.getStatusColor()),
              ),
              child: Column(
                children: [
                  Icon(
                    _currentRequest.getStatusIcon(),
                    color: _currentRequest.getStatusColor(),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Status: ${_currentRequest.getStatusDisplayName()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _currentRequest.getStatusColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dibuat pada ${DateFormat('d MMMM yyyy, HH:mm').format(_currentRequest.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (_currentRequest.status == 'completed' &&
                      _currentRequest.completionDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Diselesaikan pada ${DateFormat('dd MMM yyyy, HH:mm').format(_currentRequest.completionDate!)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Informasi Permintaan'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(
                  Icons.person, 'Pemohon', _currentRequest.employeeName),
              _buildInfoRow(
                isResourceRequest ? Icons.supervisor_account : Icons.inventory,
                'Kebutuhan',
                '${_currentRequest.request[0].toUpperCase()}${_currentRequest.request.substring(1)}',
              ),
              if (_currentRequest.timeRequired != null &&
                  _currentRequest.timeRequired!.isNotEmpty)
                _buildInfoRow(Icons.calendar_today, 'Waktu\nDibutuhkan',
                    _currentRequest.timeRequired!),
              _buildInfoRow(
                Icons.access_time,
                'Tanggal Dibuat',
                DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID')
                    .format(_currentRequest.createdAt),
              ),
            ]),
            // Tampilkan foto jika ini adalah permintaan item
            if (!isResourceRequest && _currentRequest.hasValidImage()) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Foto Item'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // Panggil fungsi untuk menampilkan gambar fullscreen
                  _showFullScreenImage(
                      context, _currentRequest.getNormalizedImageUrl()!);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Container gambar yang sudah ada
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
                          imageUrl: _currentRequest.getNormalizedImageUrl(),
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 40),
                                  const SizedBox(height: 8),
                                  const Text('Gagal memuat gambar'),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Tambahkan ikon sebagai petunjuk visual
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildSectionTitle('Deskripsi Kebutuhan'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                _currentRequest.description,
                style: TextStyle(
                    fontSize: 16, height: 1.5, color: Colors.grey[800]),
              ),
            ),
            if (_currentRequest.technicianName != null &&
                _currentRequest.technicianName!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Teknisi yang Ditugaskan'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child:
                              Icon(Icons.engineering, color: Colors.blue[700]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentRequest.technicianName!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentRequest.status == 'completed'
                                    ? 'Menyelesaikan permintaan ini'
                                    : 'Sedang menangani permintaan ini',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_currentRequest.status == 'completed' &&
                        _currentRequest.technicianRating != null) ...[
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.blue[200]),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Peringkat dari Pemohon',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '${_currentRequest.technicianRating!.toStringAsFixed(1)} dari 5.0',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _getRatingColor(
                                            _currentRequest.technicianRating!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRatingColor(
                                            _currentRequest.technicianRating!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getPerformanceLabel(
                                            _currentRequest.technicianRating!),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Menampilkan ulasan jika ada
                                if (_currentRequest.technicianReview != null &&
                                    _currentRequest
                                        .technicianReview!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.blue[100]!),
                                    ),
                                    child: Text(
                                      '"${_currentRequest.technicianReview!}"',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!isResourceRequest &&
                        _currentRequest.hasValidAfterImage()) ...[
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.blue[200]),
                      const SizedBox(height: 16),
                      Text(
                        'Item dari Teknisi:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          _showFullScreenImage(context,
                              _currentRequest.getNormalizedAfterImageUrl()!);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.blue[100],
                            child: FirebaseStorageImage(
                              imageUrl:
                                  _currentRequest.getNormalizedAfterImageUrl(),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_currentRequest.status == 'completed' &&
                _currentRequest.completionReason != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Catatan Penyelesaian'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentRequest.completionDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Diselesaikan pada: ${DateFormat('d MMMM yyyy, HH:mm').format(_currentRequest.completionDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Text(
                      _currentRequest.completionReason!,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (_currentRequest.status != 'completed') ...[
              _buildSectionTitle('Aksi'),
              const SizedBox(height: 12),
              CustomButton(
                text: _currentRequest.assignedTechnicianId == null
                    ? 'Tugaskan Teknisi'
                    : 'Ubah Teknisi',
                onPressed: _navigateToAssignTechnician,
                isLoading: _isLoading,
                icon: Icons.engineering,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Tandai Selesai',
                onPressed: () => _showCompleteDialog(_currentRequest),
                backgroundColor: Colors.green,
                icon: Icons.check_circle,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(children: children),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Colors.grey[900]),
            ),
          ),
        ],
      ),
    );
  }
}
