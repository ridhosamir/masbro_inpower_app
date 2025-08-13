import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/bookingroomApp/booking_model.dart';
import '../../../models/bookingroomApp/room_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/bookingroomApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class AvailableRoom {
  final RoomModel room;
  final bool isAvailable;

  AvailableRoom({required this.room, required this.isAvailable});
}

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
    'Hybrid Setup',
    'Snack',
    'Minuman',
    'Makan Siang'
  ];
  final Set<String> _selectedNeeds = {};
  bool _showOtherNeedsField = false;
  String? _selectedMainType;
  String? _selectedSubType;

  List<AvailableRoom> _availableRooms = [];
  String? _selectedRoomId;
  RoomModel? _selectedRoom;
  bool _isSearchingRooms = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _participantsController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _findAvailableRooms();
    });
  }

  // Method untuk mendapatkan rentang waktu booking
  DateTime? get _finalStartDate {
    if (_bookingType == BookingType.harian &&
        _selectedDate != null &&
        _startTime != null) {
      return DateTime(_selectedDate!.year, _selectedDate!.month,
          _selectedDate!.day, _startTime!.hour, _startTime!.minute);
    } else if (_bookingType == BookingType.beberapaHari &&
        _startDateMulti != null) {
      return _startDateMulti;
    }
    return null;
  }

  DateTime? get _finalEndDate {
    if (_bookingType == BookingType.harian &&
        _selectedDate != null &&
        _endTime != null) {
      return DateTime(_selectedDate!.year, _selectedDate!.month,
          _selectedDate!.day, _endTime!.hour, _endTime!.minute);
    } else if (_bookingType == BookingType.beberapaHari &&
        _endDateMulti != null) {
      return _endDateMulti;
    }
    return null;
  }

  // Method utama untuk mencari ruangan
  Future<void> _findAvailableRooms() async {
    final participants = int.tryParse(_participantsController.text) ?? 0;
    final startDate = _finalStartDate;
    final endDate = _finalEndDate;

    if (participants > 0 &&
        startDate != null &&
        endDate != null &&
        endDate.isAfter(startDate)) {
      setState(() {
        _isSearchingRooms = true;
        _availableRooms = [];
        _selectedRoomId = null;
        _selectedRoom = null;
      });

      try {
        final results = await _firestoreService.getFilteredAndCheckedRooms(
          participants: participants,
          startDate: startDate,
          endDate: endDate,
        );

        setState(() {
          _availableRooms = results
              .map((res) => AvailableRoom(
                    room: res['room'],
                    isAvailable: res['isAvailable'],
                  ))
              .toList();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to find room: $e'),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isSearchingRooms = false);
      }
    }
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
    _participantsController.removeListener(_onFormChanged);
    _debounce?.cancel();
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
                Text('Please complete the date, start time, and end time.'),
            backgroundColor: Colors.red));
        return;
      }
      if ((_endTime!.hour * 60 + _endTime!.minute) <=
          (_startTime!.hour * 60 + _startTime!.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The end time must be after the start time.'),
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
            content: Text('Please complete the start date and end date.'),
            backgroundColor: Colors.red));
        return;
      }
      if (_endDateMulti!
          .isBefore(_startDateMulti!.add(const Duration(days: 1)))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Minimum booking for several days is 2 days.'),
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

      String finalActivityType;
      if (_selectedMainType == 'Internal') {
        finalActivityType = 'Internal';
      } else {
        finalActivityType = 'Eksternal - $_selectedSubType';
      }

      if (_selectedRoom == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('An error occurred, the room has not been selected.'),
            backgroundColor: Colors.red));
        return;
      }

      final booking = BookingModel(
        id: '',
        employeeId: currentUser!.uid,
        employeeName: currentUser!.name,
        roomId: _selectedRoom!.id,
        roomName: _selectedRoom!.name,
        eventAgenda: _agendaController.text.trim(),
        usageStartDate: finalStartDate!,
        usageEndDate: finalEndDate!,
        needs: finalNeeds.isEmpty ? 'Tidak ada' : finalNeeds,
        activityType: finalActivityType,
        numberOfParticipants: int.parse(_participantsController.text),
        status: 'open',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Booking successfully created.'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Failed to make a booking: ${e.toString().replaceAll("Exception: ", "")}'),
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
        title: const Text('Create a New Booking',
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
              _buildSectionTitle('Event Details'),
              CustomTextField(
                controller: _agendaController,
                labelText: 'Event Agenda',
                hintText: 'Contoh: Rapat bulanan departemen...',
                maxLines: 3,
                validator: (val) =>
                    val!.isEmpty ? 'The agenda cannot be empty' : null,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Event duration'),
              _buildBookingTypeSelector(),
              const SizedBox(height: 16),

              // Tampilkan UI berdasarkan tipe booking
              if (_bookingType == BookingType.harian)
                _buildSingleDayInputs()
              else
                _buildMultiDayInputs(),
              const SizedBox(height: 24),

              _buildSectionTitle('Type of activity'),
              _buildActivityTypeSection(),
              const SizedBox(height: 24),

              _buildSectionTitle('Event needs'),
              _buildNeedsSection(),
              if (_showOtherNeedsField) ...[
                const SizedBox(height: 16),
                CustomTextField(
                    controller: _otherNeedsController,
                    labelText: 'Other Needs',
                    hintText: 'Tuliskan kebutuhan spesifik Anda...'),
              ],
              const SizedBox(height: 24),

              _buildSectionTitle('Participant'),
              CustomTextField(
                controller: _participantsController,
                labelText: 'Number of participants',
                hintText: 'Contoh: 15',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'The number of participants cannot be empty';
                  if (int.tryParse(val) == null)
                    return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Selesct Room'),
              _buildRoomSelectionSection(),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Send Booking Request',
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
            label: Text('One-Day'),
            icon: Icon(Icons.access_time)),
        ButtonSegment(
            value: BookingType.beberapaHari,
            label: Text('Multi-Day'),
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
        _buildDatePicker('Select Event Date', _selectedDate, (date) {
          setState(() {
            _selectedDate = date;
            final now = DateTime.now();
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            if (isToday && _startTime != null) {
              final nowInMinutes = now.hour * 60 + now.minute;
              final startTimeInMinutes =
                  _startTime!.hour * 60 + _startTime!.minute;
              if (startTimeInMinutes < nowInMinutes) {
                _startTime = null;
                _endTime = null;
              }
            }
          });
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(
                'Start Time',
                _startTime,
                (time) {
                  setState(() {
                    _startTime = time;
                    if (_endTime != null &&
                        (_endTime!.hour * 60 + _endTime!.minute) <=
                            (_startTime!.hour * 60 + _startTime!.minute)) {
                      _endTime = null;
                    }
                  });
                },
                selectedDate: _selectedDate,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimePicker(
                'End Time',
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
        _buildDatePicker('Start Date', _startDateMulti, (date) {
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
        _buildDatePicker('End Date', _endDateMulti, (date) {
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
          return 'Please select a date';
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
              _findAvailableRooms();
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
                    ? 'Select date'
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
      {TimeOfDay? startTimeFilter, DateTime? selectedDate}) {
    // Membuat daftar waktu dengan kelipatan 30 menit
    List<TimeOfDay> times = List.generate(48, (index) {
      final hour = index ~/ 2;
      final minute = (index % 2) * 30;
      return TimeOfDay(hour: hour, minute: minute);
    });

    // Filter jam mulai berdasarkan waktu sekarang jika tanggal yang dipilih adalah hari ini
    if (label == 'Start Time' && selectedDate != null) {
      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      if (isToday) {
        final nowInMinutes = now.hour * 60 + now.minute;
        times = times.where((time) {
          final timeInMinutes = time.hour * 60 + time.minute;
          // Tampilkan waktu yang akan datang atau sama dengan waktu sekarang
          return timeInMinutes >= nowInMinutes;
        }).toList();

        // Jika waktu yang sudah terpilih menjadi tidak valid (sudah lewat), reset value
        if (value != null && !times.contains(value)) {
          value = null;
        }
      }
    }

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
      hint: times.isEmpty ? const Text('Start Time') : null,
      items: times.map((time) {
        return DropdownMenuItem<TimeOfDay>(
          value: time,
          child: Text(time.format(context)),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onPicked(newValue);
          _findAvailableRooms();
        }
      },
      validator: (val) => val == null ? 'Required fields' : null,
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
          label: const Text('Other...'),
          selected: _showOtherNeedsField,
          onSelected: (selected) {
            setState(() => _showOtherNeedsField = selected);
          },
        ),
      ],
    );
  }

  Widget _buildActivityTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedMainType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          ),
          hint: const Text('Select the type of activity'),
          items: ['Internal', 'Eksternal'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedMainType = newValue;
              _selectedSubType = null;
            });
          },
          validator: (value) =>
              value == null ? 'Type of activity must be filled in' : null,
        ),

        // Tampilkan dropdown kedua jika 'Eksternal' dipilih
        if (_selectedMainType == 'Eksternal') ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSubType,
            decoration: const InputDecoration(
              labelText: 'External Activity Type',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            ),
            hint: const Text('Select type'),
            items: ['Standard', 'VIP'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSubType = newValue;
              });
            },
            validator: (value) =>
                value == null ? 'External type is required' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildRoomSelectionSection() {
    final participants = int.tryParse(_participantsController.text) ?? 0;
    if (participants == 0 || _finalStartDate == null || _finalEndDate == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Please fill in the number of participants and duration of the event to see available rooms.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    if (_isSearchingRooms) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableRooms.isEmpty && !_isSearchingRooms) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange)),
        child: const Text(
          'There are no rooms available with sufficient capacity.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    // Tampilkan daftar ruangan
    return FormField<String>(
      initialValue: _selectedRoomId,
      validator: (value) {
        if (_selectedRoomId == null) {
          return 'You have to choose one room';
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._availableRooms.map((availableRoom) {
              final room = availableRoom.room;
              final bool isAvailable = availableRoom.isAvailable;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.white,
                child: RadioListTile<String>(
                  value: room.id,
                  groupValue: _selectedRoomId,
                  title: Text(
                    room.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capacity: ${room.capacity} people',
                        style: TextStyle(
                            color: isAvailable
                                ? Colors.black54
                                : Colors.grey[600]),
                      ),
                      if (!isAvailable)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Conflict with other schedules!',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedRoomId = value;
                      _selectedRoom = room;
                      state.didChange(value);
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
              );
            }).toList(),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
