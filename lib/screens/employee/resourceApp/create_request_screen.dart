import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/resourceApp/firestore_service.dart';
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

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _timeRequiredController = TextEditingController();
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();

  bool _isLoading = false;
  UserModel? currentUser;

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
      if (mounted) {
        setState(() {
          currentUser = userData;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _timeRequiredController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        // Format tanggal dan waktu agar mudah dibaca
        String formattedDateTime =
            DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID')
                .format(finalDateTime);
        setState(() {
          _timeRequiredController.text = formattedDateTime;
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final request = RequestModel(
        id: '',
        employeeId: authService.user!.uid,
        employeeName: currentUser!.name,
        description: _descriptionController.text.trim(),
        status: 'open',
        createdAt: DateTime.now(),
        timeRequired: _timeRequiredController.text.trim(),
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
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Create Resource',
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
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.support_agent,
                            size: 48,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Permintaan Bantuan Resource',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Jelaskan kebutuhan sumber daya manusia yang Anda perlukan.',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Waktu Dibutuhkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      labelText: 'Pilih Tanggal & Jam',
                      hintText: 'Contoh: 23 Juli 2025, 14:00',
                      controller: _timeRequiredController,
                      readOnly: true,
                      onTap: _selectDateTime,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap tentukan waktu yang dibutuhkan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Deskripsi Kebutuhan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      labelText: 'Deskripsi',
                      hintText: 'Jelaskan kebutuhan Anda secara detail...',
                      controller: _descriptionController,
                      maxLines: 5,
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
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Kirim Permintaan',
                      onPressed: _submitRequest,
                      isLoading: _isLoading,
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
