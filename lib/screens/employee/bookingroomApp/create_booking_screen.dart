import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/bookingroomApp/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/bookingroomApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

enum BookingType { harian, beberapaHari }

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  _CreateBookingScreenState createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agendaController = TextEditingController();
  final _participantsController = TextEditingController();
  final _otherNeedsController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  UserModel? currentUser;
  bool _isLoading = false;

  // State untuk tipe booking
  BookingType _bookingType = BookingType.harian;

  // State untuk durasi
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _startDateMulti;
  DateTime? _endDateMulti;

  final List<String> _predefinedNeeds = [
    'Microphone',
    'Hybrid Setup',
    'Snack',
    'Minuman',
    'Makan Siang'
  ];
  final Set<String> _selectedNeeds = {};
  bool _showOtherNeedsField = false;

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
        setState(() => currentUser = userData);
      }
    }
  }

  @override
  void dispose() {
    _agendaController.dispose();
    _participantsController.dispose();
    _otherNeedsController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;

    DateTime? finalStartDate;
    DateTime? finalEndDate;

    if (_bookingType == BookingType.harian) {
      if (_selectedDate == null || _startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Harap lengkapi tanggal, jam mulai, dan jam selesai.'),
            backgroundColor: Colors.red));
        return;
      }
      if ((_endTime!.hour * 60 + _endTime!.minute) <=
          (_startTime!.hour * 60 + _startTime!.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Jam selesai harus setelah jam mulai.'),
            backgroundColor: Colors.red));
        return;
      }
      finalStartDate = DateTime(_selectedDate!.year, _selectedDate!.month,
          _selectedDate!.day, _startTime!.hour, _startTime!.minute);
      finalEndDate = DateTime(_selectedDate!.year, _selectedDate!.month,
          _selectedDate!.day, _endTime!.hour, _endTime!.minute);
    } else {
      if (_startDateMulti == null || _endDateMulti == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Harap lengkapi tanggal mulai dan tanggal selesai.'),
            backgroundColor: Colors.red));
        return;
      }
      if (_endDateMulti!
          .isBefore(_startDateMulti!.add(const Duration(days: 1)))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Booking beberapa hari minimal adalah 2 hari.'),
            backgroundColor: Colors.red));
        return;
      }
      finalStartDate = _startDateMulti;
      finalEndDate = _endDateMulti;
    }

    setState(() => _isLoading = true);

    try {
      String finalNeeds = _selectedNeeds.join(', ');
      if (_showOtherNeedsField && _otherNeedsController.text.isNotEmpty) {
        finalNeeds += (finalNeeds.isNotEmpty ? ', ' : '') +
            _otherNeedsController.text.trim();
      }

      final booking = BookingModel(
        id: '',
        employeeId: currentUser!.uid,
        employeeName: currentUser!.name,
        roomId: '',
        roomName: 'Belum Ditentukan',
        eventAgenda: _agendaController.text.trim(),
        usageStartDate: finalStartDate!,
        usageEndDate: finalEndDate!,
        needs: finalNeeds.isEmpty ? 'Tidak ada' : finalNeeds,
        numberOfParticipants: int.parse(_participantsController.text),
        status: 'open',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Booking berhasil dibuat.'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Gagal membuat booking: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Booking Baru',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Detail Acara'),
              CustomTextField(
                controller: _agendaController,
                labelText: 'Agenda Acara',
                hintText: 'Contoh: Rapat bulanan departemen...',
                maxLines: 3,
                validator: (val) =>
                    val!.isEmpty ? 'Agenda tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Durasi Penggunaan'),
              _buildBookingTypeSelector(),
              const SizedBox(height: 16),

              // Tampilkan UI berdasarkan tipe booking
              if (_bookingType == BookingType.harian)
                _buildSingleDayInputs()
              else
                _buildMultiDayInputs(),

              const SizedBox(height: 24),
              _buildSectionTitle('Kebutuhan'),
              _buildNeedsSection(),
              if (_showOtherNeedsField) ...[
                const SizedBox(height: 16),
                CustomTextField(
                    controller: _otherNeedsController,
                    labelText: 'Kebutuhan Lainnya',
                    hintText: 'Tuliskan kebutuhan spesifik Anda...'),
              ],
              const SizedBox(height: 24),

              _buildSectionTitle('Peserta'),
              CustomTextField(
                controller: _participantsController,
                labelText: 'Jumlah Peserta',
                hintText: 'Contoh: 15',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Jumlah peserta tidak boleh kosong';
                  if (int.tryParse(val) == null)
                    return 'Mohon masukkan angka yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Kirim Permintaan Booking',
                onPressed: _submitBooking,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builder --- //

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildBookingTypeSelector() {
    return SegmentedButton<BookingType>(
      segments: const <ButtonSegment<BookingType>>[
        ButtonSegment(
            value: BookingType.harian,
            label: Text('Harian'),
            icon: Icon(Icons.access_time)),
        ButtonSegment(
            value: BookingType.beberapaHari,
            label: Text('Beberapa Hari'),
            icon: Icon(Icons.date_range)),
      ],
      selected: <BookingType>{_bookingType},
      onSelectionChanged: (Set<BookingType> newSelection) {
        setState(() {
          _bookingType = newSelection.first;
        });
      },
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor:
            Theme.of(context).primaryColor.withOpacity(0.2),
        selectedForegroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSingleDayInputs() {
    return Column(
      children: [
        _buildDatePicker('Pilih Tanggal Acara', _selectedDate, (date) {
          setState(() => _selectedDate = date);
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker('Jam Mulai', _startTime, (time) {
                setState(() {
                  _startTime = time;
                  if (_endTime != null &&
                      (_endTime!.hour * 60 + _endTime!.minute) <=
                          (_startTime!.hour * 60 + _startTime!.minute)) {
                    _endTime = null;
                  }
                });
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimePicker(
                'Jam Selesai',
                _endTime,
                (time) {
                  setState(() => _endTime = time);
                },
                startTimeFilter: _startTime,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildMultiDayInputs() {
    return Column(
      children: [
        _buildDatePicker('Tanggal Mulai', _startDateMulti, (date) {
          setState(() {
            _startDateMulti = date;
            // Reset end date jika start date diubah menjadi setelah end date
            if (_endDateMulti != null &&
                _startDateMulti!.isAfter(_endDateMulti!)) {
              _endDateMulti = null;
            }
          });
        }),
        const SizedBox(height: 16),
        _buildDatePicker('Tanggal Selesai', _endDateMulti, (date) {
          setState(() => _endDateMulti = date);
        }, firstDate: _startDateMulti?.add(const Duration(days: 1))),
      ],
    );
  }

  Widget _buildDatePicker(
      String label, DateTime? value, Function(DateTime) onPicked,
      {DateTime? firstDate}) {
    return FormField<DateTime>(
      initialValue: value,
      validator: (date) {
        if (value == null) {
          return 'Harap pilih tanggal';
        }
        return null;
      },
      builder: (FormFieldState<DateTime> state) {
        return InkWell(
          onTap: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: value ?? firstDate ?? DateTime.now(),
              firstDate: firstDate ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (pickedDate != null) {
              onPicked(pickedDate);
              state.didChange(pickedDate);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              // Menampilkan pesan error dari state FormField
              errorText: state.errorText,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value == null
                    ? 'Pilih tanggal'
                    : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(value)),
                const Icon(Icons.calendar_month),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePicker(
      String label, TimeOfDay? value, Function(TimeOfDay) onPicked,
      {TimeOfDay? startTimeFilter}) {
    // Membuat daftar waktu dengan kelipatan 30 menit
    List<TimeOfDay> times = List.generate(48, (index) {
      final hour = index ~/ 2;
      final minute = (index % 2) * 30;
      return TimeOfDay(hour: hour, minute: minute);
    });

    // Filter daftar waktu jika startTimeFilter diberikan
    if (startTimeFilter != null) {
      final startTimeInMinutes =
          startTimeFilter.hour * 60 + startTimeFilter.minute;
      times = times.where((time) {
        final currentTimeInMinutes = time.hour * 60 + time.minute;
        return currentTimeInMinutes > startTimeInMinutes;
      }).toList();
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
      hint: times.isEmpty ? const Text('Pilih Jam Mulai') : null,
      items: times.map((time) {
        return DropdownMenuItem<TimeOfDay>(
          value: time,
          child: Text(time.format(context)),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onPicked(newValue);
        }
      },
      validator: (val) => val == null ? 'Wajib diisi' : null,
    );
  }

  Widget _buildNeedsSection() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        ..._predefinedNeeds.map((need) => FilterChip(
              label: Text(need),
              selected: _selectedNeeds.contains(need),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedNeeds.add(need);
                  } else {
                    _selectedNeeds.remove(need);
                  }
                });
              },
            )),
        FilterChip(
          label: const Text('Lainnya...'),
          selected: _showOtherNeedsField,
          onSelected: (selected) {
            setState(() => _showOtherNeedsField = selected);
          },
        ),
      ],
    );
  }
}
