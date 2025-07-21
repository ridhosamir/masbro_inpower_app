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
          _technicians = technicians;
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

            // Available Technicians
            Text(
              'Select Technician',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
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
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue[100]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Icon(
                                  Icons.engineering,
                                  color: isSelected
                                      ? Colors.blue[700]
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      technician.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.blue[700]
                                            : Colors.grey[800],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      technician.email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Member since ${DateFormat('MMM yyyy').format(technician.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
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
