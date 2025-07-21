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
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class CreateReportScreen extends StatefulWidget {
  @override
  _CreateReportScreenState createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
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

  final List<String> _commonRooms = [
    'Meeting Room A',
    'Meeting Room B',
    'Office 101',
    'Office 102',
    'Pantry',
    'Reception',
    'Server Room',
    'Storage Room',
    'Toilet',
    'Lobby',
  ];

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
    _roomNameController.dispose();
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
        throw Exception('File bukan gambar yang valid');
      }
      print('[CREATE_REPORT] Gambar valid: ${decodedImage.format}');
      return true;
    } catch (e) {
      print('[CREATE_REPORT] Gagal memvalidasi gambar: $e');
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
                content: Text('Gambar berhasil diambil dari kamera web'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            throw Exception('File bukan gambar yang valid');
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
            throw Exception('File bukan gambar yang valid');
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
            throw Exception('File bukan gambar yang valid');
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
            throw Exception('File bukan gambar yang valid');
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
        roomName: _roomNameController.text.trim(),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Create Report',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
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
                    Text(
                      'Room Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    CustomTextField(
                      labelText: 'Room Name',
                      hintText: 'Select or enter room name',
                      controller: _roomNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter room name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonRooms.map((room) {
                        return GestureDetector(
                          onTap: () {
                            _roomNameController.text = room;
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              room,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24),
                    _buildImageSection(),
                    SizedBox(height: 24),
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
                    CustomButton(
                      text: 'Submit Report',
                      onPressed: _submitReport,
                      isLoading: _isLoading,
                    ),
                    SizedBox(height: 16),
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
        ],
      ),
    );
  }
}