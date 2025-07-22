import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../../services/auth_service.dart';
import '../../../services/maintenanceApp/firestore_service.dart';
import '../../../services/maintenanceApp/storage_service.dart';
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
        _imageUrl = await _storageService.uploadWebFile(_webImageBytes!, fileName);
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

      print('[CREATE_REPORT] Final image URL saved to report: ${report.imageUrl}');
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

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedBuildingId,
                hint: Text('Select a building'),
                items: buildings.map((building) {
                  return DropdownMenuItem<String>(
                    value: building.id,
                    child: Text(building.name),
                    onTap: () {
                      setState(() {
                        _selectedBuilding = building;
                      });
                    },
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBuildingId = value;
                    // Reset room selection when building changes
                    _selectedRoomId = null;
                    _selectedRoom = null;
                  });
                },
              ),
            ),
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

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedRoomId,
                  hint: Text('Select a room'),
                  items: rooms.map((room) {
                    return DropdownMenuItem<String>(
                      value: room.id,
                      child: Text(room.name),
                      onTap: () {
                        setState(() {
                          _selectedRoom = room;
                        });
                      },
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRoomId = value;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ],
    ],
  );
}
}