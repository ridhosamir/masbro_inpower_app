import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/utils/firebase_storage_image.dart';
import '../../models/report_model.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  Widget build(BuildContext context) {
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
                color: widget.report.getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.report.getStatusColor()),
              ),
              child: Column(
                children: [
                  Icon(
                    widget.report.getStatusIcon(),
                    color: widget.report.getStatusColor(),
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Status: ${widget.report.getStatusDisplayName()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.report.getStatusColor(),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dibuat pada ${DateFormat('dd MMM yyyy, HH:mm').format(widget.report.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildSectionTitle('Informasi Laporan'),
            SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.room, 'Ruangan', widget.report.roomName),
              if (widget.report.itemName.isNotEmpty)
                _buildInfoRow(Icons.category, 'Item', widget.report.itemName),
              _buildInfoRow(
                Icons.access_time,
                'Tanggal',
                DateFormat('dd MMM yyyy, HH:mm')
                    .format(widget.report.createdAt),
              ),
              _buildInfoRow(
                Icons.person,
                'Pelapor',
                widget.report.employeeName,
              ),
            ]),
            SizedBox(height: 20),
            if (widget.report.hasValidImage()) ...[
              _buildSectionTitle('Foto'),
              SizedBox(height: 12),
              Container(
                height: 200,
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FirebaseStorageImage(
                    imageUrl: widget.report.imageUrl,
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
              ),
            ],
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
                widget.report.description,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
            ),
            if (widget.report.status == 'inProgress' &&
                widget.report.assignedTechnicianId != null) ...[
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
                            widget.report.technicianName ?? 'Tidak diketahui',
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
            if (widget.report.status == 'completed' &&
                widget.report.completionReason != null) ...[
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
                    if (widget.report.completionDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Diselesaikan pada: ${DateFormat('dd MMM yyyy, HH:mm').format(widget.report.completionDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Text(
                      widget.report.completionReason!,
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
