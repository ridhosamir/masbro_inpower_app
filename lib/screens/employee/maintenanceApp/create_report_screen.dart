import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../../services/auth_service.dart';
import '../../../services/maintenanceApp/firestore_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/user_service.dart';
import '../../../models/maintenanceApp/report_model.dart';
import '../../../models/maintenanceApp/building_model.dart';
import '../../../models/maintenanceApp/room_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class CreateReportScreen extends StatefulWidget {
  @override
  _CreateReportScreenState createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  UserModel? currentUser;
  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _imageUrl;
  String? _imageError;

  // Building and room selection
  String? _selectedBuildingId;
  BuildingModel? _selectedBuilding;
  String? _selectedRoomId;
  RoomModel? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (authService.user != null) {
      final userData = await userService.getUserData(authService.user!.uid);
      setState(() {
        currentUser = userData;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _validateImage(dynamic image) async {
    try {
      Uint8List bytes;
      if (kIsWeb && image is Uint8List) {
        bytes = image;
      } else if (!kIsWeb && image is File) {
        bytes = await image.readAsBytes();
      } else {
        throw Exception('Invalid image format');
      }
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        throw Exception('File is not a valid image');
      }
      print('[CREATE_REPORT] Valid image: ${decodedImage.format}');
      return true;
    } catch (e) {
      print('[CREATE_REPORT] Failed to validate image: $e');
      return false;
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (await _validateImage(bytes)) {
            setState(() {
              _webImageBytes = bytes;
              _imageFile = null;
              _imageError = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image successfully captured from web camera'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            throw Exception('File is not a valid image');
          }
        } else {
          final file = File(image.path);
          if (await _validateImage(file)) {
            setState(() {
              _imageFile = file;
              _webImageBytes = null;
              _imageError = null;
            });
          } else {
            throw Exception('File is not a valid image');
          }
        }
      }
    } catch (e) {
      setState(() {
        _imageError = 'Error accessing camera: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing camera: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print('[CREATE_REPORT] Camera error: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (await _validateImage(bytes)) {
            setState(() {
              _webImageBytes = bytes;
              _imageFile = null;
              _imageError = null;
            });
          } else {
            throw Exception('File is not a valid image');
          }
        } else {
          final file = File(image.path);
          if (await _validateImage(file)) {
            setState(() {
              _imageFile = file;
              _webImageBytes = null;
              _imageError = null;
            });
          } else {
            throw Exception('File is not a valid image');
          }
        }
      }
    } catch (e) {
      setState(() {
        _imageError = 'Error accessing gallery: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing gallery: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print('[CREATE_REPORT] Gallery error: $e');
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;

    // Validate building and room selection
    if (_selectedBuildingId == null || _selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a building'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedRoomId == null || _selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a room'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Upload image if available
      if (_imageFile != null && !kIsWeb) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'reports/${authService.user!.uid}_$timestamp.jpg';
        _imageUrl = await _storageService.uploadFile(_imageFile!, fileName);
        print('[CREATE_REPORT] Mobile image URL: $_imageUrl');
      } else if (_webImageBytes != null && kIsWeb) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'reports/${authService.user!.uid}_$timestamp.jpg';
        _imageUrl =
            await _storageService.uploadWebFile(_webImageBytes!, fileName);
        print('[CREATE_REPORT] Web image URL: $_imageUrl');
      }

      final report = ReportModel(
        id: '',
        employeeId: authService.user!.uid,
        employeeName: currentUser!.name,
        buildingId: _selectedBuildingId!,
        buildingName: _selectedBuilding!.name,
        roomId: _selectedRoomId!,
        roomName: _selectedRoom!.name,
        itemName: '',
        description: _descriptionController.text.trim(),
        status: 'open',
        createdAt: DateTime.now(),
        imageUrl: _imageUrl,
      );

      print(
          '[CREATE_REPORT] Final image URL saved to report: ${report.imageUrl}');
      await _firestoreService.createReport(report);

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print('[CREATE_REPORT] Error: $e');
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _getImageWidget(),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _takePicture,
                icon: Icon(Icons.camera_alt),
                label: Text('Camera'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: Icon(Icons.photo_library),
                label: Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (_imageFile != null || _webImageBytes != null) ...[
          SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _imageFile = null;
                _webImageBytes = null;
              });
            },
            icon: Icon(Icons.delete, color: Colors.red),
            label: Text('Remove Image', style: TextStyle(color: Colors.red)),
          ),
        ],
        if (kIsWeb) ...[
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Running in web browser. Image handling is optimized for web.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _getImageWidget() {
    if (_imageFile != null && !kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
        ),
      );
    } else if (_webImageBytes != null && kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _webImageBytes!,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            if (_imageError != null) ...[
              SizedBox(height: 8),
              Text(
                _imageError!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }
  }

  // Building and Room section with searchable dropdowns
  Widget _buildBuildingRoomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Building selection
        Text(
          'Building',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        StreamBuilder<List<BuildingModel>>(
          stream: _firestoreService.getBuildings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final buildings = snapshot.data ?? [];

            if (buildings.isEmpty) {
              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No buildings available. Please contact an officer to add buildings.',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              );
            }

            return _buildSearchableDropdown(
              items: buildings,
              selectedValue: _selectedBuildingId,
              displayProperty: (building) => building.name,
              valueProperty: (building) => building.id,
              hintText: 'Search for a building...',
              onChanged: (value, item) {
                setState(() {
                  _selectedBuildingId = value;
                  _selectedBuilding = item;
                  // Reset room selection when building changes
                  _selectedRoomId = null;
                  _selectedRoom = null;
                });
              },
            );
          },
        ),

        // Room selection (only show if building is selected)
        if (_selectedBuildingId != null) ...[
          SizedBox(height: 24),
          Text(
            'Room',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          StreamBuilder<List<RoomModel>>(
            stream: _firestoreService.getRoomsByBuilding(_selectedBuildingId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              final rooms = snapshot.data ?? [];

              if (rooms.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No rooms available in this building. Please contact an officer to add rooms.',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _buildSearchableDropdown(
                items: rooms,
                selectedValue: _selectedRoomId,
                displayProperty: (room) => room.name,
                valueProperty: (room) => room.id,
                hintText: 'Search for a room...',
                onChanged: (value, item) {
                  setState(() {
                    _selectedRoomId = value;
                    _selectedRoom = item;
                  });
                },
              );
            },
          ),
        ],
      ],
    );
  }

  // Generic searchable dropdown widget
  Widget _buildSearchableDropdown<T>({
    required List<T> items,
    required String? selectedValue,
    required String Function(T) displayProperty,
    required String Function(T) valueProperty,
    required String hintText,
    required void Function(String?, T?) onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildSearchableDropdownModal(
            items: items,
            selectedValue: selectedValue,
            displayProperty: displayProperty,
            valueProperty: valueProperty,
            hintText: hintText,
            onChanged: onChanged,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedValue != null
                    ? items
                        .firstWhere(
                          (item) => valueProperty(item) == selectedValue,
                          orElse: () => items.first,
                        )
                        .let((item) => displayProperty(item))
                    : hintText,
                style: TextStyle(
                  color:
                      selectedValue != null ? Colors.black : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.search, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // Modal for searchable dropdown
  Widget _buildSearchableDropdownModal<T>({
    required List<T> items,
    required String? selectedValue,
    required String Function(T) displayProperty,
    required String Function(T) valueProperty,
    required String hintText,
    required void Function(String?, T?) onChanged,
  }) {
    // Create a filtered list
    List<T> filteredItems = List.from(items);
    String searchQuery = '';

    return StatefulBuilder(
      builder: (context, setState) {
        // Update filtered items when search query changes
        void updateSearch(String query) {
          setState(() {
            searchQuery = query.toLowerCase();
            filteredItems = items
                .where((item) =>
                    displayProperty(item).toLowerCase().contains(searchQuery))
                .toList();
          });
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select an item',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Search field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: updateSearch,
                  decoration: InputDecoration(
                    hintText: hintText,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  autofocus: true,
                ),
              ),
              // Items list
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No items found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final value = valueProperty(item);
                          final display = displayProperty(item);
                          final isSelected = value == selectedValue;

                          return ListTile(
                            title: Text(display),
                            tileColor: isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : null,
                            leading: isSelected
                                ? Icon(Icons.check_circle, color: Colors.blue)
                                : Icon(Icons.circle_outlined,
                                    color: Colors.grey),
                            onTap: () {
                              onChanged(value, item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Report',
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
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.report_problem,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Report Maintenance Issue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Provide detailed information about the maintenance issue',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Building and Room Selection
                  _buildBuildingRoomSection(),
                  SizedBox(height: 24),

                  // Image Upload
                  _buildImageSection(),
                  SizedBox(height: 24),

                  // Description
                  Text(
                    'Problem Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  CustomTextField(
                    labelText: 'Description',
                    hintText: 'Describe the problem in detail...',
                    controller: _descriptionController,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe the problem';
                      }
                      if (value.length < 10) {
                        return 'Please provide more detailed description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32),

                  // Submit Button
                  CustomButton(
                    text: 'Submit Report',
                    onPressed: _submitReport,
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: 16),

                  // Info Note
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
                            'Your report will be reviewed by an officer. You will be notified of the status.',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension method to simplify accessing properties
extension Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
