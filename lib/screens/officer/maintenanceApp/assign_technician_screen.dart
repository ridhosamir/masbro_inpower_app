import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/maintenanceApp/report_model.dart';
import '../../../models/user_model.dart';
import '../../../services/maintenanceApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/custom_button.dart';

class AssignTechnicianScreen extends StatefulWidget {
  final ReportModel report;

  const AssignTechnicianScreen({Key? key, required this.report})
      : super(key: key);

  @override
  _AssignTechnicianScreenState createState() => _AssignTechnicianScreenState();
}

class _AssignTechnicianScreenState extends State<AssignTechnicianScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final UserService _userService = UserService();
  List<UserModel> _technicians = [];
  UserModel? _selectedTechnician;
  bool _isLoading = false;
  bool _isAssigning = false;
  String _sortBy = 'rating'; // 'rating', 'name', 'experience'

  @override
  void initState() {
    super.initState();
    // Check if report already has an assigned technician
    if (widget.report.assignedTechnicianId != null) {
      // Navigate back with message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'This report already has an assigned technician: ${widget.report.technicianName}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    } else {
      _loadTechnicians();
    }
  }

  Future<void> _loadTechnicians() async {
    setState(() => _isLoading = true);

    try {
      final technicians = await _userService.getTechnicians();
      if (mounted) {
        setState(() {
          // Filter out technicians containing "driver" in their name or email
          _technicians = technicians.where((tech) {
            final nameContainsDriver =
                tech.name.toLowerCase().contains('driver');
            final emailContainsDriver =
                tech.email.toLowerCase().contains('driver');
            return !nameContainsDriver && !emailContainsDriver;
          }).toList();

          // Sort by rating initially
          _sortTechnicians();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading technicians: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _sortTechnicians() {
    setState(() {
      switch (_sortBy) {
        case 'rating':
          _technicians.sort((a, b) {
            final ratingA = a.averageRating ?? 0.0;
            final ratingB = b.averageRating ?? 0.0;
            // Sort by rating (highest first), then by total ratings if same rating
            if (ratingA != ratingB) {
              return ratingB.compareTo(ratingA);
            }
            final totalA = a.totalRatings ?? 0;
            final totalB = b.totalRatings ?? 0;
            return totalB.compareTo(totalA);
          });
          break;
        case 'name':
          _technicians.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'experience':
          _technicians.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
      }
    });
  }

  Future<void> _assignTechnician() async {
    if (_selectedTechnician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a technician'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      // Use the updated FirestoreService method to assign technician
      await _firestoreService.assignTechnician(
        widget.report,
        _selectedTechnician!.uid,
        _selectedTechnician!.name,
      );

      if (mounted) {
        setState(() => _isAssigning = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task assigned to ${_selectedTechnician!.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Go back to detail screen and dashboard
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning technician: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Technician'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Summary Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildSummaryRow('Room', widget.report.roomName),
                  _buildSummaryRow('Reporter', widget.report.employeeName),
                  _buildSummaryRow(
                    'Date',
                    DateFormat('dd MMM yyyy').format(widget.report.createdAt),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.report.description,
                    style: TextStyle(color: Colors.blue[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Header with sorting options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Technician',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                // Sort dropdown
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: Icon(Icons.sort, size: 18),
                      isDense: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _sortBy = newValue;
                          });
                          _sortTechnicians();
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'rating',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              SizedBox(width: 4),
                              Text('Rating', style: TextStyle(fontSize: 14)),
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
                              Text('Name', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'experience',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 16),
                              SizedBox(width: 4),
                              Text('Experience',
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
            SizedBox(height: 12),

            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading technicians...'),
                    ],
                  ),
                ),
              )
            else if (_technicians.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.engineering,
                          size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No Technicians Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'No technicians are registered in the system',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _technicians.length,
                  itemBuilder: (context, index) {
                    final technician = _technicians[index];
                    final isSelected =
                        _selectedTechnician?.uid == technician.uid;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTechnician =
                                isSelected ? null : technician;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.white,
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
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar with rating badge
                              Stack(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue[100]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Icon(
                                      Icons.engineering,
                                      color: isSelected
                                          ? Colors.blue[700]
                                          : Colors.grey[600],
                                      size: 28,
                                    ),
                                  ),
                                  // Rating badge
                                  if (technician.averageRating != null &&
                                      technician.totalRatings != null &&
                                      technician.totalRatings! > 0)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getRatingColor(
                                              technician.averageRating!),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: Text(
                                          technician.averageRating!
                                              .toStringAsFixed(1),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name and selection indicator
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
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.blue[700],
                                            size: 24,
                                          )
                                        else
                                          Icon(
                                            Icons.radio_button_unchecked,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      technician.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),

                                    // Rating section with enhanced display
                                    _buildTechnicianRatingEnhanced(technician),

                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 12, color: Colors.grey[500]),
                                        SizedBox(width: 4),
                                        Text(
                                          'Member since ${DateFormat('MMM yyyy').format(technician.createdAt)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        // Experience indicator
                                        Icon(Icons.timeline,
                                            size: 12, color: Colors.grey[500]),
                                        SizedBox(width: 4),
                                        Text(
                                          _getExperienceText(
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
              ),

            // Assign Button
            if (_technicians.isNotEmpty) ...[
              SizedBox(height: 16),
              CustomButton(
                text: 'Assign Task',
                onPressed: _assignTechnician,
                isLoading: _isAssigning,
                backgroundColor: Colors.blue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }

  String _getExperienceText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y exp';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}m exp';
    } else {
      return '${difference.inDays}d exp';
    }
  }

  Widget _buildTechnicianRatingEnhanced(UserModel technician) {
    // Check if technician has ratings
    if (technician.averageRating != null &&
        technician.totalRatings != null &&
        technician.totalRatings! > 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            // Star rating
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
            SizedBox(width: 4),
            // Rating text
            Text(
              '${technician.averageRating!.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getRatingColor(technician.averageRating!),
              ),
            ),
            SizedBox(width: 4),
            Text(
              '(${technician.totalRatings})',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(width: 6),
            // Performance indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _getRatingColor(technician.averageRating!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getPerformanceLabel(technician.averageRating!),
                style: TextStyle(
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, color: Colors.grey[400], size: 14),
          SizedBox(width: 4),
          Text(
            'No ratings yet',
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

  String _getPerformanceLabel(double rating) {
    if (rating >= 4.5) return 'EXCELLENT';
    if (rating >= 4.0) return 'GOOD';
    if (rating >= 3.5) return 'AVERAGE';
    if (rating >= 3.0) return 'FAIR';
    return 'POOR';
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
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
}
