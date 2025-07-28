import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/operasionalApp/firestore_service.dart';
import '../../../models/operasionalApp/vehicle_model.dart';
import '../../../widgets/custom_text_field.dart';

class VehicleManagementScreen extends StatefulWidget {
  @override
  _VehicleManagementScreenState createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final OperasionalFirestoreService _firestoreService =
      OperasionalFirestoreService();
  final _vehicleTypeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _colorController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isAddingVehicle = false;
  bool _isLoading = false;
  VehicleModel? _selectedVehicle;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  // Search listener
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Clear search
  void _clearSearch() {
    _searchController.clear();
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehicleModelController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vehicle Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
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
                        Icon(Icons.directions_car, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Vehicle Management',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add, edit, or delete vehicles for transportation requests.',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Add vehicle section
              _isAddingVehicle
                  ? _buildAddVehicleForm()
                  : ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isAddingVehicle = true;
                          _selectedVehicle = null;
                          _vehicleTypeController.clear();
                          _vehicleModelController.clear();
                          _licensePlateController.clear();
                          _colorController.clear();
                        });
                      },
                      icon: Icon(Icons.add),
                      label: Text('Add New Vehicle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
              SizedBox(height: 24),

              // Search field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search vehicles...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Vehicles list title
              Text(
                'All Vehicles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Divider(),
              SizedBox(height: 8),

              // Vehicles list
              Expanded(
                child: _buildVehiclesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddVehicleForm() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedVehicle == null ? 'Add New Vehicle' : 'Edit Vehicle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),

          // Vehicle Type
          Text(
            'Vehicle Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          CustomTextField(
            labelText: 'Vehicle Type',
            hintText: 'e.g., SUV, Sedan, Van',
            controller: _vehicleTypeController,
            prefixIcon: Icons.category,
          ),
          SizedBox(height: 16),

          // Vehicle Model
          Text(
            'Vehicle Model',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          CustomTextField(
            labelText: 'Vehicle Model',
            hintText: 'e.g., Toyota Avanza',
            controller: _vehicleModelController,
            prefixIcon: Icons.directions_car,
          ),
          SizedBox(height: 16),

          // License Plate
          Text(
            'License Plate',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          CustomTextField(
            labelText: 'License Plate',
            hintText: 'e.g., B 1234 XYZ',
            controller: _licensePlateController,
            prefixIcon: Icons.credit_card,
          ),
          SizedBox(height: 16),

          // Color
          Text(
            'Color',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          CustomTextField(
            labelText: 'Color',
            hintText: 'e.g., Black, White, Silver',
            controller: _colorController,
            prefixIcon: Icons.color_lens,
          ),
          SizedBox(height: 24),

          // Form buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isAddingVehicle = false;
                            _selectedVehicle = null;
                            _vehicleTypeController.clear();
                            _vehicleModelController.clear();
                            _licensePlateController.clear();
                            _colorController.clear();
                          });
                        },
                  child: Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVehicle,
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : Text(_selectedVehicle == null
                          ? 'Add Vehicle'
                          : 'Update Vehicle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesList() {
    return StreamBuilder<List<VehicleModel>>(
      stream: _firestoreService.getVehicles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final allVehicles = snapshot.data ?? [];

        // Filter vehicles based on search query
        final vehicles = _searchQuery.isEmpty
            ? allVehicles
            : allVehicles
                .where((vehicle) =>
                    vehicle.vehicleType.toLowerCase().contains(_searchQuery) ||
                    vehicle.vehicleModel.toLowerCase().contains(_searchQuery) ||
                    vehicle.licensePlate.toLowerCase().contains(_searchQuery) ||
                    vehicle.color.toLowerCase().contains(_searchQuery))
                .toList();

        if (vehicles.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No vehicles match your search',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try a different search term or clear the search',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _clearSearch,
                    icon: Icon(Icons.clear, color: Colors.blue),
                    label: Text('Clear Search',
                        style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No vehicles available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Click the "Add New Vehicle" button to add a vehicle',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.blue[700],
                  ),
                ),
                title: _highlightSearchText(
                  '${vehicle.vehicleType} ${vehicle.vehicleModel}',
                  _searchQuery,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    _highlightSearchText(
                      'License: ${vehicle.licensePlate}',
                      _searchQuery,
                      TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    _highlightSearchText(
                      'Color: ${vehicle.color}',
                      _searchQuery,
                      TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: vehicle.isAvailable
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vehicle.isAvailable ? 'Available' : 'In Use',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              vehicle.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          _selectedVehicle = vehicle;
                          _vehicleTypeController.text = vehicle.vehicleType;
                          _vehicleModelController.text = vehicle.vehicleModel;
                          _licensePlateController.text = vehicle.licensePlate;
                          _colorController.text = vehicle.color;
                          _isAddingVehicle = true;
                        });
                      },
                      tooltip: 'Edit Vehicle',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteVehicle(vehicle),
                      tooltip: 'Delete Vehicle',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper to highlight search text
  Widget _highlightSearchText(String text, String searchQuery,
      [TextStyle? baseStyle]) {
    final defaultStyle = baseStyle ??
        TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        );

    if (searchQuery.isEmpty) {
      return Text(text, style: defaultStyle);
    }

    final matches = <Match>[];
    final pattern = RegExp(searchQuery, caseSensitive: false);
    pattern.allMatches(text).forEach((match) {
      matches.add(match);
    });

    if (matches.isEmpty) {
      return Text(text, style: defaultStyle);
    }

    final List<TextSpan> children = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      // Add highlighted match
      children.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: defaultStyle.copyWith(
          backgroundColor: Colors.yellow[200],
          color: Colors.black,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Add text after the last match
    if (lastMatchEnd < text.length) {
      children.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

    return RichText(text: TextSpan(children: children));
  }

  Future<void> _saveVehicle() async {
    final vehicleType = _vehicleTypeController.text.trim();
    final vehicleModel = _vehicleModelController.text.trim();
    final licensePlate = _licensePlateController.text.trim();
    final color = _colorController.text.trim();

    if (vehicleType.isEmpty ||
        vehicleModel.isEmpty ||
        licensePlate.isEmpty ||
        color.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedVehicle == null) {
        // Adding new vehicle
        final vehicle = VehicleModel(
          id: '',
          vehicleType: vehicleType,
          vehicleModel: vehicleModel,
          licensePlate: licensePlate,
          color: color,
          createdAt: DateTime.now(),
          isAvailable: true,
        );
        await _firestoreService.createVehicle(vehicle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Updating existing vehicle
        final updatedVehicle = _selectedVehicle!.copyWith(
          vehicleType: vehicleType,
          vehicleModel: vehicleModel,
          licensePlate: licensePlate,
          color: color,
        );
        await _firestoreService.updateVehicle(updatedVehicle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() {
        _isAddingVehicle = false;
        _selectedVehicle = null;
        _vehicleTypeController.clear();
        _vehicleModelController.clear();
        _licensePlateController.clear();
        _colorController.clear();
      });
    } catch (e) {
      String errorMessage = e.toString();
      // Extract more user-friendly error message if it's our validation error
      if (errorMessage.contains('Vehicle with license plate')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmDeleteVehicle(VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to delete the vehicle "${vehicle.vehicleType} ${vehicle.vehicleModel} - ${vehicle.licensePlate}"? This action cannot be undone.\n\n'
          'Note: You cannot delete a vehicle that is currently assigned to a ride request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteVehicle(vehicle.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vehicle deleted successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                String errorMessage = e.toString();
                if (errorMessage.contains('Cannot delete vehicle')) {
                  errorMessage = errorMessage.replaceAll('Exception: ', '');
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $errorMessage'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
