import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../models/operasionalApp/ride_request_model.dart';
import '../../../services/operasionalApp/firestore_service.dart';

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
  final _driverReviewController = TextEditingController();
  final _vehicleReviewController = TextEditingController();

  double _driverRating = 0;
  double _vehicleRating = 0;
  bool _isSubmittingDriverRating = false;
  bool _isSubmittingVehicleRating = false;
  RideRequestModel? _updatedRequest;

  @override
  void initState() {
    super.initState();
    _updatedRequest = widget.request;

    // Initialize ratings with stored values if they exist
    if (widget.request.hasDriverRating()) {
      _driverRating = widget.request.driverRating!;
    }
    if (widget.request.hasVehicleRating()) {
      _vehicleRating = widget.request.vehicleRating!;
    }

    // Refresh request data to ensure we have the latest ratings
    if (widget.request.status == 'completed') {
      _refreshRequestData();
    }
  }

  @override
  void dispose() {
    _driverReviewController.dispose();
    _vehicleReviewController.dispose();
    super.dispose();
  }

  Future<void> _refreshRequestData() async {
    try {
      final updatedRequest =
          await _firestoreService.getRideRequestWithRatings(widget.request.id);
      if (updatedRequest != null && mounted) {
        setState(() {
          _updatedRequest = updatedRequest;
          if (updatedRequest.hasDriverRating()) {
            _driverRating = updatedRequest.driverRating!;
          }
          if (updatedRequest.hasVehicleRating()) {
            _vehicleRating = updatedRequest.vehicleRating!;
          }
        });
      }
    } catch (e) {
      print('Error refreshing request data: $e');
    }
  }

  Future<void> _submitDriverRating() async {
    if (_driverRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a rating for the driver'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingDriverRating = true;
    });

    try {
      final review = _driverReviewController.text.trim();

      await _firestoreService.rateDriver(
        widget.request.id,
        _driverRating,
        widget.request.driverId!,
        review: review.isNotEmpty ? review : null,
      );

      // Refresh request data after rating
      await _refreshRequestData();

      if (mounted) {
        setState(() {
          _isSubmittingDriverRating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver rating submitted successfully, thank you!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingDriverRating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit driver rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitVehicleRating() async {
    if (_vehicleRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a rating for the vehicle'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingVehicleRating = true;
    });

    try {
      final review = _vehicleReviewController.text.trim();

      await _firestoreService.rateVehicle(
        widget.request.id,
        _vehicleRating,
        widget.request.vehicleId!,
        review: review.isNotEmpty ? review : null,
      );

      // Refresh request data after rating
      await _refreshRequestData();

      if (mounted) {
        setState(() {
          _isSubmittingVehicleRating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle rating submitted successfully, thank you!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingVehicleRating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit vehicle rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the updated request if available, otherwise use the original
    final request = _updatedRequest ?? widget.request;

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

            // Driver Rating Section (only for completed requests with assigned driver)
            if (request.status == 'completed' && request.driverId != null) ...[
              _buildSectionTitle('Rate Your Driver'),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'How was ${request.driverName}\'s service?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    RatingBar.builder(
                      initialRating: _driverRating,
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
                        if (request.driverRating == null) {
                          setState(() {
                            _driverRating = rating;
                          });
                        }
                      },
                      ignoreGestures: request.driverRating != null,
                    ),
                    SizedBox(height: 16),

                    // Driver review text field
                    if (request.driverRating == null) ...[
                      TextField(
                        controller: _driverReviewController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Add a review about the driver\'s service...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.blue[700]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Submit button for driver rating
                    ElevatedButton(
                      onPressed: request.driverRating != null
                          ? null
                          : _submitDriverRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmittingDriverRating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              request.driverRating != null
                                  ? 'Driver Rating Submitted'
                                  : 'Submit Driver Rating',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),

                    // Show submitted driver rating and review if available
                    if (request.driverRating != null) ...[
                      SizedBox(height: 12),
                      Divider(color: Colors.blue[200]),
                      SizedBox(height: 8),
                      Text(
                        'You rated the driver ${request.driverRating!.toStringAsFixed(1)} stars',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (request.hasDriverReview()) ...[
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            request.driverReview!,
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

            // Vehicle Rating Section (only for completed requests with assigned vehicle)
            if (request.status == 'completed' && request.vehicleId != null) ...[
              _buildSectionTitle('Rate the Vehicle'),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'How was the condition of ${request.vehicleName}?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    RatingBar.builder(
                      initialRating: _vehicleRating,
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
                        if (request.vehicleRating == null) {
                          setState(() {
                            _vehicleRating = rating;
                          });
                        }
                      },
                      ignoreGestures: request.vehicleRating != null,
                    ),
                    SizedBox(height: 16),

                    // Vehicle review text field
                    if (request.vehicleRating == null) ...[
                      TextField(
                        controller: _vehicleReviewController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Add a review about the vehicle condition...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.green[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.green[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.green[700]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Submit button for vehicle rating
                    ElevatedButton(
                      onPressed: request.vehicleRating != null
                          ? null
                          : _submitVehicleRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmittingVehicleRating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              request.vehicleRating != null
                                  ? 'Vehicle Rating Submitted'
                                  : 'Submit Vehicle Rating',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),

                    // Show submitted vehicle rating and review if available
                    if (request.vehicleRating != null) ...[
                      SizedBox(height: 12),
                      Divider(color: Colors.green[200]),
                      SizedBox(height: 8),
                      Text(
                        'You rated the vehicle ${request.vehicleRating!.toStringAsFixed(1)} stars',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (request.hasVehicleReview()) ...[
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            request.vehicleReview!,
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
                DateFormat('dd MMM yyyy, HH:mm').format(request.pickupDateTime),
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
                      request.status == 'completed' && !request.isFullyRated()
                          ? 'Please rate your experience to help us improve our service.'
                          : 'If you have questions about this ride request, please contact the transportation office.',
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
