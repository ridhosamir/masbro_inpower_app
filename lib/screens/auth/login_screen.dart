import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // DIUBAH: Menggunakan TickerProviderStateMixin untuk beberapa controller
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Controller utama untuk sequence animasi
  late AnimationController _animationController;

  // Controller khusus untuk efek kilau pada logo
  late AnimationController _shineController;

  // Kumpulan animasi untuk setiap elemen UI
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _footerFadeAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500), // Durasi total lebih lama
      vsync: this,
    );

    _shineController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animasi untuk Logo (muncul di tengah lalu geser ke atas)
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack)),
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: const Interval(0.0, 0.3)),
    );
    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.4, 0.7, curve: Curves.easeInOutCubic)),
    );

    // Animasi untuk Judul dan Subjudul
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.5, 0.8, curve: Curves.easeOut)),
    );

    // Animasi untuk Form Login
    _formSlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.6, 0.9, curve: Curves.easeOutCubic)),
    );

    // Animasi untuk Copyright Footer
    _footerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.8, 1.0, curve: Curves.easeOut)),
    );

    // Animasi untuk efek kilau pada logo
    _shineAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.linear),
    );

    // Mulai animasi
    _animationController.forward();

    // Mulai animasi kilau setelah jeda singkat
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _shineController.repeat(); // Ulangi animasi kilau
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  // Fungsi _login, _normalizeEmail, dan _showErrorDialog tidak berubah
  String _normalizeEmail(String email) {
    String trimmedEmail = email.trim();
    if (trimmedEmail.contains('@')) {
      return trimmedEmail;
    }
    return '$trimmedEmail@gmail.com';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final normalizedEmail = _normalizeEmail(_emailController.text);
    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.signIn(
      normalizedEmail,
      _passwordController.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
    if (error != null && mounted) {
      _showErrorDialog(error);
    }
  }

  void _showErrorDialog(String error) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Error Dialog",
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline,
                          color: Colors.red, size: 32),
                    ),
                    const SizedBox(height: 20),
                    const Text('Login Failed',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(error,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.grey[700], fontSize: 14)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      child: const Text('Try Again',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Latar Belakang Gradient Animasi
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
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
              );
            },
          ),
          // Lingkaran Dekoratif yang Bergerak
          AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  top: -screenHeight * 0.1 + (_animationController.value * 20),
                  right: -screenWidth * 0.2,
                  child: Container(
                    width: screenWidth * 0.7,
                    height: screenWidth * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                );
              }),
          AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  bottom:
                      -screenHeight * 0.15 - (_animationController.value * 20),
                  left: -screenWidth * 0.1,
                  child: Container(
                    width: screenWidth * 0.7,
                    height: screenWidth * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                );
              }),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SlideTransition(
                  position: _logoSlideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Widget Logo dengan Efek Kilau
                      ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: Hero(
                            tag: 'app_logo',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/MasBro.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  // Lapisan untuk efek kilau
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _shineAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                              100 * _shineAnimation.value, 0),
                                          child: Container(
                                            width: 40,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.white.withOpacity(0.0),
                                                  Colors.white.withOpacity(0.6),
                                                  Colors.white.withOpacity(0.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Widget Judul dan Subjudul
                      FadeTransition(
                        opacity: _titleFadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Service Management',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black26,
                                    offset: const Offset(0, 5.0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                'Sign in to continue',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Widget Form Login
                      FadeTransition(
                        opacity:
                            _footerFadeAnimation, // Reuse fade for smooth appearance
                        child: SlideTransition(
                          position: _formSlideAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 40),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Konten form (TextFormField, Button) tidak berubah
                                        Text('Username',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800])),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: InputDecoration(
                                            hintText: 'Enter username',
                                            prefixIcon: Icon(
                                                Icons.email_outlined,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 20),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty)
                                              return 'Please enter your email or username';
                                            if (value.contains('@')) {
                                              if (!RegExp(
                                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                  .hasMatch(value))
                                                return 'Please enter a valid email';
                                            } else {
                                              if (!RegExp(r'^[a-zA-Z0-9_.+-]+$')
                                                  .hasMatch(value))
                                                return 'Please enter a valid username';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        Text('Password',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800])),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: !_isPasswordVisible,
                                          decoration: InputDecoration(
                                            hintText: 'Enter your password',
                                            prefixIcon: Icon(Icons.lock_outline,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                  _isPasswordVisible
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  color: Colors.grey[600]),
                                              onPressed: () => setState(() =>
                                                  _isPasswordVisible =
                                                      !_isPasswordVisible),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 20),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty)
                                              return 'Please enter your password';
                                            if (value.length < 6)
                                              return 'Password must be at least 6 characters';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 30),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading ? null : _login,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16)),
                                              elevation: 8,
                                              shadowColor: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.5),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2.5))
                                                : const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text('Sign In',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing:
                                                                  0.5)),
                                                      SizedBox(width: 8),
                                                      Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          size: 20),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Widget Copyright Footer
                      FadeTransition(
                        opacity: _footerFadeAnimation,
                        child: Text(
                          'Copyright © 2025 MasBro App',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
