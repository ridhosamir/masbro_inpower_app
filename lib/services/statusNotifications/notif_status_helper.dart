import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:masbro_inpower_app/models/bookingroomApp/booking_model.dart';
import 'package:masbro_inpower_app/models/maintenanceApp/report_model.dart';
import 'package:masbro_inpower_app/models/operasionalApp/ride_request_model.dart';
import 'package:masbro_inpower_app/models/resourceApp/request_model.dart';
import 'package:masbro_inpower_app/screens/homeDashboard/dashboard_technician.dart';
import 'package:masbro_inpower_app/screens/officer/bookingroomApp/booking_detail_screen.dart'
    as officer_booking_detail;
import 'package:masbro_inpower_app/screens/employee/bookingroomApp/booking_detail_screen.dart'
    as user_booking_detail;
import 'package:masbro_inpower_app/screens/officer/maintenanceApp/report_detail_screen.dart'
    as officer_report_detail;
import 'package:masbro_inpower_app/screens/employee/maintenanceApp/report_detail_screen.dart'
    as user_report_detail;
import 'package:masbro_inpower_app/screens/officer/operasionalApp/ride_request_detail_screen.dart'
    as officer_ride_detail;
import 'package:masbro_inpower_app/screens/employee/operasionalApp/ride_request_detail_screen.dart'
    as user_ride_detail;
import 'package:masbro_inpower_app/screens/officer/resourceApp/request_detail_screen.dart'
    as officer_resource_detail;
import 'package:masbro_inpower_app/screens/employee/resourceApp/request_detail_screen.dart'
    as user_resource_detail;
import 'package:masbro_inpower_app/services/navigation_service.dart';
import 'package:masbro_inpower_app/services/user_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NavigationService _navigationService;
  final UserService _userService;

  NotificationService(this._navigationService, this._userService);

  Future<void> initNotifications(String userId) async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true, // Tampilkan alert/popup notifikasi
        announcement: false, // Tidak untuk pengumuman khusus
        badge: true, // Tampilkan badge (angka) di icon app
        carPlay: false, // Tidak untuk CarPlay
        criticalAlert: false, // Tidak untuk alert kritis
        provisional: false, // Tidak untuk notifikasi sementara
        sound: true, // Aktifkan suara notifikasi
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('[FCM] User menolak permission notifikasi');
        return; // Hentikan proses jika ditolak
      }

      String? fcmToken;
      if (kIsWeb) {
        // Untuk platform WEB, VAPID key WAJIB disertakan.
        print('[FCM] Getting token for Web...');
        fcmToken = await _firebaseMessaging.getToken(
          // GANTI string di bawah ini dengan VAPID key dari Firebase Console Anda
          vapidKey:
              "BF5PvjovJx9VqsL9a0UEX9CDOEzMKY_tO7tODrlxgVIVZNdZDN28h5ifehtDp2I75hkBki2P8r6HTe6Ym_FRSgw",
        );
      } else {
        // Untuk platform Android/iOS
        print('[FCM] Getting token for Mobile...');
        fcmToken = await _firebaseMessaging.getToken();
      }

      if (fcmToken != null) {
        print('[FCM] Token didapatkan: $fcmToken');
        await _saveTokenToDatabase(
            userId, fcmToken); // await untuk memastikan tersimpan

        // Listen untuk token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _saveTokenToDatabase(userId, newToken);
        });
      } else {
        print('[FCM] Gagal mendapatkan token. Periksa VAPID Key untuk web.');
      }

      await _createNotificationChannel();
      await _initLocalNotifications();
      _setupFirebaseListeners();
    } catch (e) {
      print('[FCM] Error saat inisialisasi: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('logo_masbro');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      // --- PENTING: Handler saat notifikasi lokal di-tap ---
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final data = jsonDecode(response.payload!);
          handleMessageNavigation(data);
        }
      },
    );
  }

  void _setupFirebaseListeners() {
    // Listener untuk notifikasi saat aplikasi di FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FOREGROUND] Pesan diterima: ${message.notification?.title}');
      if (message.notification != null) {
        // Tampilkan notifikasi lokal saat aplikasi terbuka
        showFlutterNotification(message);
      }
    });

    // Listener untuk saat notifikasi di-klik (aplikasi di background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('[FCM] App dibuka dari notifikasi background');
      handleMessageNavigation(message.data);
    });
  }

  // Fungsi untuk menampilkan notifikasi lokal
  void showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'masbro_channel', // ID Channel
            'MasBro Notifications', // Nama Channel
            channelDescription: 'Channel untuk notifikasi penting.',
            icon: 'logo_masbro', // Ikon notifikasi
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data), // Sertakan data untuk navigasi
      );
    }
  }

  // 3. Untuk notifikasi saat aplikasi TERMINATED
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleMessageNavigation(initialMessage.data);
    }
  }

  Future<void> _saveTokenToDatabase(String userId, String token) async {
    try {
      print('[FCM] Mencoba menyimpan token untuk user: $userId');

      // Gunakan set dengan merge untuk memastikan dokumen dibuat jika belum ada
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[FCM] Token berhasil disimpan ke database');

      // Verifikasi token tersimpan
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['fcmToken'] == token) {
        print('[FCM] Verifikasi: Token berhasil tersimpan');
      } else {
        print('[FCM] Verifikasi: Token gagal tersimpan');
      }
    } catch (e) {
      print('[FCM] Error saving FCM Token: $e');

      // Coba alternatif jika gagal
      try {
        await _firestore.collection('user_tokens').doc(userId).set({
          'fcmToken': token,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('[FCM] Token disimpan di koleksi alternatif');
      } catch (e2) {
        print('[FCM] Error pada koleksi alternatif: $e2');
      }
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'masbroapp_channel',
      'MasBro Notification',
      description:
          'Channel ini digunakan untuk notifikasi penting terkait status permintaan.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: 'logo_masbro',
    );
    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await _localNotifications.show(id, title, body, platformDetails,
        payload: payload);
  }

  // --- FUNGSI UTAMA UNTUK NAVIGASI ---
  Future<void> handleMessageNavigation(Map<String, dynamic> data) async {
    final String? collection = data['collection'];
    final String? docId = data['docId'];

    if (collection == null || docId == null) return;

    // Tunggu sebentar untuk memastikan UI siap
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Mengambil data user yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final currentUser = await _userService.getUserData(user.uid);
      if (currentUser == null) return;

      final docSnapshot =
          await _firestore.collection(collection).doc(docId).get();
      if (!docSnapshot.exists) return;

      final navigator = _navigationService.navigatorKey.currentState;
      if (navigator == null) return;

      if (currentUser.role == 'technician') {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeDashboardTechnician(initialTabIndex: 0),
          ),
          (route) => false,
        );
        return; // Selesai.
      }

      Widget? detailScreen;

      // Logika navigasi berdasarkan role dan koleksi
      // memiliki factory constructor seperti ini:
      // factory ReportModel.fromFirestore(DocumentSnapshot doc) { ... }
      switch (collection) {
        case 'reports':
          final report = ReportModel.fromFirestore(docSnapshot);
          detailScreen = currentUser.role == 'officer'
              ? officer_report_detail.ReportDetailScreen(report: report)
              : user_report_detail.ReportDetailScreen(report: report);
          break;
        case 'requests_resource':
          final request = RequestModel.fromFirestore(docSnapshot);
          detailScreen = currentUser.role == 'officer'
              ? officer_resource_detail.RequestDetailScreenResource(
                  request: request)
              : user_resource_detail.RequestDetailScreen(request: request);
          break;
        case 'ride_requests':
          final rideRequest = RideRequestModel.fromFirestore(docSnapshot);
          detailScreen = currentUser.role == 'officer'
              ? officer_ride_detail.RideRequestDetailScreen(
                  request: rideRequest)
              : user_ride_detail.RideRequestDetailScreen(request: rideRequest);
          break;
        case 'bookings':
          final booking = BookingModel.fromFirestore(docSnapshot);
          detailScreen = currentUser.role == 'officer'
              ? officer_booking_detail.BookingDetailScreen(booking: booking)
              : user_booking_detail.BookingDetailScreen(booking: booking);
          break;
        default:
          print('[NAVIGATION] Collection tidak dikenal: $collection');
      }

      if (detailScreen != null) {
        navigator.push(MaterialPageRoute(builder: (_) => detailScreen!));
      }
    } catch (e) {
      print("Error handling notification navigation: $e");
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'masbroapp_channel',
      'MasBro Notification',
      description:
          'Channel ini digunakan untuk notifikasi penting terkait status permintaan.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> removeToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      print('[FCM] Token berhasil dihapus');
    } catch (e) {
      print('[FCM] Error removing token: $e');
    }
  }
}
