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
      // Method 1: Get available technicians using direct query on drivers collection
      final availableDriversSnapshot = await _firestore
          .collection('drivers')
          .where('isAvailable', isEqualTo: true)
          .get();

      List<UserModel> availableTechnicians = [];

      // For each available driver, get the corresponding user data
      for (var driverDoc in availableDriversSnapshot.docs) {
        try {
          final userData = await _userService.getUserData(driverDoc.id);
          availableTechnicians.add(userData);
        } catch (e) {
          print('Error fetching user data for driver ${driverDoc.id}: $e');
        }
      }

      // Get available vehicles
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
          .where('status', isEqualTo: 'inProgress')
          .get();

      final driverIds = snapshot.docs
          .map((doc) => doc.data()['driverId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      final driversSnapshot = await _firestore
          .collection('drivers')
          .where('isAvailable', isEqualTo: false)
          .get();

      final unavailableDriverIds =
          driversSnapshot.docs.map((doc) => doc.id).toList();

      return [...driverIds, ...unavailableDriverIds].toSet().toList();
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
      await _firestoreService.assignDriverAndVehicle(
        widget.request.id,
        _selectedTechnician!.uid,
        _selectedTechnician!.name,
        _selectedVehicle!.id,
        "${_selectedVehicle!.vehicleType} ${_selectedVehicle!.vehicleModel} - ${_selectedVehicle!.licensePlate}",
      );

      if (mounted) {
        setState(() => _isAssigning = false);
        Navigator.pop(context, true);
        Navigator.pop(context);
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Assign Driver & Vehicle'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading available drivers and vehicles...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequestSummaryCard(),
                  SizedBox(height: 24),
                  _buildDriverSection(),
                  SizedBox(height: 24),
                  _buildVehicleSection(),
                  SizedBox(height: 32),
                  _buildAssignButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildRequestSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Request Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildSummaryRow(
                Icons.location_on, 'Pickup', widget.request.pickupLocation),
            _buildSummaryRow(
                Icons.location_on, 'Dropoff', widget.request.dropoffLocation),
            _buildSummaryRow(
                Icons.person, 'Requester', widget.request.employeeName),
            _buildSummaryRow(
              Icons.calendar_today,
              'Pickup Date',
              DateFormat('dd MMM yyyy, HH:mm')
                  .format(widget.request.pickupDateTime),
            ),
            if (widget.request.returnDateTime != null)
              _buildSummaryRow(
                Icons.calendar_today,
                'Return Date',
                DateFormat('dd MMM yyyy, HH:mm')
                    .format(widget.request.returnDateTime!),
              ),
            _buildSummaryRow(
              Icons.group,
              'Passengers',
              '${widget.request.passengerCapacity} ${widget.request.passengerCapacity > 1 ? 'passengers' : 'passenger'}',
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Description:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.request.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.engineering,
          title: 'Select Driver',
          subtitle: 'Choose an available technician as driver',
        ),
        SizedBox(height: 16),
        _buildSearchField(
          hintText: 'Search available drivers...',
          onChanged: (value) =>
              setState(() => _searchDriverQuery = value.toLowerCase()),
        ),
        SizedBox(height: 16),
        _buildTechniciansList(),
      ],
    );
  }

  Widget _buildVehicleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.directions_car,
          title: 'Select Vehicle',
          subtitle: _selectedTechnician == null
              ? 'Please select a driver first'
              : 'Choose an available vehicle',
        ),
        SizedBox(height: 16),
        _buildSearchField(
          hintText: 'Search available vehicles...',
          onChanged: (value) =>
              setState(() => _searchVehicleQuery = value.toLowerCase()),
          enabled: _selectedTechnician != null,
        ),
        SizedBox(height: 16),
        _buildVehiclesList(),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[500]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            Icons.search,
            color: enabled ? Colors.grey[600] : Colors.grey[400],
          ),
          suffixIcon: enabled &&
                  ((_searchDriverQuery.isNotEmpty) ||
                      (_searchVehicleQuery.isNotEmpty))
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      if (hintText.contains('driver')) {
                        _searchDriverQuery = '';
                      } else {
                        _searchVehicleQuery = '';
                      }
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
      return _buildEmptyState(
        icon: Icons.engineering,
        title: _searchDriverQuery.isEmpty
            ? 'No Available Drivers'
            : 'No Matching Drivers',
        subtitle: _searchDriverQuery.isEmpty
            ? 'All drivers are currently assigned to other tasks'
            : 'Try a different search term',
      );
    }

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: filteredTechnicians.length,
        itemBuilder: (context, index) {
          final technician = filteredTechnicians[index];
          final isSelected = _selectedTechnician?.uid == technician.uid;

          return Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            child: Material(
              color: Colors.transparent,
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
                    color: isSelected ? Colors.blue[50] : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [
                                  Colors.blue[400]!,
                                  Colors.blue[600]!
                                ])
                              : LinearGradient(colors: [
                                  Colors.grey[300]!,
                                  Colors.grey[400]!
                                ]),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.engineering,
                          color: Colors.white,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue[700]
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue[700]!
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ],
                  ),
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
      return _buildEmptyState(
        icon: Icons.directions_car,
        title: 'Select a driver first',
        subtitle: 'Please select a technician before choosing a vehicle',
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
      return _buildEmptyState(
        icon: Icons.directions_car,
        title: _searchVehicleQuery.isEmpty
            ? 'No Available Vehicles'
            : 'No Matching Vehicles',
        subtitle: _searchVehicleQuery.isEmpty
            ? 'All vehicles are currently in use'
            : 'Try a different search term',
      );
    }

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: filteredVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = filteredVehicles[index];
          final isSelected = _selectedVehicle?.id == vehicle.id;

          return Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            child: Material(
              color: Colors.transparent,
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
                    color: isSelected ? Colors.blue[50] : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [
                                  Colors.blue[400]!,
                                  Colors.blue[600]!
                                ])
                              : LinearGradient(colors: [
                                  Colors.grey[300]!,
                                  Colors.grey[400]!
                                ]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vehicle.vehicleType} ${vehicle.vehicleModel}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.blue[700]
                                    : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.confirmation_number,
                                    size: 14, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  vehicle.licensePlate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(Icons.color_lens,
                                    size: 14, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  vehicle.color,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue[700]
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue[700]!
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 48, color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignButton() {
    final canAssign = _selectedTechnician != null && _selectedVehicle != null;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: canAssign
            ? LinearGradient(
                colors: [Colors.green[600]!, Colors.green[700]!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: canAssign
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canAssign ? _assignDriverAndVehicle : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isAssigning) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                ] else ...[
                  Icon(
                    Icons.assignment_turned_in,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                ],
                Text(
                  _isAssigning ? 'Assigning...' : 'Assign Driver & Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
