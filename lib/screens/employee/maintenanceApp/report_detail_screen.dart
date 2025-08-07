import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import '../../../models/maintenanceApp/report_model.dart';
import '../../../services/maintenanceApp/firestore_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  bool _isSubmittingRating = false;
  ReportModel? _updatedReport;

  @override
  void initState() {
    super.initState();
    _updatedReport = widget.report;
    // Initialize rating with the stored value if it exists
    if (widget.report.technicianRating != null) {
      _rating = widget.report.technicianRating!;
    }

    // Refresh report data to ensure we have the latest rating and review
    if (widget.report.status == 'completed') {
      _refreshReportData();
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _refreshReportData() async {
    try {
      final updatedReport =
          await _firestoreService.getReportWithRating(widget.report.id);
      if (updatedReport != null && mounted) {
        setState(() {
          _updatedReport = updatedReport;
          if (updatedReport.technicianRating != null) {
            _rating = updatedReport.technicianRating!;
          }
        });
      }
    } catch (e) {
      print('Error refreshing report data: $e');
      // No need to show error to user, we'll just use the original report
    }
  }

  Future<void> _submitRatingAndReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan berikan rating terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      final review = _reviewController.text.trim();

      await _firestoreService.rateTechnician(
        widget.report.id,
        _rating,
        widget.report.assignedTechnicianId!,
        review: review.isNotEmpty ? review : null,
      );

      // Refresh report data after rating
      await _refreshReportData();

      if (mounted) {
        setState(() {
          _isSubmittingRating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rating dan ulasan berhasil dikirim, terima kasih!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingRating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show full screen image view
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text('Lihat Gambar', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(20),
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
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Gagal memuat gambar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the updated report if available, otherwise use the original
    final report = _updatedReport ?? widget.report;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Laporan'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: report.getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: report.getStatusColor()),
              ),
              child: Column(
                children: [
                  Icon(
                    report.getStatusIcon(),
                    color: report.getStatusColor(),
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Status: ${report.getStatusDisplayName()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: report.getStatusColor(),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dibuat pada ${DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  // Show completion date when status is completed
                  if (report.status == 'completed' &&
                      report.completionDate != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Diselesaikan pada ${DateFormat('dd MMM yyyy, HH:mm').format(report.completionDate!)}',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20),

            // Technician Rating Section (only for completed reports)
            if (report.status == 'completed' &&
                report.assignedTechnicianId != null) ...[
              _buildSectionTitle('Berikan Rating dan Ulasan untuk Teknisi'),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Bagaimana kinerja ${report.technicianName} dalam menangani laporan ini?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    // Review text field
                    if (report.technicianRating == null) ...[
                      TextField(
                        controller: _reviewController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Tambahkan ulasan tentang pelayanan teknisi...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.amber[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.amber[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.amber[700]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Submit button
                    ElevatedButton(
                      onPressed: report.technicianRating != null
                          ? null
                          : _submitRatingAndReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmittingRating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              report.technicianRating != null
                                  ? 'Rating Sudah Dikirim'
                                  : 'Kirim Rating & Ulasan',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),

                    // Show submitted rating and review if available
                    if (report.technicianRating != null) ...[
                      SizedBox(height: 12),
                      Divider(color: Colors.amber[200]),
                      SizedBox(height: 8),
                      Text(
                        'Anda telah memberikan rating ${report.technicianRating!.toStringAsFixed(1)} bintang',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (report.hasReview()) ...[
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Text(
                            report.technicianReview!,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],

            _buildSectionTitle('Informasi Laporan'),
            SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.room, 'Ruangan', report.roomName),
              if (report.itemName.isNotEmpty)
                _buildInfoRow(Icons.category, 'Item', report.itemName),
              _buildInfoRow(
                Icons.access_time,
                'Tanggal',
                DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt),
              ),
              _buildInfoRow(
                Icons.person,
                'Pelapor',
                report.employeeName,
              ),
              // Add completion date in the information card as well
              if (report.status == 'completed' && report.completionDate != null)
                _buildInfoRow(
                  Icons.check_circle,
                  'Selesai',
                  DateFormat('dd MMM yyyy, HH:mm')
                      .format(report.completionDate!),
                ),
            ]),
            SizedBox(height: 20),

            // Original issue photo
            if (report.hasValidImage()) ...[
              _buildSectionTitle('Foto Masalah'),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showFullScreenImage(context, report.imageUrl!),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FirebaseStorageImage(
                          imageUrl: report.imageUrl,
                          fit: BoxFit.cover,
                          cacheDuration: Duration(days: 1),
                          forceFresh: true,
                          placeholder: Container(
                            color: Colors.grey[200],
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red),
                                  Text('Gagal memuat gambar'),
                                  SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {});
                                    },
                                    icon: Icon(Icons.refresh),
                                    label: Text('Coba lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
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
            ],

            // After completion photo (if available)
            if (report.hasValidAfterImage()) ...[
              _buildSectionTitle('Foto Setelah Perbaikan'),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    _showFullScreenImage(context, report.afterImageUrl!),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FirebaseStorageImage(
                          imageUrl: report.afterImageUrl,
                          fit: BoxFit.cover,
                          cacheDuration: Duration(days: 1),
                          forceFresh: true,
                          placeholder: Container(
                            color: Colors.grey[200],
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red),
                                  Text('Gagal memuat gambar'),
                                  SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {});
                                    },
                                    icon: Icon(Icons.refresh),
                                    label: Text('Coba lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
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
            ],

            // Show before/after comparison if both images are available
            if (report.hasValidImage() && report.hasValidAfterImage()) ...[
              _buildSectionTitle('Perbandingan Sebelum & Sesudah'),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Sebelum',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _showFullScreenImage(
                                    context, report.imageUrl!),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FirebaseStorageImage(
                                      imageUrl: report.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Sesudah',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _showFullScreenImage(
                                    context, report.afterImageUrl!),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.green[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FirebaseStorageImage(
                                      imageUrl: report.afterImageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tap pada gambar untuk melihat detail',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 20),
            _buildSectionTitle('Deskripsi Masalah'),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                report.description,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
            ),
            if (report.status == 'inProgress' &&
                report.assignedTechnicianId != null) ...[
              SizedBox(height: 20),
              _buildSectionTitle('Teknisi yang Ditugaskan'),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.engineering,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.technicianName ?? 'Tidak diketahui',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sedang mengerjakan permintaan pemeliharaan Anda',
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
              ),
            ],
            if (report.status == 'completed' &&
                report.completionReason != null) ...[
              SizedBox(height: 20),
              _buildSectionTitle('Catatan Penyelesaian'),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (report.completionDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.green[600]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Diselesaikan pada: ${DateFormat('dd MMM yyyy, HH:mm').format(report.completionDate!)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      report.completionReason!,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Jika Anda memiliki pertanyaan tentang laporan ini, silakan hubungi kantor manajemen.',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
