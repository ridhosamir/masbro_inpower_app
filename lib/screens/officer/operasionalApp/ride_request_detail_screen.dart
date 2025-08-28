import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
  RideRequestModel? _updatedRequest; // ← TAMBAH: Variable untuk updated request

  @override
  void initState() {
    super.initState();
    _updatedRequest = widget.request; // ← TAMBAH: Set initial value
    _refreshRequestData(); // ← TAMBAH: Load fresh data
  }

  @override
  void dispose() {
    _completionNoteController.dispose();
    super.dispose();
  }

  // ← TAMBAH: Method untuk refresh data request
  Future<void> _refreshRequestData() async {
    setState(() => _isLoading = true);

    try {
      print('Refreshing request data for ID: ${widget.request.id}');

      // Ambil data terbaru dari Firestore
      final updatedRequest =
          await _firestoreService.getRideRequestById(widget.request.id);

      // Debug print untuk check data
      print('DEBUG: Request ID: ${widget.request.id}');
      print('DEBUG: Fetched Driver ID: ${updatedRequest?.driverId}');
      print('DEBUG: Fetched Driver Name: ${updatedRequest?.driverName}');
      print('DEBUG: Fetched Vehicle ID: ${updatedRequest?.vehicleId}');
      print('DEBUG: Fetched Vehicle Name: ${updatedRequest?.vehicleName}');
      print('DEBUG: Fetched Status: ${updatedRequest?.status}');
      print('DEBUG: Fetched Assigned At: ${updatedRequest?.assignedAt}');

      if (updatedRequest != null && mounted) {
        setState(() {
          _updatedRequest = updatedRequest;
          _isLoading = false;
        });
        print('Request state updated with new data');
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error refreshing request data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _updatedRequest ?? widget.request;

    return Scaffold(
      appBar: AppBar(
        title: Text('Request Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // ← TAMBAH: Refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshRequestData,
            tooltip: 'Refresh Request',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Refreshing request data...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: request.getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: request.getStatusColor()),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          request.getStatusIcon(),
                          color: request.getStatusColor(),
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Status: ${request.getStatusDisplayName()}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: request.getStatusColor(),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Created on ${DateFormat('dd MMM yyyy, HH:mm').format(request.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        // Show assignment date when status is in progress
                        if (request.status == 'inProgress' &&
                            request.assignedAt != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Assigned on ${DateFormat('dd MMM yyyy, HH:mm').format(request.assignedAt!)}',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        // Show completion date when status is completed
                        if (request.status == 'completed' &&
                            request.completedAt != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Completed on ${DateFormat('dd MMM yyyy, HH:mm').format(request.completedAt!)}',
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

                  // Employee Ratings Display (Read-only for Officer)
                  if (request.status == 'completed' &&
                      (request.hasDriverRating() ||
                          request.hasVehicleRating())) ...[
                    _buildSectionTitle('Employee Ratings'),
                    SizedBox(height: 12),

                    // Driver Rating Display
                    if (request.hasDriverRating()) ...[
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
                            Row(
                              children: [
                                Icon(Icons.person,
                                    color: Colors.blue[700], size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Driver Rating: ${request.driverName}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: request.driverRating!,
                                  itemBuilder: (context, index) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 20.0,
                                  direction: Axis.horizontal,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '${request.driverRating!.toStringAsFixed(1)} / 5.0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (request.hasDriverReview()) ...[
                              SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Employee Review:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      request.driverReview!,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                    ],

                    // Vehicle Rating Display
                    if (request.hasVehicleRating()) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.directions_car,
                                    color: Colors.green[700], size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Vehicle Rating: ${request.vehicleName}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: request.vehicleRating!,
                                  itemBuilder: (context, index) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 20.0,
                                  direction: Axis.horizontal,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '${request.vehicleRating!.toStringAsFixed(1)} / 5.0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (request.hasVehicleReview()) ...[
                              SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Employee Review:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      request.vehicleReview!,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                    ],

                    // No ratings message
                    if (!request.hasDriverRating() &&
                        !request.hasVehicleRating()) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star_border,
                                color: Colors.grey[600], size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Employee has not provided ratings yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                  ],

                  // Basic Information Section
                  _buildSectionTitle('Request Information'),
                  SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.location_on,
                      'Pickup',
                      request.pickupLocation,
                    ),
                    _buildInfoRow(
                      Icons.location_on,
                      'Dropoff',
                      request.dropoffLocation,
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Pickup Date',
                      DateFormat('dd MMM yyyy, HH:mm')
                          .format(request.pickupDateTime),
                    ),
                    if (request.returnDateTime != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Return Date',
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(request.returnDateTime!),
                      ),
                    _buildInfoRow(
                      Icons.group,
                      'Passengers',
                      '${request.passengerCapacity}',
                    ),
                    _buildInfoRow(
                      Icons.person,
                      'Requester',
                      request.employeeName,
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
                      request.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),

                  // Driver and Vehicle Information (if assigned)
                  if (request.status == 'inProgress' &&
                      request.driverName != null) ...[
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
                                  request.driverName ?? 'Not assigned',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Assigned to handle this transportation request',
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
                    if (request.vehicleName != null) ...[
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
                                request.vehicleName ?? 'Not assigned',
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
                  if (request.status == 'completed' &&
                      request.completionNote != null) ...[
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
                          if (request.completedAt != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 16, color: Colors.green[600]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Completed on: ${DateFormat('dd MMM yyyy, HH:mm').format(request.completedAt!)}',
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
                            request.completionNote!,
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

                  // Enhanced Action Buttons (for officers)
                  if (request.status == 'open') ...[
                    _buildSectionTitle('Actions'),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        // Assign Driver & Vehicle Button
                        Expanded(
                          child: _buildElegantButton(
                            icon: Icons.assignment_ind_rounded,
                            title: 'Assign Driver & Vehicle',
                            subtitle:
                                'Select driver and vehicle for this request',
                            gradient: LinearGradient(
                              colors: [Colors.blue[600]!, Colors.blue[700]!],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            onPressed: _navigateToAssignDriverVehicle,
                          ),
                        ),
                        SizedBox(width: 12),
                        // Mark Completed Button
                        Expanded(
                          child: _buildElegantButton(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'Mark as Completed',
                            subtitle: 'Complete this request with notes',
                            gradient: LinearGradient(
                              colors: [Colors.green[600]!, Colors.green[700]!],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            onPressed: _showCompleteDialog,
                          ),
                        ),
                      ],
                    ),
                  ] else if (request.status == 'inProgress') ...[
                    _buildSectionTitle('Actions'),
                    SizedBox(height: 16),
                    _buildElegantButton(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Mark as Completed',
                      subtitle: 'Complete this request with notes',
                      gradient: LinearGradient(
                        colors: [Colors.green[600]!, Colors.green[700]!],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      onPressed: _showCompleteDialog,
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

  // Enhanced elegant button widget
  Widget _buildElegantButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 14,
                ),
              ],
            ),
          ),
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

  // ← UBAH: Method navigation menjadi async dengan await result
  Future<void> _navigateToAssignDriverVehicle() async {
    final currentRequest = _updatedRequest ?? widget.request;

    if (currentRequest.driverId != null && currentRequest.vehicleId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This request already has assigned driver and vehicle'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // ← UBAH: Await the result dari navigation
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AssignDriverVehicleScreen(request: currentRequest),
      ),
    );

    // ← TAMBAH: Auto refresh jika berhasil
    if (result == true && mounted) {
      print('Driver/Vehicle assigned successfully, refreshing data...');
      await _refreshRequestData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

  // ← UBAH: Method complete request dengan refresh data
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
      final currentRequest =
          _updatedRequest ?? widget.request; // ← UBAH: gunakan _updatedRequest

      await _firestoreService.completeRideRequest(
        currentRequest.id,
        _completionNoteController.text.trim(),
        driverId: currentRequest.driverId,
        vehicleId: currentRequest.vehicleId,
      );

      Navigator.pop(context); // Close dialog

      // ← TAMBAH: Refresh data sebelum navigate back
      await _refreshRequestData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request marked as completed'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // ← TAMBAH: Delay sebelum navigate back
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
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
