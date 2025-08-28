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
import 'package:masbro_inpower_app/screens/homeDashboard/dashboard_user.dart';
import 'package:masbro_inpower_app/screens/homeDashboard/dashboard_officer.dart';
import 'package:masbro_inpower_app/screens/auth/login_screen.dart';
import 'package:masbro_inpower_app/services/navigation_service.dart';
import 'package:masbro_inpower_app/services/user_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rxdart/rxdart.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NavigationService _navigationService;
  final UserService _userService;
  // Stream ini akan menerima data notifikasi DARI SEMUA SUMBER (terminated, background, foreground tap)
  final BehaviorSubject<Map<String, dynamic>> _notificationDataForNavigation =
      BehaviorSubject<Map<String, dynamic>>();

  final _notificationStreamController = BehaviorSubject<Map<String, dynamic>>();

  Stream<Map<String, dynamic>> get onNotificationData =>
      _notificationStreamController.stream;

  NotificationService(this._navigationService, this._userService) {
    _notificationDataForNavigation.stream
        .distinct()
        .listen(_handleNavigationLogic);
  }

  void dispose() {
    _notificationStreamController.close();
    _notificationDataForNavigation.close();
  }

  // Fungsi ini akan menjadi satu-satunya cara bagi UI lain (seperti NotificationListScreen)
  // untuk memicu navigasi dari notifikasi.
  void triggerNavigationFromNotification(Map<String, dynamic> data) {
    print('[FCM] Navigasi dipicu secara manual dari UI. Meneruskan data...');
    _notificationDataForNavigation.add(data);
  }

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

      _setupInteractedMessageListener();

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
        await _saveTokenToDatabase(userId, fcmToken);
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _saveTokenToDatabase(userId, newToken);
        });
      }

      // Setup listener HANYA untuk MENAMPILKAN notifikasi saat app di foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('[FOREGROUND] Pesan diterima: ${message.notification?.title}');
        if (message.notification != null) {
          showFlutterNotification(
              message); // Fungsi ini tidak melakukan navigasi
        }
      });

      await _createNotificationChannel();
    } catch (e) {
      print('[FCM] Error saat inisialisasi: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');
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
          triggerNavigationFromNotification(data);
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
      triggerNavigationFromNotification(message.data);
    });
  }

  // Fungsi untuk menampilkan notifikasi lokal
  void showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      // Gunakan hashCode dari docId untuk membuat ID notifikasi integer yang konsisten.
      // Jika notifikasi untuk docId yang sama datang lagi, notifikasi yang ada akan di-update,
      // bukan membuat notifikasi baru.
      // Jika docId tidak ada (kasus yang jarang terjadi), gunakan hashCode dari notifikasi sebagai fallback.
      final String docId =
          message.data['docId'] ?? notification.hashCode.toString();
      final int notificationId = docId.hashCode;
      _localNotifications.show(
        notificationId,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'masbro_main_channel', // ID Channel
            'MasBro Notifications', // Nama Channel
            channelDescription: 'Channel untuk notifikasi penting.',
            icon: 'ic_launcher', // Ikon notifikasi
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data), // Sertakan data untuk navigasi
      );
    }
  }

  Future<void> _saveTokenToDatabase(String userId, String token) async {
    try {
      print('[FCM] Mencoba menyimpan token untuk user: $userId');

      // Gunakan set dengan merge untuk memastikan dokumen dibuat jika belum ada
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

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
        await _firestore.collection('users').doc(userId).set({
          'fcmTokens': [token],
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('[FCM] Dokumen user baru dibuat dengan fcmTokens array');
      } catch (e2) {
        print('[FCM] Gagal membuat dokumen baru dengan fcmTokens: $e2');
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
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    await _localNotifications.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  void _setupInteractedMessageListener() {
    // Menangani klik saat app di background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('[FCM] App dibuka dari notifikasi BACKGROUND. Meneruskan data...');
      _notificationDataForNavigation.add(message.data);
    });

    // Menangani klik pada notifikasi LOKAL (yang muncul saat app di foreground)
    _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          print('[FCM] Notifikasi LOKAL di-tap. Meneruskan data...');
          final data = jsonDecode(response.payload!);
          _notificationDataForNavigation.add(data);
        }
      },
    );
  }

  bool _isNavigating = false;

  // --- FUNGSI UTAMA UNTUK NAVIGASI ---
  Future<void> _handleNavigationLogic(Map<String, dynamic> data) async {
    // Cegah navigasi berulang
    if (_isNavigating) {
      print(
          '[FCM] Navigasi sedang berlangsung, mengabaikan permintaan navigasi baru');
      return;
    }

    final String? collection = data['collection'];
    final String? docId = data['docId'];

    if (collection == null || docId == null) {
      print(
          '[FCM] Data navigasi tidak lengkap: collection=$collection, docId=$docId');
      return;
    }

    // Set flag navigasi dimulai
    _isNavigating = true;

    try {
      // Tunggu dashboard ter-render sempurna
      await Future.delayed(const Duration(milliseconds: 800));

      // Mengambil data user yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[FCM] User tidak terautentikasi');
        return;
      }

      final currentUser = await _userService.getUserData(user.uid);
      if (currentUser == null) {
        print('[FCM] Data user tidak ditemukan');
        return;
      }

      final navigator = _navigationService.navigatorKey.currentState;
      if (navigator == null || !navigator.mounted) {
        print('[FCM] Navigator tidak tersedia atau tidak mounted');
        return;
      }

      // Untuk teknisi, tidak perlu navigasi tambahan karena sudah di dashboard
      if (currentUser.role == 'technician') {
        print(
            '[FCM] Role Teknisi, sudah berada di dashboard. Tidak perlu navigasi tambahan.');
        return;
      }

      // Ambil data dari Firestore untuk user dan officer
      final docSnapshot =
          await _firestore.collection(collection).doc(docId).get();
      if (!docSnapshot.exists) {
        print('[FCM] Dokumen tidak ditemukan: $collection/$docId');
        return;
      }

      Widget? targetScreen;

      // Switch case untuk menentukan halaman detail
      switch (collection) {
        case 'reports':
          final report = ReportModel.fromFirestore(docSnapshot);
          targetScreen = currentUser.role == 'officer'
              ? officer_report_detail.ReportDetailScreen(report: report)
              : user_report_detail.ReportDetailScreen(report: report);
          break;
        case 'requests_resource':
          final request = RequestModel.fromFirestore(docSnapshot);
          targetScreen = currentUser.role == 'officer'
              ? officer_resource_detail.RequestDetailScreenResource(
                  request: request)
              : user_resource_detail.RequestDetailScreen(request: request);
          break;
        case 'ride_requests':
          final rideRequest = RideRequestModel.fromFirestore(docSnapshot);
          targetScreen = currentUser.role == 'officer'
              ? officer_ride_detail.RideRequestDetailScreen(
                  request: rideRequest)
              : user_ride_detail.RideRequestDetailScreen(request: rideRequest);
          break;
        case 'bookings':
          final booking = BookingModel.fromFirestore(docSnapshot);
          targetScreen = currentUser.role == 'officer'
              ? officer_booking_detail.BookingDetailScreen(booking: booking)
              : user_booking_detail.BookingDetailScreen(booking: booking);
          break;
        default:
          print('[NAVIGATION] Collection tidak dikenal: $collection');
      }

      if (targetScreen != null) {
        print(
            '[FCM] Melakukan navigasi ke halaman detail untuk collection: $collection');

        // Gunakan push biasa, bukan pushAndRemoveUntil untuk menjaga context
        navigator.push(
          MaterialPageRoute(
            builder: (_) => targetScreen!,
            settings: RouteSettings(
              name: '/notification_detail',
              arguments: {'collection': collection, 'docId': docId},
            ),
          ),
        );

        print('[FCM] Navigasi berhasil dilakukan ke halaman detail');
      }
    } catch (e) {
      print("[FCM] Error handling notification navigation: $e");
    } finally {
      // Reset flag navigasi selesai
      await Future.delayed(const Duration(milliseconds: 500));
      _isNavigating = false;
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'masbro_main_channel',
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
