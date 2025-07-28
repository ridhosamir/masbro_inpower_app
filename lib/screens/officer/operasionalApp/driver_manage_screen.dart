import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/operasionalApp/firestore_service.dart';
import '../../../models/operasionalApp/driver_model.dart';
import '../../../widgets/custom_text_field.dart';

class DriverManagementScreen extends StatefulWidget {
  @override
  _DriverManagementScreenState createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  final OperasionalFirestoreService _firestoreService =
      OperasionalFirestoreService();
  final _driverNameController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isAddingDriver = false;
  bool _isLoading = false;
  DriverModel? _selectedDriver;
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
    _driverNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Driver Management',
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
                        Icon(Icons.person, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Driver Management',
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
                      'Add, edit, or delete drivers for transportation requests.',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Add driver section
              _isAddingDriver
                  ? _buildAddDriverForm()
                  : ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isAddingDriver = true;
                          _selectedDriver = null;
                          _driverNameController.clear();
                        });
                      },
                      icon: Icon(Icons.add),
                      label: Text('Add New Driver'),
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
                    hintText: 'Search drivers...',
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

              // Drivers list title
              Text(
                'All Drivers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Divider(),
              SizedBox(height: 8),

              // Drivers list
              Expanded(
                child: _buildDriversList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddDriverForm() {
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
            _selectedDriver == null ? 'Add New Driver' : 'Edit Driver',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),

          // Driver Name
          Text(
            'Driver Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          CustomTextField(
            labelText: 'Driver Name',
            hintText: 'Enter driver name',
            controller: _driverNameController,
            prefixIcon: Icons.person,
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
                            _isAddingDriver = false;
                            _selectedDriver = null;
                            _driverNameController.clear();
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
                  onPressed: _isLoading ? null : _saveDriver,
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : Text(_selectedDriver == null
                          ? 'Add Driver'
                          : 'Update Driver'),
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

  Widget _buildDriversList() {
    return StreamBuilder<List<DriverModel>>(
      stream: _firestoreService.getDrivers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final allDrivers = snapshot.data ?? [];

        // Filter drivers based on search query
        final drivers = _searchQuery.isEmpty
            ? allDrivers
            : allDrivers
                .where((driver) =>
                    driver.name.toLowerCase().contains(_searchQuery))
                .toList();

        if (drivers.isEmpty) {
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
                    'No drivers match your search',
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
                  Icons.person_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No drivers available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Click the "Add New Driver" button to add a driver',
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
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
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
                    Icons.person,
                    color: Colors.blue[700],
                  ),
                ),
                title: _highlightSearchText(
                  driver.name,
                  _searchQuery,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: driver.isAvailable
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        driver.isAvailable ? 'Available' : 'On Duty',
                        style: TextStyle(
                          fontSize: 12,
                          color: driver.isAvailable ? Colors.green : Colors.red,
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
                          _selectedDriver = driver;
                          _driverNameController.text = driver.name;
                          _isAddingDriver = true;
                        });
                      },
                      tooltip: 'Edit Driver',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteDriver(driver),
                      tooltip: 'Delete Driver',
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

  Future<void> _saveDriver() async {
    final driverName = _driverNameController.text.trim();

    if (driverName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter driver name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedDriver == null) {
        // Adding new driver
        final driver = DriverModel(
          id: '',
          name: driverName,
          createdAt: DateTime.now(),
          isAvailable: true,
        );
        await _firestoreService.createDriver(driver);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Updating existing driver
        final updatedDriver = _selectedDriver!.copyWith(
          name: driverName,
        );
        await _firestoreService.updateDriver(updatedDriver);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() {
        _isAddingDriver = false;
        _selectedDriver = null;
        _driverNameController.clear();
      });
    } catch (e) {
      String errorMessage = e.toString();
      // Extract more user-friendly error message if it's our validation error
      if (errorMessage.contains('Driver with name')) {
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

  void _confirmDeleteDriver(DriverModel driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Driver'),
        content: Text(
          'Are you sure you want to delete the driver "${driver.name}"? This action cannot be undone.\n\n'
          'Note: You cannot delete a driver that is currently assigned to a ride request.',
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
                await _firestoreService.deleteDriver(driver.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Driver deleted successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                String errorMessage = e.toString();
                if (errorMessage.contains('Cannot delete driver')) {
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
