import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Mengambil semua notifikasi untuk pengguna saat ini
  Stream<List<QueryDocumentSnapshot>> getNotificationsStream() {
    // Controller untuk mengelola stream secara manual.
    late StreamController<List<QueryDocumentSnapshot>> controller;
    StreamSubscription? firestoreSubscription;
    StreamSubscription? authStateSubscription;

    controller = StreamController<List<QueryDocumentSnapshot>>(
      onListen: () {
        // 1. Saat UI mulai mendengarkan, kita juga mulai mendengarkan perubahan status login.
        authStateSubscription = _auth.authStateChanges().listen((User? user) {
          // Batalkan listener ke Firestore yang lama setiap kali status login berubah.
          firestoreSubscription?.cancel();

          if (user == null) {
            // 2. Jika user logout, kirim list kosong ke UI. Stream tetap terbuka.
            controller.add([]);
          } else {
            // 3. Jika user login, buat query ke Firestore dan mulai mendengarkan data.
            firestoreSubscription = _firestore
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .snapshots()
                .listen((snapshot) {
              // 4. Setiap ada data baru dari Firestore, kirim ke UI.
              controller.add(snapshot.docs);
            }, onError: (error) {
              // Kirim error jika terjadi masalah pada stream Firestore.
              print("Error pada stream notifikasi: $error");
              controller.addError(error);
            });
          }
        });
      },
      onCancel: () {
        // 5. Saat UI berhenti mendengarkan (misal: halaman ditutup),
        // hentikan semua listener untuk mencegah memory leak.
        authStateSubscription?.cancel();
        firestoreSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  // Mengambil jumlah notifikasi yang belum dibaca
  Stream<int> getUnreadCountStream() {
    late StreamController<int> controller;
    StreamSubscription? firestoreSubscription;
    StreamSubscription? authStateSubscription;

    controller = StreamController<int>(
      onListen: () {
        authStateSubscription = _auth.authStateChanges().listen((User? user) {
          firestoreSubscription?.cancel();
          if (user == null) {
            // Jika logout, jumlah notif 0.
            controller.add(0);
          } else {
            // Jika login, buat query untuk menghitung notif yang belum dibaca.
            firestoreSubscription = _firestore
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .where('isRead', isEqualTo: false)
                .snapshots()
                .map((snapshot) => snapshot.docs.length)
                .listen((count) {
              controller.add(count);
            }, onError: (error) {
              print("Error pada stream hitung notifikasi: $error");
              controller.addError(error);
            });
          }
        });
      },
      onCancel: () {
        authStateSubscription?.cancel();
        firestoreSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  // Menandai notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String notificationId) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Menandai notifikasi sebagai belum dibaca
  Future<void> markAsUnread(String notificationId) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': false});
  }

  // Menandai semua notifikasi sebagai sudah dibaca
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;
    final querySnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Menghapus satu notifikasi
  Future<void> deleteNotification(String notificationId) async {
    if (currentUserId == null) return;
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Menghapus beberapa notifikasi
  Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    if (currentUserId == null) return;
    WriteBatch batch = _firestore.batch();
    for (var id in notificationIds) {
      batch.delete(_firestore.collection('notifications').doc(id));
    }
    await batch.commit();
  }
}
