import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/bookingroomApp/booking_model.dart';
import '../../models/bookingroomApp/room_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referensi ke collection
  CollectionReference get _roomsCollection =>
      _firestore.collection('rooms_booking');
  CollectionReference get _bookingsCollection =>
      _firestore.collection('bookings');

  // =======================================================================
  // MANAJEMEN RUANGAN (ROOM MANAGEMENT)
  // =======================================================================

  /// Cek apakah nama ruangan sudah ada (tidak case-sensitive).
  Future<bool> roomNameExists(String name, {String? excludeRoomId}) async {
    try {
      final lowercaseName = name.toLowerCase();
      final snapshot = await _roomsCollection.get();

      final matches = snapshot.docs.where((doc) {
        if (excludeRoomId != null && doc.id == excludeRoomId) {
          return false;
        }
        final data = doc.data() as Map<String, dynamic>;
        final roomName = data['name'] as String? ?? '';
        return roomName.toLowerCase() == lowercaseName;
      }).toList();

      return matches.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking room name: $e');
      rethrow;
    }
  }

  /// Membuat ruangan baru.
  Future<void> createRoom(RoomModel room) async {
    try {
      final nameExists = await roomNameExists(room.name);
      if (nameExists) {
        throw Exception('Ruangan dengan nama "${room.name}" sudah ada.');
      }
      await _roomsCollection.add(room.toMap());
    } catch (e) {
      debugPrint('Error creating room: $e');
      throw e;
    }
  }

  /// Mendapatkan semua data ruangan secara real-time.
  Stream<List<RoomModel>> getRooms() {
    return _roomsCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    });
  }

  /// Memperbarui data ruangan.
  Future<void> updateRoom(RoomModel room) async {
    try {
      final nameExists =
          await roomNameExists(room.name, excludeRoomId: room.id);
      if (nameExists) {
        throw Exception('Ruangan lain dengan nama "${room.name}" sudah ada.');
      }

      final batch = _firestore.batch();
      batch.update(_roomsCollection.doc(room.id), room.toMap());

      final bookingsQuery =
          await _bookingsCollection.where('roomId', isEqualTo: room.id).get();

      for (var bookingDoc in bookingsQuery.docs) {
        batch.update(bookingDoc.reference, {'roomName': room.name});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating room: $e');
      throw e;
    }
  }

  /// Menyimpan penilaian (rating dan komentar) untuk sebuah booking.
  Future<void> submitBookingRating({
    required String bookingId,
    required double rating,
    String? comment,
  }) async {
    try {
      final dataToUpdate = {
        'rating': rating,
        'ratingComment': comment,
        'ratingDate': Timestamp.now(),
      };
      await _bookingsCollection.doc(bookingId).update(dataToUpdate);
    } catch (e) {
      debugPrint('Error submitting booking rating: $e');
      throw e;
    }
  }

  /// Menghapus ruangan.
  Future<void> deleteRoom(String roomId) async {
    try {
      final bookingsQuery = await _bookingsCollection
          .where('roomId', isEqualTo: roomId)
          .limit(1)
          .get();

      if (bookingsQuery.docs.isNotEmpty) {
        throw Exception(
            'Tidak dapat menghapus ruangan yang sudah pernah dibooking.');
      }

      await _roomsCollection.doc(roomId).delete();
    } catch (e) {
      debugPrint('Error deleting room: $e');
      throw e;
    }
  }

  // =======================================================================
  // MANAJEMEN BOOKING (BOOKING MANAGEMENT)
  // =======================================================================

  /// Cek apakah ada jadwal yang bentrok untuk ruangan pada waktu tertentu.
  /// Hanya booking dengan status 'approved' yang dianggap bentrok.
  Future<bool> checkBookingConflict(
      String roomId, DateTime startDate, DateTime endDate,
      {String? bookingIdToExclude}) async {
    try {
      // Query untuk mengambil booking yang berpotensi bentrok
      // Kondisi: (booking.endDate > new.startDate)
      final query = _bookingsCollection
          .where('roomId', isEqualTo: roomId)
          .where('status', isEqualTo: 'approved')
          .where('usageEndDate', isGreaterThan: Timestamp.fromDate(startDate));

      final snapshot = await query.get();

      // Filter di sisi klien untuk kondisi kedua: (booking.startDate < new.endDate)
      final conflictingDocs = snapshot.docs.where((doc) {
        // Jangan cek konflik dengan booking itu sendiri saat diedit
        if (bookingIdToExclude != null && doc.id == bookingIdToExclude) {
          return false;
        }
        final booking = BookingModel.fromFirestore(doc);
        return booking.usageStartDate.isBefore(endDate);
      }).toList();

      return conflictingDocs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking booking conflict: $e');
      rethrow;
    }
  }

  Future<bool> checkBookingConflictForApproval(
      String roomId, DateTime startDate, DateTime endDate,
      {String? bookingIdToExclude}) async {
    try {
      // Query untuk mengambil booking yang berpotensi bentrok
      // Hanya ambil booking dengan status 'approved' (bukan cancelled)
      final query = _bookingsCollection
          .where('roomId', isEqualTo: roomId)
          .where('status', isEqualTo: 'approved')
          .where('usageEndDate', isGreaterThan: Timestamp.fromDate(startDate));

      final snapshot = await query.get();

      // Filter di sisi klien untuk kondisi kedua: (booking.startDate < new.endDate)
      final conflictingDocs = snapshot.docs.where((doc) {
        // Jangan cek konflik dengan booking itu sendiri saat diedit
        if (bookingIdToExclude != null && doc.id == bookingIdToExclude) {
          return false;
        }
        final booking = BookingModel.fromFirestore(doc);
        return booking.usageStartDate.isBefore(endDate);
      }).toList();

      return conflictingDocs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking booking conflict for approval: $e');
      rethrow;
    }
  }

  Future<List<BookingModel>> getConflictingBookings(
      String roomId, DateTime startDate, DateTime endDate,
      {String? bookingIdToExclude}) async {
    try {
      final query = _bookingsCollection
          .where('roomId', isEqualTo: roomId)
          .where('status', isEqualTo: 'approved')
          .where('usageEndDate', isGreaterThan: Timestamp.fromDate(startDate));

      final snapshot = await query.get();

      final conflictingBookings = snapshot.docs
          .where((doc) {
            if (bookingIdToExclude != null && doc.id == bookingIdToExclude) {
              return false;
            }
            final booking = BookingModel.fromFirestore(doc);
            return booking.usageStartDate.isBefore(endDate);
          })
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();

      return conflictingBookings;
    } catch (e) {
      debugPrint('Error getting conflicting bookings: $e');
      rethrow;
    }
  }

  /// Mendapatkan daftar ruangan yang sesuai dengan jumlah peserta dan tanggal
  Future<List<Map<String, dynamic>>> getFilteredAndCheckedRooms({
    required int participants,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final roomQuery = _roomsCollection.where('capacity',
          isGreaterThanOrEqualTo: participants);
      final roomSnapshot = await roomQuery.get();
      final allSuitableRooms =
          roomSnapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();

      allSuitableRooms.sort((a, b) => a.capacity.compareTo(b.capacity));

      List<Map<String, dynamic>> checkedRooms = [];
      for (var room in allSuitableRooms) {
        final isConflict =
            await checkBookingConflict(room.id, startDate, endDate);
        checkedRooms.add({
          'room': room,
          'isAvailable': !isConflict,
        });
      }

      return checkedRooms;
    } catch (e) {
      debugPrint('Error getting and checking rooms: $e');
      rethrow;
    }
  }

  /// Membuat booking baru.
  Future<void> createBooking(BookingModel booking) async {
    try {
      // // Cek konflik hanya jika ruangan sudah ditentukan saat pembuatan booking
      // if (booking.roomId.isNotEmpty && booking.roomName != 'Belum Ditentukan') {
      //   final isConflict = await checkBookingConflict(
      //     booking.roomId,
      //     booking.usageStartDate,
      //     booking.usageEndDate,
      //   );
      //   if (isConflict) {
      //     throw Exception(
      //         'Jadwal bentrok! Ruangan ini sudah dipesan pada rentang waktu yang sama.');
      //   }
      // }
      await _bookingsCollection.add(booking.toMap());
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }

  /// Mendapatkan semua data booking secara real-time.
  Stream<List<BookingModel>> getBookings() {
    return _bookingsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Mendapatkan data booking berdasarkan ID employee.
  Stream<List<BookingModel>> getBookingsByEmployee(String employeeId) {
    return _bookingsCollection
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Memperbarui status booking.
  Future<void> updateBookingStatus(String bookingId, String newStatus,
      {String? reason}) async {
    try {
      Map<String, dynamic> dataToUpdate = {'status': newStatus};

      if (newStatus == 'approved' || newStatus == 'cancelled') {
        dataToUpdate['completionDate'] = Timestamp.now();
        if (reason != null) {
          dataToUpdate['completionReason'] = reason;
        }
      }

      await _bookingsCollection.doc(bookingId).update(dataToUpdate);
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      throw e;
    }
  }

  /// Memperbarui data booking dan menyetujuinya.
  Future<void> updateAndApproveBooking({
    required String bookingId,
    required String roomId,
    required String roomName,
    required DateTime startDate,
    required DateTime endDate,
    required String notes,
  }) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': 'approved',
        'roomId': roomId,
        'roomName': roomName,
        'usageStartDate': Timestamp.fromDate(startDate),
        'usageEndDate': Timestamp.fromDate(endDate),
        'completionDate': Timestamp.now(),
        'completionReason':
            notes, // Menggunakan 'completionReason' sesuai model
      });
    } catch (e) {
      debugPrint('Error updating and approving booking: $e');
      rethrow;
    }
  }

  /// Menghapus booking (misalnya, jika pemesan membatalkan).
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).delete();
    } catch (e) {
      debugPrint('Error deleting booking: $e');
      throw e;
    }
  }
}
