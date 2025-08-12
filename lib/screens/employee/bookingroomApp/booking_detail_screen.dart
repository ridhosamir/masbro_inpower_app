import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/bookingroomApp/booking_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../services/bookingroomApp/firestore_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0.0;
  bool _isSubmitting = false;
  late BookingModel _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;

    if (_currentBooking.rating != null) {
      _rating = _currentBooking.rating!;
    }
    if (_currentBooking.ratingComment != null) {
      _commentController.text = _currentBooking.ratingComment!;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatBookingDuration(DateTime start, DateTime end) {
    // Cek apakah booking dalam satu hari yang sama
    final isSingleDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (isSingleDay) {
      // Format untuk booking harian: Senin, 28 Jul 2025, 09:00 - 11:30
      final date = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(start);
      final startTime = DateFormat('HH:mm').format(start);
      final endTime = DateFormat('HH:mm').format(end);
      return '$date, $startTime - $endTime';
    } else {
      // Format untuk booking beberapa hari: Senin, 28 Jul 2025 s/d Rabu, 30 Jul 2025
      final startDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(start);
      final endDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(end);
      return '$startDate s/d $endDate';
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan berikan minimal 1 bintang.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _firestoreService.submitBookingRating(
        bookingId: _currentBooking.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      // Perbarui UI secara lokal untuk respons instan
      setState(() {
        _currentBooking = _currentBooking.copyWith(
          rating: _rating,
          ratingComment: _commentController.text.trim(),
          ratingDate: DateTime.now(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih! Penilaian Anda telah disimpan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim penilaian: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildRatingSection() {
    final bool hasRated = _currentBooking.rating != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            hasRated ? 'Penilaian Anda' : 'Beri Penilaian Kesiapan Ruangan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.amber[800],
            ),
          ),
          const SizedBox(height: 16),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              if (!hasRated) {
                setState(() {
                  _rating = rating;
                });
              }
            },
            ignoreGestures: hasRated,
          ),
          const SizedBox(height: 16),
          if (!hasRated) ...[
            // --- Form untuk memberi rating ---
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis ulasan Anda (opsional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[500],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isSubmitting
                  ? Container(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Penilaian'),
            ),
          ] else ...[
            // --- Tampilan setelah memberi rating ---
            const Divider(height: 20),
            if (_currentBooking.ratingComment != null &&
                _currentBooking.ratingComment!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  '"${_currentBooking.ratingComment!}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              )
            else
              Text(
                'Terima kasih atas penilaian Anda!',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Booking'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBox(context),
            const SizedBox(height: 24),

            if (_currentBooking.status == 'approved' &&
                DateTime.now().isAfter(_currentBooking.usageEndDate)) ...[
              _buildRatingSection(),
              const SizedBox(height: 24),
            ],

            // --- Informasi Booking ---
            _buildSectionTitle('Informasi Booking'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.meeting_room_outlined, 'Ruangan',
                  _currentBooking.roomName),
              _buildInfoRow(Icons.person_outline, 'Dipesan oleh',
                  _currentBooking.employeeName),
              _buildInfoRow(
                  Icons.calendar_today,
                  'Jadwal Acara',
                  _formatBookingDuration(_currentBooking.usageStartDate,
                      _currentBooking.usageEndDate)),
              _buildInfoRow(Icons.local_activity_outlined, 'Jenis Kegiatan',
                  _currentBooking.activityType),
              _buildInfoRow(Icons.group_outlined, 'Jumlah Peserta',
                  '${_currentBooking.numberOfParticipants} orang'),
            ]),
            const SizedBox(height: 24),

            // --- Agenda Acara ---
            _buildSectionTitle('Agenda Acara'),
            const SizedBox(height: 12),
            _buildDescriptionBox(_currentBooking.eventAgenda),

            // --- Kebutuhan Tambahan ---
            const SizedBox(height: 24),
            _buildSectionTitle('Kebutuhan Tambahan'),
            const SizedBox(height: 12),
            _buildDescriptionBox(_currentBooking.needs),

            // --- Catatan Pembatalan (jika ada) ---
            if ((_currentBooking.status == 'approved' ||
                    _currentBooking.status == 'cancelled') &&
                _currentBooking.completionReason != null &&
                _currentBooking.completionReason!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(
                _currentBooking.status == 'approved'
                    ? 'Catatan Persetujuan'
                    : 'Alasan Pembatalan',
              ),
              const SizedBox(height: 12),
              _buildReasonBox(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk kotak status di bagian atas
  Widget _buildStatusBox(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _currentBooking.getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _currentBooking.getStatusColor()),
      ),
      child: Column(
        children: [
          Icon(
            _currentBooking.getStatusIcon(),
            color: _currentBooking.getStatusColor(),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Status: ${_currentBooking.getStatusDisplayName()}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _currentBooking.getStatusColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dibuat pada ${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(_currentBooking.createdAt)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (_currentBooking.status == 'approved' &&
              _currentBooking.completionDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Disetujui pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(_currentBooking.completionDate!)}',
              style: TextStyle(
                color: _currentBooking.getStatusColor().withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_currentBooking.status == 'cancelled' &&
              _currentBooking.completionDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dibatalkan pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(_currentBooking.completionDate!)}',
              style: TextStyle(
                color: _currentBooking.getStatusColor().withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper widget untuk kotak deskripsi/agenda
  Widget _buildDescriptionBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800]),
      ),
    );
  }

  // Helper widget untuk kotak alasan pembatalan
  Widget _buildReasonBox() {
    bool isApproved = _currentBooking.status == 'approved';

    Color backgroundColor = isApproved ? Colors.green[50]! : Colors.red[50]!;
    Color borderColor = isApproved ? Colors.green[200]! : Colors.red[200]!;
    Color textColor = isApproved ? Colors.green[800]! : Colors.red[800]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        _currentBooking.completionReason!,
        style: TextStyle(fontSize: 15, height: 1.5, color: textColor),
      ),
    );
  }

// --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
