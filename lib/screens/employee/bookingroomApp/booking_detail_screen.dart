import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/bookingroomApp/booking_model.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

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

            // --- Informasi Booking ---
            _buildSectionTitle('Informasi Booking'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(
                  Icons.meeting_room_outlined, 'Ruangan', booking.roomName),
              _buildInfoRow(
                  Icons.person_outline, 'Dipesan oleh', booking.employeeName),
              _buildInfoRow(
                  Icons.calendar_today,
                  'Jadwal Acara',
                  _formatBookingDuration(
                      booking.usageStartDate, booking.usageEndDate)),
              _buildInfoRow(Icons.local_activity_outlined, 'Jenis Kegiatan',
                  booking.activityType),
              _buildInfoRow(Icons.group_outlined, 'Jumlah Peserta',
                  '${booking.numberOfParticipants} orang'),
            ]),
            const SizedBox(height: 24),

            // --- Agenda Acara ---
            _buildSectionTitle('Agenda Acara'),
            const SizedBox(height: 12),
            _buildDescriptionBox(booking.eventAgenda),

            // --- Kebutuhan Tambahan ---
            const SizedBox(height: 24),
            _buildSectionTitle('Kebutuhan Tambahan'),
            const SizedBox(height: 12),
            _buildDescriptionBox(booking.needs),

            // --- Catatan Pembatalan (jika ada) ---
            if ((booking.status == 'approved' ||
                    booking.status == 'cancelled') &&
                booking.completionReason != null &&
                booking.completionReason!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(
                booking.status == 'approved'
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
        color: booking.getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: booking.getStatusColor()),
      ),
      child: Column(
        children: [
          Icon(
            booking.getStatusIcon(),
            color: booking.getStatusColor(),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Status: ${booking.getStatusDisplayName()}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: booking.getStatusColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dibuat pada ${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(booking.createdAt)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (booking.status == 'approved' &&
              booking.completionDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Disetujui pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(booking.completionDate!)}',
              style: TextStyle(
                color: booking.getStatusColor().withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (booking.status == 'cancelled' &&
              booking.completionDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dibatalkan pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(booking.completionDate!)}',
              style: TextStyle(
                color: booking.getStatusColor().withOpacity(0.8),
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
    bool isApproved = booking.status == 'approved';

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
        booking.completionReason!,
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
