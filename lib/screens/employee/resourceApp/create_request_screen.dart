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

class _CreateRequestScreenState extends State<CreateRequestScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _timeRequiredController = TextEditingController();
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();

  late TabController _tabController;
  bool _isLoading = false;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadUserData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // Membersihkan input field saat tab diganti untuk UX yang lebih baik
      _formKey.currentState?.reset();
      _descriptionController.clear();
      _timeRequiredController.clear();
      // Memaksa rebuild untuk menampilkan/menyembunyikan field yang sesuai
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
        initialEntryMode: TimePickerEntryMode.input,
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
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
      final requestType = _tabController.index == 0 ? 'resource' : 'item';

      final request = RequestModel(
        id: '',
        employeeId: authService.user!.uid,
        employeeName: currentUser!.name,
        description: _descriptionController.text.trim(),
        status: 'open',
        createdAt: DateTime.now(),
        request: requestType, // Mengisi atribut 'request' baru
        timeRequired: requestType == 'resource'
            ? _timeRequiredController.text.trim()
            : null,
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
                      _buildLabel('Waktu Dibutuhkan'),
                      CustomTextField(
                        labelText: 'Pilih Tanggal & Jam',
                        hintText: 'Contoh: 23 Juli 2025, 14:00',
                        controller: _timeRequiredController,
                        readOnly: true,
                        onTap: _selectDateTime,
                        prefixIcon: Icons.calendar_today,
                        validator: (value) {
                          if (isResourceRequest &&
                              (value == null || value.isEmpty)) {
                            return 'Harap tentukan waktu yang dibutuhkan';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildLabel(isResourceRequest
                        ? 'Deskripsi Kebutuhan'
                        : 'Deskripsi Item'),
                    CustomTextField(
                      labelText: 'Deskripsi',
                      hintText: isResourceRequest
                          ? 'Jelaskan kebutuhan Anda secara detail...'
                          : 'Contoh: Saya membutuhkan peralatan kantor, elektronik, ATK, dll',
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
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Kirim Permintaan',
                      onPressed: _submitRequest,
                      isLoading: _isLoading,
                      icon: Icons.send,
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
}
