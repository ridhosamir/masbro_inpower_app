import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/operasionalApp/ride_request_model.dart';

class RideRequestDetailScreen extends StatefulWidget {
  final RideRequestModel request;

  const RideRequestDetailScreen({Key? key, required this.request})
      : super(key: key);

  @override
  _RideRequestDetailScreenState createState() =>
      _RideRequestDetailScreenState();
}

class _RideRequestDetailScreenState extends State<RideRequestDetailScreen> {
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
            _buildSectionTitle('Request Information'),
            SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(
                Icons.location_on,
                'Pickup',
                widget.request.pickupLocation,
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Pickup Date',
                DateFormat('dd MMM yyyy, HH:mm')
                    .format(widget.request.pickupDateTime),
              ),
              _buildInfoRow(
                Icons.location_on,
                'Dropoff',
                widget.request.dropoffLocation,
              ),
              if (widget.request.returnDateTime != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Return',
                  DateFormat('dd MMM yyyy, HH:mm')
                      .format(widget.request.returnDateTime!),
                ),
              _buildInfoRow(
                Icons.group,
                'Passengers',
                '${widget.request.passengerCapacity} ${widget.request.passengerCapacity > 1 ? 'passengers' : 'passenger'}',
              ),
              _buildInfoRow(
                Icons.person,
                'Requester',
                widget.request.employeeName,
              ),
            ]),
            SizedBox(height: 20),
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

            // Show assigned driver and vehicle when in progress
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
              SizedBox(height: 12),
              if (widget.request.vehicleName != null) ...[
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

            // Show completion notes for completed requests
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
}
