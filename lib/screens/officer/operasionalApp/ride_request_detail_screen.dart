import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/operasionalApp/ride_request_model.dart';
import '../../../services/operasionalApp/firestore_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'assign_driver_vehicle_screen.dart';

class RideRequestDetailScreen extends StatefulWidget {
  final RideRequestModel request;

  const RideRequestDetailScreen({Key? key, required this.request})
      : super(key: key);

  @override
  _RideRequestDetailScreenState createState() =>
      _RideRequestDetailScreenState();
}

class _RideRequestDetailScreenState extends State<RideRequestDetailScreen> {
  final OperasionalFirestoreService _firestoreService =
      OperasionalFirestoreService();
  final _completionNoteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _completionNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
                  SizedBox(height: 12),
                  Text(
                    'Status: ${widget.request.getStatusDisplayName()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.request.getStatusColor(),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Created on ${DateFormat('dd MMM yyyy, HH:mm').format(widget.request.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  // Show assignment date when status is in progress
                  if (widget.request.status == 'inProgress' &&
                      widget.request.assignedAt != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Assigned on ${DateFormat('dd MMM yyyy, HH:mm').format(widget.request.assignedAt!)}',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  // Show completion date when status is completed
                  if (widget.request.status == 'completed' &&
                      widget.request.completedAt != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Completed on ${DateFormat('dd MMM yyyy, HH:mm').format(widget.request.completedAt!)}',
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

            // Basic Information Section
            _buildSectionTitle('Request Information'),
            SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(
                Icons.location_on,
                'Pickup',
                widget.request.pickupLocation,
              ),
              _buildInfoRow(
                Icons.location_on,
                'Dropoff',
                widget.request.dropoffLocation,
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Pickup Date',
                DateFormat('dd MMM yyyy, HH:mm')
                    .format(widget.request.pickupDateTime),
              ),
              if (widget.request.returnDateTime != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Return Date',
                  DateFormat('dd MMM yyyy, HH:mm')
                      .format(widget.request.returnDateTime!),
                ),
              _buildInfoRow(
                Icons.group,
                'Passengers',
                '${widget.request.passengerCapacity}',
              ),
              _buildInfoRow(
                Icons.person,
                'Requester',
                widget.request.employeeName,
              ),
            ]),
            SizedBox(height: 20),

            // Description Section
            _buildSectionTitle('Description'),
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
                widget.request.description,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
            ),

            // Driver and Vehicle Information (if assigned)
            if (widget.request.status == 'inProgress' &&
                widget.request.driverName != null) ...[
              SizedBox(height: 20),
              _buildSectionTitle('Assigned Driver'),
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
                        Icons.person,
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
                            widget.request.driverName ?? 'Not assigned',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Assigned to handle your transportation request',
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
              if (widget.request.vehicleName != null) ...[
                SizedBox(height: 12),
                _buildSectionTitle('Assigned Vehicle'),
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
                          Icons.directions_car,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.request.vehicleName ?? 'Not assigned',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Completion Notes (if completed)
            if (widget.request.status == 'completed' &&
                widget.request.completionNote != null) ...[
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.request.completedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.green[600]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Completed on: ${DateFormat('dd MMM yyyy, HH:mm').format(widget.request.completedAt!)}',
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
                      widget.request.completionNote!,
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

            // Action Buttons (for officers)
            if (widget.request.status == 'open') ...[
              _buildSectionTitle('Actions'),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Assign Driver & Vehicle',
                      onPressed: () => _navigateToAssignDriverVehicle(),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Mark Completed',
                      onPressed: () => _showCompleteDialog(),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ] else if (widget.request.status == 'inProgress') ...[
              CustomButton(
                text: 'Mark Completed',
                onPressed: () => _showCompleteDialog(),
                backgroundColor: Colors.green,
              ),
            ],

            SizedBox(height: 20),

            // Info Box
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
                      'If you have questions about this ride request, please contact the transportation office.',
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

  void _navigateToAssignDriverVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AssignDriverVehicleScreen(request: widget.request),
      ),
    );
  }

  void _showCompleteDialog() {
    _completionNoteController.clear();

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
              controller: _completionNoteController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _completionNoteController.clear();
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: _completeRequest,
            child: _isLoading
                ? CircularProgressIndicator(strokeWidth: 2)
                : Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRequest() async {
    if (_completionNoteController.text.trim().isEmpty) {
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
      await _firestoreService.completeRideRequest(
        widget.request.id,
        _completionNoteController.text.trim(),
        driverId: widget.request.driverId,
        vehicleId: widget.request.vehicleId,
      );

      Navigator.pop(context); // Close dialog
      Navigator.pop(context); // Go back to dashboard

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request marked as completed'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
