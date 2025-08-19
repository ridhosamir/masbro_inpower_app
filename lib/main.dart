import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:masbro_inpower_app/screens/homeDashboard/dashboard_user.dart';
import 'package:masbro_inpower_app/screens/homeDashboard/dashboard_officer.dart';
import 'package:masbro_inpower_app/screens/homeDashboard/dashboard_technician.dart';
import 'package:masbro_inpower_app/screens/admin/admin_dashboard.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'screens/auth/login_screen.dart';
import 'utils/theme.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:masbro_inpower_app/services/navigation_service.dart';
import 'package:masbro_inpower_app/services/statusNotifications/notif_status_helper.dart';
import 'package:masbro_inpower_app/services/notification_list_service.dart';
import 'models/user_model.dart';

final NavigationService navigationService = NavigationService();
final UserService userService = UserService();
final NotificationService notificationService =
    NotificationService(navigationService, userService);
final NotificationListService notificationListService =
    NotificationListService();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inisialisasi Firebase untuk background handler
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('[BACKGROUND] Pesan diterima: ${message.notification?.title}');
  print('[BACKGROUND] Data: ${message.data}');

  // Simpan notifikasi ke database jika perlu
  if (message.data.isNotEmpty) {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('[BACKGROUND] Error menyimpan notifikasi: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pindahkan inisialisasi Firebase ke atas agar bisa digunakan oleh setup notifikasi
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[MAIN] Firebase berhasil diinisialisasi');
  } catch (e) {
    print('[MAIN] Gagal menginisialisasi Firebase: $e');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Setup notifikasi lokal untuk non-web platform
  if (!kIsWeb) {
    try {
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
    } catch (e) {
      print('[MAIN] Persistence tidak bisa diaktifkan: $e');
    }
  }

  await initializeDateFormatting('id_ID', null);

  // Blok try-catch ini sedikit diubah karena Firebase.initializeApp sudah dipanggil di atas
  try {
    if (!kIsWeb) {
      try {
        await FirebaseFirestore.instance.enablePersistence(
          const PersistenceSettings(synchronizeTabs: true),
        );
      } catch (e) {
        print('[MAIN] Persistence tidak bisa diaktifkan: $e');
      }
    }

    await notificationService.setupInteractedMessage();

    final storage = FirebaseStorage.instanceFor(
        bucket: 'gs://test-4fa2a.firebasestorage.app');
    print('[MAIN] Bucket Storage yang digunakan: ${storage.bucket}');
  } catch (e) {
    print('[MAIN] Error pada setup lanjutan: $e');
  }

  runApp(DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: userService),
        Provider.value(value: navigationService),
        Provider.value(value: notificationService),
        Provider.value(value: notificationListService),
      ],
      child: MaterialApp(
        title: 'MasBro InPower App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigationService.navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/auth_wrapper': (context) => const AuthWrapper(),
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;

  // Background animations
  late Animation<double> _gradientPosition;
  late Animation<double> _backgroundFadeIn;

  // Logo animations
  late Animation<double> _logoFadeIn;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<Offset> _logoSlideUp;

  // Text animations
  late Animation<double> _textFadeIn;
  late Animation<Offset> _appNameSlide;
  late Animation<Offset> _taglineSlide;

  // Particle animations
  late Animation<double> _particlesFadeIn;
  late Animation<double> _particlesPosition;

  // Loading indicator animation
  late Animation<double> _loadingFadeIn;
  late Animation<double> _loadingRotation;

  @override
  void initState() {
    super.initState();

    // Initialize main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Background animations
    _gradientPosition = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    ));

    _backgroundFadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    // Logo animations
    _logoFadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
    ));

    _logoScale = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
    ));

    _logoRotation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
    ));

    _logoSlideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    ));

    // Text animations with staggered effect
    _textFadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
    ));

    _appNameSlide = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 0.7, curve: Curves.easeOutCubic),
    ));

    _taglineSlide = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.6, 0.8, curve: Curves.easeOutCubic),
    ));

    // Particle animations
    _particlesFadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
    ));

    _particlesPosition = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    ));

    // Loading indicator animation
    _loadingFadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.7, 0.9, curve: Curves.easeIn),
    ));

    _loadingRotation = Tween<double>(
      begin: 0.0,
      end: 2.0 * 3.14159, // 360 degrees in radians
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
    ));

    // Start the animation
    _animationController.forward();

    // Navigate to AuthWrapper after animation completes
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthWrapper(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return Stack(
            children: [
              // Animated Gradient Background
              Container(
                width: screenSize.width,
                height: screenSize.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context)
                          .primaryColor
                          .withOpacity(_backgroundFadeIn.value),
                      Theme.of(context)
                          .primaryColor
                          .withBlue(
                            (Theme.of(context).primaryColor.blue + 20)
                                .clamp(0, 255),
                          )
                          .withOpacity(_backgroundFadeIn.value * 0.85),
                      Theme.of(context)
                          .primaryColor
                          .withRed(
                            (Theme.of(context).primaryColor.red - 30)
                                .clamp(0, 255),
                          )
                          .withOpacity(_backgroundFadeIn.value * 0.7),
                    ],
                    stops: [
                      0.0,
                      0.5 + (_gradientPosition.value * 0.2),
                      1.0,
                    ],
                  ),
                ),
              ),

              // Particle Effect 1 (top right)
              Positioned(
                top: screenSize.height * 0.1 - (20 * _particlesPosition.value),
                right: screenSize.width * 0.1 - (10 * _particlesPosition.value),
                child: Opacity(
                  opacity: _particlesFadeIn.value * 0.5,
                  child: Container(
                    width: screenSize.width * 0.4,
                    height: screenSize.width * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Particle Effect 2 (mid left)
              Positioned(
                top: screenSize.height * 0.45 + (10 * _particlesPosition.value),
                left: -screenSize.width * 0.2 + (20 * _particlesPosition.value),
                child: Opacity(
                  opacity: _particlesFadeIn.value * 0.3,
                  child: Container(
                    width: screenSize.width * 0.5,
                    height: screenSize.width * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.2, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Particle Effect 3 (bottom right)
              Positioned(
                bottom:
                    -screenSize.height * 0.1 + (15 * _particlesPosition.value),
                right:
                    -screenSize.width * 0.1 - (10 * _particlesPosition.value),
                child: Opacity(
                  opacity: _particlesFadeIn.value * 0.4,
                  child: Container(
                    width: screenSize.width * 0.6,
                    height: screenSize.width * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Small decorative particles
              ...List.generate(6, (index) {
                final delay = index * 0.1;
                final size = (index % 3 + 1) * 10.0;
                final posX = (index * 45 + 30) % screenSize.width.toInt();
                final posY = (index * 80 + 50) % screenSize.height.toInt();
                final opacity = _particlesFadeIn.value *
                    (index % 2 == 0 ? 0.7 : 0.5) *
                    (((_particlesPosition.value * 3) + delay) % 1.0);

                return Positioned(
                  left: posX.toDouble(),
                  top: posY.toDouble() -
                      (20 * _particlesPosition.value * (index % 3 + 1)),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: size,
                            spreadRadius: size * 0.3,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with animations
                    FadeTransition(
                      opacity: _logoFadeIn,
                      child: SlideTransition(
                        position: _logoSlideUp,
                        child: Transform.rotate(
                          angle: _logoRotation.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/MasBro.png',
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App name with side slide animation
                    FadeTransition(
                      opacity: _textFadeIn,
                      child: SlideTransition(
                        position: _appNameSlide,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Text(
                            'MasBro App',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  blurRadius: 8.0,
                                  color: Colors.black26,
                                  offset: Offset(0, 3.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tagline with opposite side slide animation
                    FadeTransition(
                      opacity: _textFadeIn,
                      child: SlideTransition(
                        position: _taglineSlide,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Sistem Manajemen Layanan',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 16,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Animated Loading Indicator
                    FadeTransition(
                      opacity: _loadingFadeIn,
                      child: Transform.rotate(
                        angle: _loadingRotation.value,
                        child: Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Loading text
                    FadeTransition(
                      opacity: _loadingFadeIn,
                      child: Text(
                        'Memuat...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memuat...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (authService.user == null) {
          print(
              '[AUTH_WRAPPER] Tidak ada pengguna terautentikasi, mengarahkan ke LoginScreen');
          return LoginScreen();
        }

        print(
            '[AUTH_WRAPPER] Pengguna terautentikasi: ${authService.user!.uid}');
        return FutureBuilder(
          future: Provider.of<UserService>(context, listen: false)
              .getUserData(authService.user!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Menyiapkan dashboard Anda...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              print(
                  '[AUTH_WRAPPER] Gagal memuat data pengguna: ${snapshot.error}');
              return LoginScreen();
            }

            final userData = snapshot.data!;
            print('[AUTH_WRAPPER] Peran pengguna: ${userData.role}');

            final notificationService =
                Provider.of<NotificationService>(context, listen: false);
            notificationService.initNotifications(userData.uid);

            // Navigate based on role
            switch (userData.role) {
              case 'employee':
                return const HomeDashboardUser();
              case 'officer':
                return const HomeDashboardOfficer();
              case 'technician':
                return const HomeDashboardTechnician();
              case 'admin':
                return AdminDashboard();
              default:
                print(
                    '[AUTH_WRAPPER] Peran tidak dikenali: ${userData.role}, mengarahkan ke LoginScreen');
                return LoginScreen();
            }
          },
        );
      },
    );
  }
}
