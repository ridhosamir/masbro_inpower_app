import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/resourceApp/request_model.dart';
import '../../../models/user_model.dart';
import '../../../services/resourceApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/custom_button.dart';

class AssignTechnicianScreenResource extends StatefulWidget {
  final RequestModel request;
  const AssignTechnicianScreenResource({super.key, required this.request});

  @override
  State<AssignTechnicianScreenResource> createState() =>
      _AssignTechnicianScreenResourceState();
}

class _AssignTechnicianScreenResourceState
    extends State<AssignTechnicianScreenResource> {
  final FirestoreServiceResource _firestoreService = FirestoreServiceResource();
  final UserService _userService = UserService();
  List<UserModel> _technicians = [];
  UserModel? _selectedTechnician;
  bool _isLoading = true;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    try {
      final technicians = await _userService.getTechnicians();
      if (mounted) {
        setState(() {
          _technicians = technicians;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat teknisi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignTechnician() async {
    if (_selectedTechnician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih teknisi terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      await _firestoreService.assignTechnician(
        widget.request,
        _selectedTechnician!.uid,
        _selectedTechnician!.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tugas ditugaskan ke ${_selectedTechnician!.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menugaskan teknisi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugaskan Resource'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Ringkasan Permintaan ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Permintaan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Pemohon', widget.request.employeeName),
                  if (widget.request.timeRequired != null)
                    _buildSummaryRow(
                      'Waktu Dibutuhkan',
                      widget.request.timeRequired!,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Deskripsi:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.blue[800]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.request.description,
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Daftar Teknisi Tersedia ---
            Text(
              'Pilih Teknisi',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_technicians.isEmpty)
              const Expanded(
                  child: Center(child: Text('Tidak ada teknisi tersedia.')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _technicians.length,
                  itemBuilder: (context, index) {
                    final technician = _technicians[index];
                    final isSelected =
                        _selectedTechnician?.uid == technician.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue[300]!
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedTechnician =
                                isSelected ? null : technician;
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor:
                              isSelected ? Colors.blue[100] : Colors.grey[200],
                          child: Icon(
                            Icons.engineering,
                            color: isSelected
                                ? Colors.blue[700]
                                : Colors.grey[600],
                          ),
                        ),
                        title: Text(
                          technician.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.blue[800]
                                : Colors.grey[800],
                          ),
                        ),
                        subtitle: Text(technician.email),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.blue[700])
                            : const Icon(Icons.radio_button_unchecked),
                      ),
                    );
                  },
                ),
              ),

            // --- Tombol Tugaskan ---
            if (_technicians.isNotEmpty) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'Tugaskan',
                onPressed: _assignTechnician,
                isLoading: _isAssigning,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Lebar disesuaikan
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }
}
