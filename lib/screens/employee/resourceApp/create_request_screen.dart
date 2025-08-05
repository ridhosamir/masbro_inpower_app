import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/resourceApp/firestore_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/resourceApp/request_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _timeRequiredController = TextEditingController();
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();
  final _descriptionFocusNode = FocusNode();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isDescriptionFocused = false;

  late TabController _tabController;
  bool _isLoading = false;
  UserModel? currentUser;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _imageUrl;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadUserData();

    _descriptionFocusNode.addListener(() {
      setState(() {
        _isDescriptionFocused = _descriptionFocusNode.hasFocus;
      });
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _formKey.currentState?.reset();
      _descriptionController.clear();
      _timeRequiredController.clear();
      _selectedDate = null;
      _selectedTime = null;
      _imageFile = null;
      _webImageBytes = null;
      _imageUrl = null;
      _imageError = null;
      setState(() {});
    }
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (authService.user != null) {
      final userData = await userService.getUserData(authService.user!.uid);
      if (mounted) {
        setState(() {
          currentUser = userData;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _descriptionController.dispose();
    _timeRequiredController.dispose();
    _descriptionFocusNode.dispose();
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
        throw Exception('Format gambar tidak valid');
      }
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        throw Exception('File bukan gambar yang valid');
      }
      print('[CREATE_REQUEST] Gambar valid: ${decodedImage.format}');
      return true;
    } catch (e) {
      print('[CREATE_REQUEST] Gagal validasi gambar: $e');
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
        _imageError = 'Error mengakses kamera: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mengakses kamera: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        _imageError = 'Error mengakses galeri: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mengakses galeri: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTime = null;
        _timeRequiredController.text =
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(pickedDate);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;

    if (_tabController.index == 0 &&
        (_selectedDate == null || _selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap tentukan tanggal dan jam yang dibutuhkan'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final requestType = _tabController.index == 0 ? 'resource' : 'item';

      if (requestType == 'item') {
        if (_imageFile != null && !kIsWeb) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'requests/${authService.user!.uid}_$timestamp.jpg';
          _imageUrl = await _storageService.uploadFile(_imageFile!, fileName);
        } else if (_webImageBytes != null && kIsWeb) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'requests/${authService.user!.uid}_$timestamp.jpg';
          _imageUrl =
              await _storageService.uploadWebFile(_webImageBytes!, fileName);
        }
      }

      String? timeRequiredString;
      if (requestType == 'resource' &&
          _selectedDate != null &&
          _selectedTime != null) {
        final DateTime finalDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        timeRequiredString = DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID')
            .format(finalDateTime);
      }

      final request = RequestModel(
        id: '',
        employeeId: authService.user!.uid,
        employeeName: currentUser!.name,
        description: _descriptionController.text.trim(),
        status: 'open',
        createdAt: DateTime.now(),
        request: requestType,
        timeRequired: timeRequiredString,
        imageUrl: _imageUrl,
      );

      await _firestoreService.createRequest(request);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan berhasil dikirim!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Foto Item (Opsional)'),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeri'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (_imageFile != null || _webImageBytes != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _imageFile = null;
                  _webImageBytes = null;
                  _imageError = null;
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Hapus Gambar',
                  style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _getImageWidget() {
    if (_imageFile != null && !kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.file(_imageFile!, fit: BoxFit.cover),
      );
    } else if (_webImageBytes != null && kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Tambah Foto', style: TextStyle(color: Colors.grey[500])),
            if (_imageError != null) ...[
              const SizedBox(height: 8),
              Text(
                _imageError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
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
    final bool isResourceRequest = _tabController.index == 0;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 90.0,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Buat Permintaan Baru'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.supervisor_account),
                      SizedBox(width: 8),
                      Text('Resource')
                    ])),
                Tab(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.inventory),
                      SizedBox(width: 8),
                      Text('Item')
                    ])),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header Dinamis ---
                    _buildDynamicHeader(isResourceRequest, primaryColor),
                    const SizedBox(height: 24),

                    // --- Form Field Dinamis ---
                    if (isResourceRequest) ...[
                      _buildLabel('Tanggal Dibutuhkan'),
                      CustomTextField(
                        labelText: 'Pilih Tanggal',
                        controller: _timeRequiredController,
                        readOnly: true,
                        onTap: _selectDateTime,
                        prefixIcon: Icons.calendar_today,
                        validator: (value) {
                          if (isResourceRequest && (_selectedDate == null)) {
                            return 'Harap tentukan tanggal yang dibutuhkan';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Jam Dibutuhkan'),
                      _buildTimePicker(
                        'Pilih Jam',
                        _selectedTime,
                        (time) {
                          setState(() {
                            _selectedTime = time;
                            if (_selectedDate != null) {
                              final DateTime combinedDateTime = DateTime(
                                _selectedDate!.year,
                                _selectedDate!.month,
                                _selectedDate!.day,
                                _selectedTime!.hour,
                                _selectedTime!.minute,
                              );
                              _timeRequiredController.text = DateFormat(
                                      'EEEE, d MMMM yyyy, HH:mm', 'id_ID')
                                  .format(combinedDateTime);
                            }
                          });
                        },
                        selectedDate: _selectedDate,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildLabel(isResourceRequest
                        ? 'Deskripsi Kebutuhan'
                        : 'Deskripsi Item'),
                    CustomTextField(
                      focusNode: _descriptionFocusNode,
                      labelText: _isDescriptionFocused
                          ? 'Deskripsi Kebutuhan Anda'
                          : (isResourceRequest
                              ? 'Jelaskan kebutuhan resource anda...'
                              : 'Jelaskan barang yang anda perlukan...'),
                      controller: _descriptionController,
                      maxLines: 5,
                      prefixIcon: isResourceRequest
                          ? Icons.description_outlined
                          : Icons.inventory_2_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap jelaskan kebutuhan Anda';
                        }
                        if (value.length < 10) {
                          return 'Harap berikan deskripsi yang lebih detail';
                        }
                        return null;
                      },
                    ),
                    if (!isResourceRequest) ...[
                      const SizedBox(height: 24),
                      _buildImageSection(),
                    ],
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Kirim Permintaan',
                      onPressed: _submitRequest,
                      isLoading: _isLoading,
                      icon: Icons.send,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDynamicHeader(bool isResourceRequest, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            isResourceRequest ? Icons.supervisor_account : Icons.inventory,
            size: 48,
            color: primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            isResourceRequest
                ? 'Permintaan Bantuan Resource'
                : 'Permintaan Pengadaan Item',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isResourceRequest
                ? 'Jelaskan kebutuhan sumber daya manusia yang Anda perlukan.'
                : 'Jelaskan item atau barang yang Anda butuhkan untuk pekerjaan.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
      String label, TimeOfDay? value, Function(TimeOfDay) onPicked,
      {required DateTime? selectedDate}) {
    List<TimeOfDay> times = [];
    for (int i = 0; i < 24; i++) {
      times.add(TimeOfDay(hour: i, minute: 0));
      times.add(TimeOfDay(hour: i, minute: 30));
    }

    // Filter times based on selectedDate and current time if it's today
    if (selectedDate != null) {
      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      if (isToday) {
        final currentHour = now.hour;
        final currentMinute = now.minute;
        final filterStartMinute = (currentMinute < 30) ? 0 : 30;

        times = times.where((time) {
          if (time.hour > currentHour) {
            return true;
          } else if (time.hour == currentHour) {
            return time.minute >= filterStartMinute;
          }
          return false;
        }).toList();

        if (times.isEmpty &&
            now.isAfter(DateTime(now.year, now.month, now.day, 23, 30))) {
          value = null;
        } else if (value != null && !times.contains(value)) {
          value = null;
        }
      }
    }

    if (value != null && !times.contains(value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedTime = null;
          if (_selectedDate != null) {
            _timeRequiredController.text =
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate!);
          } else {
            _timeRequiredController.clear();
          }
        });
      });
    }

    return DropdownButtonFormField<TimeOfDay>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      menuMaxHeight: 200,
      items: times.map((time) {
        return DropdownMenuItem<TimeOfDay>(
          value: time,
          child: Text(
            time.format(context),
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onPicked(newValue);
        }
      },
      validator: (val) {
        if (val == null) {
          return 'Harap tentukan jam yang dibutuhkan';
        }

        if (selectedDate != null) {
          final now = DateTime.now();
          final isToday = selectedDate.year == now.year &&
              selectedDate.month == now.month &&
              selectedDate.day == now.day;

          if (isToday) {
            final selectedDateTime = DateTime(selectedDate.year,
                selectedDate.month, selectedDate.day, val.hour, val.minute);
            if (selectedDateTime
                .isBefore(now.subtract(const Duration(minutes: 1)))) {
              return 'Waktu yang dipilih sudah lewat';
            }
          }
        }
        return null;
      },
    );
  }
}
