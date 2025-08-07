import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/maintenanceApp/report_model.dart';
import '../../../services/maintenanceApp/firestore_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'assign_technician_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _completionReasonController = TextEditingController();
  bool _isLoading = false;
  ReportModel? _updatedReport;

  @override
  void initState() {
    super.initState();
    _updatedReport = widget.report;
    _refreshReportData();
  }

  // Refresh report data to ensure we have the latest information including rating
  Future<void> _refreshReportData() async {
    try {
      final updatedReport =
          await _firestoreService.getReportWithRating(widget.report.id);
      if (updatedReport != null && mounted) {
        setState(() {
          _updatedReport = updatedReport;
        });
      }
    } catch (e) {
      print('Error refreshing report data: $e');
    }
  }

  @override
  void dispose() {
    _completionReasonController.dispose();
    super.dispose();
  }

  // Get color based on status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'inProgress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Get icon based on status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.pending;
      case 'inProgress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  // Get color based on rating value
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Use the updated report if available
    final report = _updatedReport ?? widget.report;

    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshReportData,
            tooltip: 'Refresh Report',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareReport,
            tooltip: 'Share Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(report.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(report.status)),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(report.status),
                    color: _getStatusColor(report.status),
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Status: ${report.getStatusDisplayName()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(report.status),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Created ${DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  // Show completion date if completed
                  if (report.status == 'completed' &&
                      report.completionDate != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'Completed ${DateFormat('dd MMM yyyy, HH:mm').format(report.completionDate!)}',
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

            // Report Information
            _buildSectionTitle('Report Information'),
            SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.room, 'Room', report.roomName),
              _buildInfoRow(Icons.person, 'Reporter', report.employeeName),
              _buildInfoRow(
                Icons.access_time,
                'Date',
                DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt),
              ),
            ]),
            SizedBox(height: 20),

            // Photo if available
            if (report.imageUrl != null) ...[
              _buildSectionTitle('Photo'),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    report.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Problem Description
            _buildSectionTitle('Problem Description'),
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

            // Completion Reason (if completed)
            if (report.status == 'completed' &&
                report.completionReason != null) ...[
              SizedBox(height: 20),
              _buildSectionTitle('Completion Notes'),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  report.completionReason!,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],

            // Assigned Technician Info (if assigned)
            if (report.assignedTechnicianId != null) ...[
              SizedBox(height: 20),
              _buildSectionTitle('Assigned Technician'),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
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
                                report.technicianName ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                report.status == 'completed'
                                    ? 'Completed this maintenance task'
                                    : 'Assigned to handle this maintenance task',
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

                    // Show rating if completed and has rating
                    if (report.status == 'completed' &&
                        report.technicianRating != null) ...[
                      SizedBox(height: 16),
                      Divider(height: 1, color: Colors.blue[200]),
                      SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Technician Rating',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                // Star rating display
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < (report.technicianRating!).floor()
                                          ? Icons.star
                                          : index <
                                                      (report.technicianRating!)
                                                          .ceil() &&
                                                  (report.technicianRating!)
                                                          .floor() !=
                                                      (report.technicianRating!)
                                                          .ceil()
                                              ? Icons.star_half
                                              : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  }),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${report.technicianRating!.toStringAsFixed(1)} out of 5.0',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _getRatingColor(
                                            report.technicianRating!),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRatingColor(
                                            report.technicianRating!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getPerformanceLabel(
                                            report.technicianRating!),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            SizedBox(height: 32),

            // Action Buttons based on status
            if (report.status == 'open') ...[
              _buildSectionTitle('Actions'),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Assign Technician',
                      onPressed: _assignTechnician,
                      isLoading: _isLoading,
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Mark Completed',
                      onPressed: _showCompleteDialog,
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ] else if (report.status == 'inProgress' &&
                report.assignedTechnicianId != null) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This report is being handled by ${report.technicianName}. The technician will update the status when completed.',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              CustomButton(
                text: 'Mark Completed',
                onPressed: _showCompleteDialog,
                backgroundColor: Colors.green,
              ),
            ],

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Get performance label based on rating
  String _getPerformanceLabel(double rating) {
    if (rating >= 4.5) return 'EXCELLENT';
    if (rating >= 4.0) return 'GOOD';
    if (rating >= 3.5) return 'AVERAGE';
    if (rating >= 3.0) return 'FAIR';
    return 'NEEDS IMPROVEMENT';
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

  void _assignTechnician() {
    // Check if report already has an assigned technician
    if (widget.report.assignedTechnicianId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'This report already has an assigned technician: ${widget.report.technicianName}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTechnicianScreen(report: widget.report),
      ),
    );
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide completion notes:'),
            SizedBox(height: 16),
            CustomTextField(
              labelText: 'Completion Notes',
              hintText: 'Enter notes about the completion...',
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
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: _completeReport,
            child: Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeReport() async {
    if (_completionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide completion notes'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.completeReport(
        widget.report.id,
        _completionReasonController.text.trim(),
        // If there's no technician assigned, use a default officer completion
        technicianId: widget.report.assignedTechnicianId ?? 'officer',
        technicianName: widget.report.technicianName ?? 'Office Management',
      );

      Navigator.pop(context); // Close dialog
      Navigator.pop(context); // Go back to dashboard

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report marked as completed'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing report: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Report'),
        content: Text('Share functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
