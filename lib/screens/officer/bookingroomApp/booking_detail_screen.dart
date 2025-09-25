import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../models/bookingroomApp/booking_model.dart';
import '../../../models/bookingroomApp/room_model.dart';
import '../../../services/bookingroomApp/firestore_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingType { harian, beberapaHari }

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _rejectionReasonController = TextEditingController();
  bool _isLoading = false;
  late BookingModel _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  void _showRejectDialog() {
    _rejectionReasonController.clear();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Pemesanan'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _rejectionReasonController,
            decoration: const InputDecoration(
              labelText: 'Alasan Penolakan',
              hintText: 'Harap berikan alasan penolakan pemesanan',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Alasan tidak bisa kosong';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _firestoreService.updateBookingStatus(
                  _currentBooking.id,
                  'cancelled',
                  reason: 'Rejected: ${_rejectionReasonController.text.trim()}',
                );

                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Pemesanan berhasil ditolak.'),
                  backgroundColor: Colors.orange,
                ));
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final DateFormat dayFormat = DateFormat('E, d MMM yyyy', 'id_ID');
    final DateFormat timeFormat = DateFormat('HH:mm', 'id_ID');
    if (DateUtils.isSameDay(start, end)) {
      // Jika di hari yang sama: "Sen, 28 Jul 2025, 09:00 - 11:00"
      return '${dayFormat.format(start)}, ${timeFormat.format(start)} - ${timeFormat.format(end)}';
    } else {
      // Jika beda hari: "28 Jul 2025, 09:00 - 29 Jul 2025, 11:00"
      final DateFormat fullFormat = DateFormat('d MMM y', 'id_ID');
      return '${fullFormat.format(start)} - ${fullFormat.format(end)}';
    }
  }

  Future<void> _refreshBookingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(_currentBooking.id)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _currentBooking = BookingModel.fromFirestore(doc);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load latest data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _showManageBookingSheet(BookingModel booking) {
    final formKey = GlobalKey<FormState>();

    // State untuk UI
    RoomModel? selectedRoom;
    final notesController =
        TextEditingController(text: booking.completionReason);

    // State untuk tipe booking & waktu (diadaptasi dari create_booking_screen.dart)
    BookingType bookingType =
        DateUtils.isSameDay(booking.usageStartDate, booking.usageEndDate)
            ? BookingType.harian
            : BookingType.beberapaHari;

    // State untuk durasi Harian
    DateTime? selectedDate = booking.usageStartDate;
    TimeOfDay? startTime = TimeOfDay.fromDateTime(booking.usageStartDate);
    TimeOfDay? endTime = TimeOfDay.fromDateTime(booking.usageEndDate);

    // State untuk durasi Beberapa Hari
    DateTime? startDateMulti = booking.usageStartDate;
    DateTime? endDateMulti =
        DateUtils.isSameDay(booking.usageStartDate, booking.usageEndDate)
            ? null
            : booking.usageEndDate;

    // Variabel untuk menandai jika jadwal sudah lewat
    bool isOutdated = false;

    // --- Logika untuk mereset tanggal yang sudah lewat ---
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (booking.usageStartDate.isBefore(today)) {
      isOutdated = true;
      selectedDate = null;
      startTime = null;
      endTime = null;
      startDateMulti = null;
      endDateMulti = null;
    }

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String? selectedRoomId =
            booking.roomName == 'Not specified' ? null : booking.roomId;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> handleFinalApproval() async {
              if (!formKey.currentState!.validate()) return;

              DateTime finalStartDate;
              DateTime finalEndDate;

              if (bookingType == BookingType.harian) {
                finalStartDate = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    startTime!.hour,
                    startTime!.minute);
                finalEndDate = DateTime(selectedDate!.year, selectedDate!.month,
                    selectedDate!.day, endTime!.hour, endTime!.minute);
              } else {
                finalStartDate = startDateMulti!;
                finalEndDate = endDateMulti!;
              }

              // CEK KONFLIK JADWAL TERLEBIH DAHULU
              try {
                showDialog(
                    context: context,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                    barrierDismissible: false);

                // Cek apakah ada konflik dengan booking yang sudah approved
                final hasConflict =
                    await _firestoreService.checkBookingConflictForApproval(
                  selectedRoomId!,
                  finalStartDate,
                  finalEndDate,
                  bookingIdToExclude:
                      booking.id, // Exclude booking yang sedang diproses
                );

                // Tutup loading dialog
                if (mounted) Navigator.pop(context);

                if (hasConflict) {
                  // Dapatkan detail booking yang bentrok untuk info lebih detail
                  final conflictingBookings =
                      await _firestoreService.getConflictingBookings(
                    selectedRoomId!,
                    finalStartDate,
                    finalEndDate,
                    bookingIdToExclude: booking.id,
                  );

                  // Tampilkan popup error dengan info detail
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 24),
                            SizedBox(width: 8),
                            Text('Konflik Jadwal!'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tidak dapat menyetujui pemesanan karena jadwal bentrok dengan agenda lain yang disetujui:',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: conflictingBookings
                                      .map((conflictBooking) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '• ${conflictBooking.eventAgenda}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                height: 28,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            BookingDetailScreen(
                                                                booking:
                                                                    conflictBooking),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    side: BorderSide.none,
                                                  ),
                                                  child: const Text(
                                                      'Lihat Detail',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ),
                                              )
                                            ],
                                          ),
                                          Text(
                                            '  ${_formatDateRange(conflictBooking.usageStartDate, conflictBooking.usageEndDate)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                          Text(
                                            '  Pemesan: ${conflictBooking.employeeName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Silakan pilih jadwal atau ruangan lain.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.red, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                // Jika tidak ada konflik, lanjutkan dengan konfirmasi approval
                final bool? confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi Persetujuan'),
                    content: const Text(
                        'Apakah Anda yakin ingin menerima pemesanan ini?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Batal')),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Ya, Setujui',
                              style: TextStyle(color: Colors.green))),
                    ],
                  ),
                );

                if (confirmed != true) return;
                if (!mounted) return;

                // Tampilkan loading lagi untuk proses approval
                showDialog(
                    context: context,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                    barrierDismissible: false);

                // Proses approval
                await _firestoreService.updateAndApproveBooking(
                  bookingId: booking.id,
                  roomId: selectedRoomId!,
                  roomName: selectedRoom!.name,
                  startDate: finalStartDate,
                  endDate: finalEndDate,
                  notes: notesController.text.trim(),
                );

                if (!mounted) return;

                Navigator.pop(context);
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Pemesanan berhasil disetujui.'),
                  backgroundColor: Colors.green,
                ));
              } catch (e) {
                // Tutup loading jika ada error
                if (mounted) Navigator.pop(context);

                // Tampilkan error
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Error'),
                      content: Text('There is an error: ${e.toString()}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            }

            Widget _buildSingleDayInputs(
              BuildContext context,
              StateSetter setState,
              DateTime? currentDate,
              TimeOfDay? currentTime,
              TimeOfDay? endTime, {
              required Function(DateTime) onDateChanged,
              required Function(TimeOfDay?) onStartTimeChanged,
              required Function(TimeOfDay?) onEndTimeChanged,
            }) {
              return Column(
                children: [
                  FormField<DateTime>(
                    initialValue: currentDate,
                    validator: (value) {
                      if (value == null) {
                        return 'Tanggal acara diperlukan';
                      }
                      return null;
                    },
                    builder: (FormFieldState<DateTime> state) {
                      return _buildDatePicker(
                          context, 'Pilih Tanggal Acara', state.value, (date) {
                        setState(() {
                          onDateChanged(date);
                          state.didChange(date);
                          final now = DateTime.now();
                          final isToday = date.year == now.year &&
                              date.month == now.month &&
                              date.day == now.day;

                          // Logika tambahan untuk reset jam mulai jika sudah lewat
                          if (isToday && currentTime != null) {
                            final nowInMinutes = now.hour * 60 + now.minute;
                            final startTimeInMinutes =
                                currentTime.hour * 60 + currentTime.minute;
                            if (startTimeInMinutes < nowInMinutes) {
                              // Jika jam mulai yang dipilih sudah lewat, reset keduanya
                              onStartTimeChanged(null);
                              onEndTimeChanged(null);
                            }
                          }
                          // Logika tambahan untuk reset jam selesai jika sudah lewat
                          if (isToday && endTime != null) {
                            final nowInMinutes = now.hour * 60 + now.minute;
                            final endTimeInMinutes =
                                endTime.hour * 60 + endTime.minute;
                            if (endTimeInMinutes < nowInMinutes) {
                              onEndTimeChanged(null);
                            }
                          }
                        });
                      }, errorText: state.errorText);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTimePicker(
                              context, 'Jam mulai', currentTime,
                              (newStartTime) {
                        setState(() {
                          onStartTimeChanged(newStartTime);
                          // Reset end time if it's before new start time
                          if (newStartTime != null) {
                            // Jika jam selesai lebih awal dari jam mulai baru, kosongkan jam selesai
                            if (endTime != null &&
                                (endTime.hour * 60 + endTime.minute) <=
                                    (newStartTime.hour * 60 +
                                        newStartTime.minute)) {
                              onEndTimeChanged(null);
                            }
                          } else {
                            // Jika jam mulai dikosongkan, jam selesai juga harus kosong
                            onEndTimeChanged(null);
                          }
                        });
                      }, selectedDate: currentDate)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTimePicker(
                              context, 'Jam selesai', endTime, (newEndTime) {
                        setState(() => onEndTimeChanged(newEndTime));
                      }, startTimeFilter: currentTime)),
                    ],
                  )
                ],
              );
            }

            Widget _buildMultiDayInputs(
              BuildContext context,
              StateSetter setState,
              DateTime? currentStartDate,
              DateTime? currentEndDate, {
              required Function(DateTime) onStartDateChanged,
              required Function(DateTime?) onEndDateChanged,
            }) {
              return Column(
                children: [
                  FormField<DateTime>(
                    initialValue: currentStartDate,
                    validator: (value) {
                      if (value == null) {
                        return 'Tanggal mulai diperlukan';
                      }
                      if (currentEndDate != null &&
                          (value.isAfter(currentEndDate) ||
                              DateUtils.isSameDay(value, currentEndDate))) {
                        return 'Tanggal mulai harus sebelum tanggal akhir acara!';
                      }
                      return null;
                    },
                    builder: (FormFieldState<DateTime> state) {
                      return _buildDatePicker(
                          context, 'Tanggal mulai', state.value, (date) {
                        setState(() {
                          onStartDateChanged(date);
                          state.didChange(date);
                          if (currentEndDate != null &&
                              !currentEndDate.isAfter(date)) {
                            onEndDateChanged(date.add(const Duration(days: 1)));
                          }
                        });
                      }, errorText: state.errorText);
                    },
                  ),
                  const SizedBox(height: 16),
                  FormField<DateTime>(
                    key: ValueKey(currentEndDate),
                    initialValue: currentEndDate,
                    validator: (value) {
                      if (value == null) {
                        return 'Tanggal akhir diperlukan';
                      }
                      return null;
                    },
                    builder: (FormFieldState<DateTime> state) {
                      return _buildDatePicker(
                          context, 'Tanggal selesai', state.value, (date) {
                        setState(() {
                          onEndDateChanged(date);
                          state.didChange(date);
                        });
                      },
                          firstDate:
                              currentStartDate?.add(const Duration(days: 1)) ??
                                  DateTime.now().add(const Duration(days: 1)),
                          errorText: state.errorText);
                    },
                  ),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kelola Pemesanan Ruangan',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          _buildStatusChip('open'),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildDetailItem(Icons.event_note,
                                        'Agenda Acara', booking.eventAgenda),
                                    _buildDetailItem(
                                        Icons.local_activity_outlined,
                                        'Jenis Kegiatan',
                                        booking.activityType),
                                    _buildDetailItem(Icons.person_outline,
                                        'Pemesan', booking.employeeName),
                                    _buildDetailItem(Icons.add_box_outlined,
                                        'Kebutuhan', booking.needs),
                                    _buildDetailItem(
                                        Icons.groups_3_outlined,
                                        'Jumlah Peserta',
                                        booking.numberOfParticipants
                                            .toString()),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Ruangan & Jadwal'),
                              const SizedBox(height: 12),
                              StreamBuilder<List<RoomModel>>(
                                stream: _firestoreService.getRooms(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Text(
                                        'Error: No rooms available.');
                                  }
                                  final rooms = snapshot.data!;
                                  if (selectedRoomId != null &&
                                      selectedRoom == null) {
                                    try {
                                      selectedRoom = rooms.firstWhere(
                                          (r) => r.id == selectedRoomId);
                                    } catch (_) {
                                      selectedRoomId = null;
                                      selectedRoom = null;
                                    }
                                  }

                                  return DropdownButtonFormField<String>(
                                    value: selectedRoomId,
                                    menuMaxHeight: 300,
                                    decoration: const InputDecoration(
                                      labelText: 'Pilih Ruangan',
                                      prefixIcon:
                                          Icon(Icons.meeting_room_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    isExpanded: true,
                                    itemHeight: null,
                                    selectedItemBuilder:
                                        (BuildContext context) {
                                      return rooms
                                          .map<Widget>((RoomModel room) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            room.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList();
                                    },
                                    items: rooms.map((room) {
                                      return DropdownMenuItem<String>(
                                        value: room.id,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    room.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Kapasitas: ${room.capacity} orang',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: Color(0xFFEEEEEE),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedRoomId = value;
                                        selectedRoom = rooms
                                            .firstWhere((r) => r.id == value);
                                      });
                                    },
                                    validator: (value) => value == null
                                        ? 'Ruangan harus dipilih'
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Peringatan jika jadwal sudah lewat
                              if (isOutdated) ...[
                                const SizedBox(height: 12),
                                _buildWarningBox(
                                    'Jadwal sudah lewat, silakan pilih lagi.'),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 16),
                              SegmentedButton<BookingType>(
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
                                selected: <BookingType>{bookingType},
                                onSelectionChanged:
                                    (Set<BookingType> newSelection) {
                                  setModalState(() {
                                    final newType = newSelection.first;
                                    if (newType == bookingType) return;

                                    final oldType = bookingType;
                                    bookingType = newType;

                                    // Logic perpindahan dari Beberapa Hari ke Harian
                                    if (oldType == BookingType.beberapaHari &&
                                        newType == BookingType.harian &&
                                        startDateMulti != null) {
                                      selectedDate = startDateMulti;

                                      // Cek apakah tanggal sudah kadaluarsa
                                      final now = DateTime.now();
                                      final today = DateTime(
                                          now.year, now.month, now.day);

                                      if (selectedDate!.isBefore(today)) {
                                        // Jika sudah kadaluarsa, reset semua
                                        selectedDate = null;
                                        startTime = null;
                                        endTime = null;
                                      } else {
                                        // Cek apakah booking asli adalah harian atau multi-day
                                        if (DateUtils.isSameDay(
                                            booking.usageStartDate,
                                            booking.usageEndDate)) {
                                          // Jika booking asli adalah harian, kembalikan jam dari booking asli
                                          startTime = TimeOfDay.fromDateTime(
                                              booking.usageStartDate);
                                          endTime = TimeOfDay.fromDateTime(
                                              booking.usageEndDate);
                                        } else {
                                          // Jika booking asli adalah multi-day, kosongkan jam
                                          startTime = null;
                                          endTime = null;
                                        }
                                      }
                                    }
                                    // Logic perpindahan dari Harian ke Beberapa Hari
                                    else if (oldType == BookingType.harian &&
                                        newType == BookingType.beberapaHari &&
                                        selectedDate != null) {
                                      startDateMulti = selectedDate;

                                      // Kembalikan endDateMulti jika sebelumnya ada data _buildMultiDayInputs
                                      if (DateUtils.isSameDay(
                                          booking.usageStartDate,
                                          booking.usageEndDate)) {
                                        // Jika booking asli adalah harian, kosongkan endDateMulti
                                        endDateMulti = null;
                                      } else {
                                        // Jika booking asli adalah multi-day, kembalikan data endDateMulti
                                        endDateMulti = booking.usageEndDate;
                                      }

                                      // Cek apakah tanggal sudah kadaluarsa
                                      final now = DateTime.now();
                                      final today = DateTime(
                                          now.year, now.month, now.day);

                                      if (startDateMulti!.isBefore(today)) {
                                        // Jika sudah kadaluarsa, reset semua
                                        startDateMulti = null;
                                        endDateMulti = null;
                                      }
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              if (bookingType == BookingType.harian)
                                _buildSingleDayInputs(
                                  context,
                                  setModalState,
                                  selectedDate,
                                  startTime,
                                  endTime,
                                  onDateChanged: (d) => selectedDate = d,
                                  onStartTimeChanged: (t) => startTime = t,
                                  onEndTimeChanged: (t) => endTime = t,
                                )
                              else
                                _buildMultiDayInputs(
                                  context,
                                  setModalState,
                                  startDateMulti,
                                  endDateMulti,
                                  onStartDateChanged: (d) {
                                    startDateMulti = d;
                                    if (endDateMulti != null &&
                                        (d.isAfter(endDateMulti!) ||
                                            DateUtils.isSameDay(
                                                d, endDateMulti!))) {
                                      endDateMulti = null;
                                    }
                                  },
                                  onEndDateChanged: (d) => endDateMulti = d,
                                ),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Catatan Tambahan (Opsional)'),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Catatan Tambahan',
                                  hintText:
                                      'Tambahkan catatan untuk pemesan ruangan...',
                                  prefixIcon: Icon(Icons.note_alt_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Batal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: handleFinalApproval,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Setujui'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  String _formatBookingDuration(DateTime start, DateTime end) {
    final isSingleDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (isSingleDay) {
      final date = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(start);
      final startTime = DateFormat('HH:mm').format(start);
      final endTime = DateFormat('HH:mm').format(end);
      return '$date, $startTime - $endTime';
    } else {
      final startDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(start);
      final endDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(end);
      return '$startDate s/d $endDate';
    }
  }

  Widget _buildRatingDisplaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Penilaian & Ulasan'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Menampilkan bintang rating (read-only)
                  RatingBar.builder(
                    initialRating: _currentBooking.rating ?? 0.0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    itemCount: 5,
                    itemSize: 22.0,
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {},
                    ignoreGestures: true,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_currentBooking.rating?.toStringAsFixed(1) ?? '0.0'})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
              // Menampilkan ulasan/komentar jika ada
              if (_currentBooking.ratingComment != null &&
                  _currentBooking.ratingComment!.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Tinjauan:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '"${_currentBooking.ratingComment!}"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pemesanan Ruangan'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBox(),
            const SizedBox(height: 24),
            _buildSectionTitle('Informasi Pemesanan'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.meeting_room_outlined, 'Ruangan',
                  _currentBooking.roomName),
              _buildInfoRow(Icons.local_activity_outlined, 'Jenis Kegiatan',
                  _currentBooking.activityType),
              _buildInfoRow(Icons.person_outline, 'Pemesan',
                  _currentBooking.employeeName),
              _buildInfoRowWithWidgetValue(
                Icons.priority_high_outlined,
                'Urgensi',
                _buildUrgencyChip(_currentBooking.requestType),
              ),
              _buildInfoRow(
                  Icons.calendar_today,
                  'Jadwal Acara',
                  _formatBookingDuration(_currentBooking.usageStartDate,
                      _currentBooking.usageEndDate)),
              _buildInfoRow(Icons.group_outlined, 'Jumlah Peserta',
                  '${_currentBooking.numberOfParticipants} orang'),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('Agenda Acara'),
            const SizedBox(height: 12),
            _buildDescriptionBox(_currentBooking.eventAgenda),
            const SizedBox(height: 24),
            _buildSectionTitle('Kebutuhan Tambahan'),
            const SizedBox(height: 12),
            _buildDescriptionBox(_currentBooking.needs),
            if ((_currentBooking.status == 'approved' ||
                    _currentBooking.status == 'cancelled') &&
                _currentBooking.completionReason != null &&
                _currentBooking.completionReason!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(
                _currentBooking.status == 'approved'
                    ? 'Catatan Persetujuan'
                    : 'Catatan Penolakan',
              ),
              const SizedBox(height: 12),
              _buildReasonBox(),
            ],
            if (_currentBooking.rating != null) ...[
              const SizedBox(height: 24),
              _buildRatingDisplaySection(),
            ],
            const SizedBox(height: 24),
            if (_currentBooking.status == 'open') ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Tolak Pemesanan',
                      onPressed: _showRejectDialog,
                      isLoading: _isLoading,
                      backgroundColor: Colors.red[700],
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Kelola dan Setujui',
                      onPressed: () async {
                        // Tunggu hasil dari bottom sheet
                        final result =
                            await _showManageBookingSheet(_currentBooking);

                        // Jika ada hasil true (tanda sukses), refresh data
                        if (result == true && mounted) {
                          _refreshBookingData();
                        }
                      },
                      isLoading: _isLoading,
                      backgroundColor: Colors.blue[700],
                      icon: Icons.edit_calendar_outlined,
                    ),
                  ),
                ],
              ),
            ],
            if (_currentBooking.status == 'approved' &&
                DateTime.now().isBefore(_currentBooking.usageEndDate)) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Perbari Jadwal',
                      onPressed: () async {
                        final result =
                            await _showManageBookingSheet(_currentBooking);

                        if (result == true && mounted) {
                          _refreshBookingData();
                        }
                      },
                      isLoading: _isLoading,
                      backgroundColor: Colors.orange[700],
                      icon: Icons.edit_calendar_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Tolak Pemesanan',
                      onPressed: _showRejectDialog,
                      isLoading: _isLoading,
                      backgroundColor: Colors.red[700],
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Widget Builder Helpers ---

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final (color, text, icon) = switch (status) {
      'open' => (Colors.orange, 'OPEN', Icons.pending),
      'approved' => (Colors.green, 'APPROVED', Icons.check_circle),
      'cancelled' => (Colors.red, 'CANCELLED', Icons.cancel),
      _ => (Colors.grey, status.toUpperCase(), Icons.help),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime? value,
      Function(DateTime) onPicked,
      {DateTime? firstDate, String? errorText}) {
    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: value ?? firstDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (pickedDate != null) onPicked(pickedDate);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          errorText: errorText,
          helperText: errorText == null ? ' ' : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value == null
                ? 'Pilih Tanggal'
                : DateFormat('EEEE, d MMM yyyy', 'id_ID').format(value)),
            const Icon(Icons.calendar_month),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, TimeOfDay? value,
      Function(TimeOfDay?) onPicked,
      {TimeOfDay? startTimeFilter, DateTime? selectedDate}) {
    List<TimeOfDay> times = List.generate(48, (index) {
      final hour = index ~/ 2;
      final minute = (index % 2) * 30;
      return TimeOfDay(hour: hour, minute: minute);
    });

    if (label == 'Jam Mulai' && selectedDate != null) {
      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      if (isToday) {
        final nowInMinutes = now.hour * 60 + now.minute;
        times = times.where((time) {
          final timeInMinutes = time.hour * 60 + time.minute;
          return timeInMinutes >= nowInMinutes;
        }).toList();

        if (value != null && !times.contains(value)) {
          value = null;
        }
      }
    }

    if (startTimeFilter != null) {
      final startTimeInMinutes =
          startTimeFilter.hour * 60 + startTimeFilter.minute;
      times = times.where((time) {
        final currentTimeInMinutes = time.hour * 60 + time.minute;
        return currentTimeInMinutes > startTimeInMinutes;
      }).toList();

      if (value != null && !times.contains(value)) {
        value = null;
      }
    }

    return DropdownButtonFormField<TimeOfDay>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        helperText: ' ',
      ),
      menuMaxHeight: 200,
      hint: times.isEmpty ? const Text('Jam Mulai') : null,
      items: times.map((time) {
        return DropdownMenuItem<TimeOfDay>(
          value: time,
          child: Text(time.format(context)),
        );
      }).toList(),
      onChanged: (newValue) {
        onPicked(newValue);
      },
      validator: (val) {
        if (val == null) {
          return 'Wajib diisi';
        }

        if (selectedDate != null) {
          final now = DateTime.now();
          final isToday = selectedDate.year == now.year &&
              selectedDate.month == now.month &&
              selectedDate.day == now.day;

          if (isToday) {
            final selectedTimeInMinutes = val.hour * 60 + val.minute;
            final nowInMinutes = now.hour * 60 + now.minute;

            if (selectedTimeInMinutes < nowInMinutes) {
              return 'Waktu sudah lewat';
            }
          }
        }
        return null;
      },
    );
  }

  Widget _buildStatusBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _currentBooking.getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _currentBooking.getStatusColor()),
      ),
      child: Column(
        children: [
          Icon(
            _currentBooking.getStatusIcon(),
            color: _currentBooking.getStatusColor(),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Status: ${_currentBooking.getStatusDisplayName()}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _currentBooking.getStatusColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Created at ${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(_currentBooking.createdAt)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (_currentBooking.status == 'approved' &&
              _currentBooking.completionDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Approved on ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(_currentBooking.completionDate!)}',
              style: TextStyle(
                color: _currentBooking.getStatusColor().withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_currentBooking.status == 'cancelled' &&
              _currentBooking.completionDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Rejected on ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(_currentBooking.completionDate!)}',
              style: TextStyle(
                color: _currentBooking.getStatusColor().withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildReasonBox() {
    bool isApproved = _currentBooking.status == 'approved';

    Color backgroundColor = isApproved ? Colors.green[50]! : Colors.red[50]!;
    Color borderColor = isApproved ? Colors.green[200]! : Colors.red[200]!;
    Color textColor = isApproved ? Colors.green[800]! : Colors.red[800]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        _currentBooking.completionReason!,
        style: TextStyle(fontSize: 15, height: 1.5, color: textColor),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Widget baru untuk menampilkan pesan peringatan
  Widget _buildWarningBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Colors.red[700],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membuat baris info dengan value berupa widget
  Widget _buildInfoRowWithWidgetValue(
      IconData icon, String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: valueWidget,
          ),
        ],
      ),
    );
  }

// Helper widget untuk menampilkan chip tingkat urgensi
  Widget _buildUrgencyChip(String requestType) {
    Color color;
    String text;
    IconData icon;

    switch (requestType) {
      case 'Rendah':
        color = Colors.green;
        text = 'Rendah';
        icon = Icons.keyboard_arrow_down;
        break;
      case 'Tinggi':
        color = Colors.red;
        text = 'Tinggi';
        icon = Icons.keyboard_arrow_up;
        break;
      case 'Sedang':
      default:
        color = Colors.orange;
        text = 'Sedang';
        icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
