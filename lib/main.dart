import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[MAIN] Firebase berhasil diinisialisasi');
    // Verifikasi bucket Storage
    final storage = FirebaseStorage.instanceFor(
        bucket: 'gs://test-4fa2a.firebasestorage.app');
    print('[MAIN] Bucket Storage yang digunakan: ${storage.bucket}');
  } catch (e) {
    print('[MAIN] Gagal menginisialisasi Firebase: $e');
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
        ChangeNotifierProvider(create: (_) => UserService()),
      ],
      child: MaterialApp(
        title: 'Masbro App',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
        ],
        locale: const Locale('id', 'ID'),
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.home_repair_service,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 24),
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
                  child: Center(
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
