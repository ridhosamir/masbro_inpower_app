import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/maintenanceApp/firestore_service.dart';
import '../../../models/maintenanceApp/building_model.dart';
import '../../../widgets/custom_text_field.dart';

class BuildingManagementScreen extends StatefulWidget {
  @override
  _BuildingManagementScreenState createState() =>
      _BuildingManagementScreenState();
}

class _BuildingManagementScreenState extends State<BuildingManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _buildingNameController = TextEditingController();
  bool _isAddingBuilding = false;
  bool _isLoading = false;
  BuildingModel? _selectedBuilding;

  @override
  void dispose() {
    _buildingNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Building Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
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
                      Icon(Icons.info, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Text(
                        'Building Management',
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
                    'Add, edit, or delete buildings. Each building can contain multiple rooms.',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Add building section
            _isAddingBuilding
                ? _buildAddBuildingForm()
                : ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAddingBuilding = true;
                        _selectedBuilding = null;
                        _buildingNameController.clear();
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add New Building'),
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

            // Buildings list title
            Text(
              'All Buildings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),

            // Buildings list
            Expanded(
              child: _buildBuildingsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBuildingForm() {
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
            _selectedBuilding == null ? 'Add New Building' : 'Edit Building',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          CustomTextField(
            labelText: 'Building Name',
            hintText: 'Enter building name',
            controller: _buildingNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter building name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isAddingBuilding = false;
                            _selectedBuilding = null;
                            _buildingNameController.clear();
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
                  onPressed: _isLoading ? null : _saveBuilding,
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : Text(_selectedBuilding == null
                          ? 'Add Building'
                          : 'Update Building'),
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

  Widget _buildBuildingsList() {
    return StreamBuilder<List<BuildingModel>>(
      stream: _firestoreService.getBuildings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final buildings = snapshot.data ?? [];

        if (buildings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.domain_disabled,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No buildings added yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Click the "Add New Building" button to add a building',
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
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final building = buildings[index];
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
                    Icons.domain,
                    color: Colors.blue[700],
                  ),
                ),
                title: Text(
                  building.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Added on ${_formatDate(building.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          _selectedBuilding = building;
                          _buildingNameController.text = building.name;
                          _isAddingBuilding = true;
                        });
                      },
                      tooltip: 'Edit Building',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteBuilding(building),
                      tooltip: 'Delete Building',
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

  Future<void> _saveBuilding() async {
    final buildingName = _buildingNameController.text.trim();
    if (buildingName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter building name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedBuilding == null) {
        // Adding new building
        final building = BuildingModel(
          id: '',
          name: buildingName,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createBuilding(building);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Building added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Updating existing building
        final updatedBuilding = _selectedBuilding!.copyWith(
          name: buildingName,
        );
        await _firestoreService.updateBuilding(updatedBuilding);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Building updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() {
        _isAddingBuilding = false;
        _selectedBuilding = null;
        _buildingNameController.clear();
      });
    } catch (e) {
      String errorMessage = e.toString();
      // Extract more user-friendly error message if it's our validation error
      if (errorMessage.contains('Building with the name')) {
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

  void _confirmDeleteBuilding(BuildingModel building) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Building'),
        content: Text(
          'Are you sure you want to delete "${building.name}"? This action cannot be undone.\n\n'
          'Note: You cannot delete a building that has rooms assigned to it.',
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
                await _firestoreService.deleteBuilding(building.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Building deleted successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                String errorMessage = e.toString();
                if (errorMessage.contains('Cannot delete building')) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
