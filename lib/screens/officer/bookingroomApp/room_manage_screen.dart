import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/bookingroomApp/room_model.dart';
import '../../../services/bookingroomApp/firestore_service.dart';
import '../../../widgets/custom_text_field.dart';

class RoomBookingManagementScreen extends StatefulWidget {
  const RoomBookingManagementScreen({super.key});

  @override
  _RoomBookingManagementScreenState createState() =>
      _RoomBookingManagementScreenState();
}

class _RoomBookingManagementScreenState
    extends State<RoomBookingManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isFormVisible = false;
  bool _isLoading = false;
  RoomModel? _selectedRoom;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showForm({RoomModel? room}) {
    setState(() {
      _selectedRoom = room;
      _isFormVisible = true;
      _nameController.text = room?.name ?? '';
      _capacityController.text = room?.capacity.toString() ?? '';
    });
  }

  void _hideForm() {
    setState(() {
      _isFormVisible = false;
      _selectedRoom = null;
      _nameController.clear();
      _capacityController.clear();
    });
  }

  Future<void> _saveRoom() async {
    final roomName = _nameController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim());

    if (roomName.isEmpty || capacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Room name and capacity cannot be blank.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedRoom == null) {
        final newRoom = RoomModel(
          id: '',
          name: roomName,
          capacity: capacity,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createRoom(newRoom);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Room added successfully.'),
          backgroundColor: Colors.green,
        ));
      } else {
        final updatedRoom = _selectedRoom!.copyWith(
          name: roomName,
          capacity: capacity,
        );
        await _firestoreService.updateRoom(updatedRoom);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The room was successfully updated.'),
          backgroundColor: Colors.green,
        ));
      }
      _hideForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDeleteRoom(RoomModel room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text(
          'Anda yakin ingin menghapus ruangan "${room.name}"? Tindakan ini tidak dapat dibatalkan.\n\nCatatan: Ruangan tidak dapat dihapus jika sudah digunakan dalam pemesanan.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteRoom(room.id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Ruangan berhasil dihapus.'),
                  backgroundColor: Colors.green,
                ));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Error: ${e.toString().replaceAll("Exception: ", "")}'),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Ruangan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isFormVisible)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Ruangan Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (_isFormVisible) _buildAddOrEditRoomForm(),
            const SizedBox(height: 24),
            _buildRoomSearchField(),
            const SizedBox(height: 16),
            const Text('Daftar Ruangan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(child: _buildRoomsList()),
          ],
        ),
      ),
    );
  }

  // --- Widget Builder ---

  Widget _buildAddOrEditRoomForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedRoom == null ? 'Tambah Ruangan Baru' : 'Edit Ruangan',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _nameController,
            labelText: 'Nama Ruangan',
            hintText: 'Contoh: Ruang Meeting A',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _capacityController,
            labelText: 'Kapasitas (orang)',
            hintText: 'Contoh: 20',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _hideForm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[500]),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRoom,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_selectedRoom == null ? 'Simpan' : 'Perbarui'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama ruangan...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear())
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildRoomsList() {
    return StreamBuilder<List<RoomModel>>(
      stream: _firestoreService.getRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allRooms = snapshot.data ?? [];
        final filteredRooms = allRooms.where((room) {
          return room.name.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredRooms.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'Ruangan tidak ditemukan.'
                  : 'Belum ada ruangan.\nSilakan tambahkan ruangan baru.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            final room = filteredRooms[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.meeting_room,
                      color: Theme.of(context).primaryColor),
                ),
                title: Text(room.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Kapasitas: ${room.capacity} orang'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showForm(room: room),
                      tooltip: 'Edit Ruangan',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteRoom(room),
                      tooltip: 'Delete Ruangan',
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
}
