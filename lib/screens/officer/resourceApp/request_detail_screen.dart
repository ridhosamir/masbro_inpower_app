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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _completionReasonController.dispose();
    super.dispose();
  }

  void _navigateToAssignTechnician() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AssignTechnicianScreenResource(request: widget.request),
      ),
    );
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Permintaan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berikan catatan penyelesaian:'),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Catatan Penyelesaian',
              hintText: 'Contoh: Pekerjaan telah selesai...',
              controller: _completionReasonController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _completionReasonController.clear();
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: _completeRequest,
            child:
                const Text('Selesaikan', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
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

  Future<void> _completeRequest() async {
    if (_completionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap berikan catatan penyelesaian'),
          backgroundColor: Colors.red,
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
        widget.request.id,
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

  @override
  Widget build(BuildContext context) {
    final bool isResourceRequest = widget.request.request == 'resource';
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
                color: widget.request.getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.request.getStatusColor()),
              ),
              child: Column(
                children: [
                  Icon(
                    widget.request.getStatusIcon(),
                    color: widget.request.getStatusColor(),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Status: ${widget.request.getStatusDisplayName()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.request.getStatusColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dibuat pada ${DateFormat('d MMMM yyyy, HH:mm').format(widget.request.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (widget.request.status == 'completed' &&
                      widget.request.completionDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Diselesaikan pada ${DateFormat('dd MMM yyyy, HH:mm').format(widget.request.completionDate!)}',
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
                  Icons.person, 'Pemohon', widget.request.employeeName),
              _buildInfoRow(
                isResourceRequest ? Icons.supervisor_account : Icons.inventory,
                'Kebutuhan',
                '${widget.request.request[0].toUpperCase()}${widget.request.request.substring(1)}',
              ),
              if (widget.request.timeRequired != null &&
                  widget.request.timeRequired!.isNotEmpty)
                _buildInfoRow(Icons.calendar_today, 'Waktu\nDibutuhkan',
                    widget.request.timeRequired!),
              _buildInfoRow(
                Icons.access_time,
                'Tanggal Dibuat',
                DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID')
                    .format(widget.request.createdAt),
              ),
            ]),
            // Tampilkan foto jika ini adalah permintaan item
            if (!isResourceRequest && widget.request.hasValidImage()) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Foto Item'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // Panggil fungsi untuk menampilkan gambar fullscreen
                  _showFullScreenImage(
                      context, widget.request.getNormalizedImageUrl()!);
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
                          imageUrl: widget.request.getNormalizedImageUrl(),
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
                widget.request.description,
                style: TextStyle(
                    fontSize: 16, height: 1.5, color: Colors.grey[800]),
              ),
            ),
            if (widget.request.technicianName != null &&
                widget.request.technicianName!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Resource yang Ditugaskan'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.engineering, color: Colors.blue[700]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.request.technicianName!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.request.status == 'completed' &&
                widget.request.completionReason != null) ...[
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
                    if (widget.request.completionDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Diselesaikan pada: ${DateFormat('d MMMM yyyy, HH:mm').format(widget.request.completionDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Text(
                      widget.request.completionReason!,
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
            if (widget.request.status != 'completed') ...[
              _buildSectionTitle('Aksi'),
              const SizedBox(height: 12),
              CustomButton(
                text: widget.request.assignedTechnicianId == null
                    ? 'Tugaskan Teknisi'
                    : 'Ubah Teknisi',
                onPressed: _navigateToAssignTechnician,
                isLoading: _isLoading,
                icon: Icons.engineering,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Tandai Selesai',
                onPressed: _showCompleteDialog,
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
