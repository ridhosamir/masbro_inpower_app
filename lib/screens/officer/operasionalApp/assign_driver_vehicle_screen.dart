import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/operasionalApp/ride_request_model.dart';
import '../../../models/operasionalApp/vehicle_model.dart';
import '../../../models/user_model.dart';
import '../../../services/operasionalApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/custom_button.dart';

class AssignDriverVehicleScreen extends StatefulWidget {
  final RideRequestModel request;

  const AssignDriverVehicleScreen({Key? key, required this.request})
      : super(key: key);

  @override
  _AssignDriverVehicleScreenState createState() =>
      _AssignDriverVehicleScreenState();
}

class _AssignDriverVehicleScreenState extends State<AssignDriverVehicleScreen> {
  final OperasionalFirestoreService _firestoreService =
      OperasionalFirestoreService();
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _technicians = [];
  List<VehicleModel> _vehicles = [];
  UserModel? _selectedTechnician;
  VehicleModel? _selectedVehicle;
  bool _isLoading = false;
  bool _isAssigning = false;
  String _searchDriverQuery = '';
  String _searchVehicleQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.request.driverId != null && widget.request.vehicleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('This request already has assigned driver and vehicle'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    } else {
      _loadAvailableTechniciansAndVehicles();
    }
  }

  Future<void> _loadAvailableTechniciansAndVehicles() async {
    setState(() => _isLoading = true);

    try {
      final allTechnicians = await _userService.getTechnicians();
      final assignedDriverIds = await _getAssignedDriverIds();

      // Filter available technicians (contains 'driver' in name and not assigned)
      final availableTechnicians = allTechnicians
          .where((tech) =>
              tech.name.toLowerCase().contains('driver') &&
              !assignedDriverIds.contains(tech.uid))
          .toList();

      final availableVehicles =
          await _firestoreService.getAvailableVehicles().first;

      if (mounted) {
        setState(() {
          _technicians = availableTechnicians;
          _vehicles = availableVehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<List<String>> _getAssignedDriverIds() async {
    try {
      final snapshot = await _firestore
          .collection('ride_requests')
          .where('status', whereIn: ['assigned', 'in-progress']).get();

      return snapshot.docs
          .map((doc) => doc.data()['driverId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();
    } catch (e) {
      debugPrint('Error getting assigned drivers: $e');
      return [];
    }
  }

  Future<void> _assignDriverAndVehicle() async {
    if (_selectedTechnician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a technician as driver'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a vehicle'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      final batch = _firestore.batch();

      // Update ride request
      final requestRef =
          _firestore.collection('ride_requests').doc(widget.request.id);
      batch.update(requestRef, {
        'driverId': _selectedTechnician!.uid,
        'driverName': _selectedTechnician!.name,
        'vehicleId': _selectedVehicle!.id,
        'vehicleInfo':
            '${_selectedVehicle!.vehicleType} ${_selectedVehicle!.vehicleModel} - ${_selectedVehicle!.licensePlate}',
        'status': 'in-progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update vehicle
      final vehicleRef =
          _firestore.collection('vehicles').doc(_selectedVehicle!.id);
      batch.update(vehicleRef, {
        'status': 'in-use',
        'currentDriverId': _selectedTechnician!.uid,
        'currentDriverName': _selectedTechnician!.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Technician and vehicle assigned successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error assigning technician and vehicle: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        debugPrint('Assignment error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Technician & Vehicle'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequestSummaryCard(),
                  SizedBox(height: 20),
                  _buildSectionHeader('Available Technicians (Drivers)'),
                  SizedBox(height: 12),
                  _buildSearchField(
                    hintText: 'Search available technicians...',
                    onChanged: (value) => setState(
                        () => _searchDriverQuery = value.toLowerCase()),
                  ),
                  SizedBox(height: 12),
                  _buildTechniciansList(),
                  SizedBox(height: 20),
                  _buildSectionHeader('Available Vehicles'),
                  SizedBox(height: 12),
                  _buildSearchField(
                    hintText: 'Search available vehicles...',
                    onChanged: (value) => setState(
                        () => _searchVehicleQuery = value.toLowerCase()),
                    enabled: _selectedTechnician != null,
                  ),
                  SizedBox(height: 12),
                  _buildVehiclesList(),
                  SizedBox(height: 16),
                  CustomButton(
                    text: 'Assign Technician & Vehicle',
                    onPressed: _assignDriverAndVehicle,
                    isLoading: _isAssigning,
                    backgroundColor: Colors.blue,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRequestSummaryCard() {
    return Container(
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
            'Request Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 12),
          _buildSummaryRow('Pickup', widget.request.pickupLocation),
          _buildSummaryRow('Dropoff', widget.request.dropoffLocation),
          _buildSummaryRow('Requester', widget.request.employeeName),
          _buildSummaryRow(
            'Pickup Date',
            DateFormat('dd MMM yyyy, HH:mm')
                .format(widget.request.pickupDateTime),
          ),
          if (widget.request.returnDateTime != null)
            _buildSummaryRow(
              'Return Date',
              DateFormat('dd MMM yyyy, HH:mm')
                  .format(widget.request.returnDateTime!),
            ),
          _buildSummaryRow(
            'Passengers',
            '${widget.request.passengerCapacity} ${widget.request.passengerCapacity > 1 ? 'passengers' : 'passenger'}',
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
            widget.request.description,
            style: TextStyle(color: Colors.blue[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildSearchField({
    required String hintText,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: enabled ? Colors.grey[300]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(Icons.search,
              color: enabled ? Colors.grey[600] : Colors.grey[400]),
          suffixIcon: enabled &&
                  ((_searchDriverQuery.isNotEmpty) ||
                      (_searchVehicleQuery.isNotEmpty))
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      if (hintText.contains('technician')) {
                        _searchDriverQuery = '';
                      } else {
                        _searchVehicleQuery = '';
                      }
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTechniciansList() {
    final filteredTechnicians = _technicians
        .where((tech) =>
            _searchDriverQuery.isEmpty ||
            tech.name.toLowerCase().contains(_searchDriverQuery) ||
            tech.email.toLowerCase().contains(_searchDriverQuery))
        .toList();

    if (filteredTechnicians.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.engineering, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                _searchDriverQuery.isEmpty
                    ? 'No Available Drivers'
                    : 'No Matching Drivers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _searchDriverQuery.isEmpty
                    ? 'All drivers are currently assigned to other tasks'
                    : 'Try a different search term',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      child: ListView.builder(
        itemCount: filteredTechnicians.length,
        itemBuilder: (context, index) {
          final technician = filteredTechnicians[index];
          final isSelected = _selectedTechnician?.uid == technician.uid;

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTechnician = isSelected ? null : technician;
                  _selectedVehicle = null;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.engineering,
                        color: isSelected ? Colors.blue[700] : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technician.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.blue[700]
                                  : Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            technician.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    isSelected
                        ? Icon(Icons.check_circle,
                            color: Colors.blue[700], size: 20)
                        : Icon(Icons.radio_button_unchecked,
                            color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehiclesList() {
    if (_selectedTechnician == null) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                'Select a driver first',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Please select a technician before choosing a vehicle',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    final filteredVehicles = _vehicles
        .where((vehicle) =>
            _searchVehicleQuery.isEmpty ||
            vehicle.vehicleType.toLowerCase().contains(_searchVehicleQuery) ||
            vehicle.vehicleModel.toLowerCase().contains(_searchVehicleQuery) ||
            vehicle.licensePlate.toLowerCase().contains(_searchVehicleQuery) ||
            vehicle.color.toLowerCase().contains(_searchVehicleQuery))
        .toList();

    if (filteredVehicles.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                _searchVehicleQuery.isEmpty
                    ? 'No Available Vehicles'
                    : 'No Matching Vehicles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _searchVehicleQuery.isEmpty
                    ? 'All vehicles are currently in use'
                    : 'Try a different search term',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      child: ListView.builder(
        itemCount: filteredVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = filteredVehicles[index];
          final isSelected = _selectedVehicle?.id == vehicle.id;

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedVehicle = isSelected ? null : vehicle;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: isSelected ? Colors.blue[700] : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vehicle.vehicleType} ${vehicle.vehicleModel}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.blue[700]
                                  : Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'License: ${vehicle.licensePlate}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Color: ${vehicle.color}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    isSelected
                        ? Icon(Icons.check_circle,
                            color: Colors.blue[700], size: 20)
                        : Icon(Icons.radio_button_unchecked,
                            color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),
          );
        },
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
