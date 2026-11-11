import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'onboarding_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nisnController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nisnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.login(
        _nisnController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (res.success && res.data != null) {
        final user = res.data!;
        HapticFeedback.mediumImpact();

        if (!user.hasChangedPassword) {
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(
              builder: (_) => OnboardingPasswordScreen(user: user),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = res.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Terjadi kesalahan sistem saat proses login.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Apple System Grouped Background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Apple Pop-out Logo ──
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE5E5EA),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          'assets/images/logo.png',
                          errorBuilder: (_, __, ___) => const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 44,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 450.ms,
                          curve: Curves.easeOutBack,
                        ),

                    const SizedBox(height: 20),

                    // ── Apple Large Title Typography ──
                    Text(
                      'Portal Siswa',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.6,
                      ),
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: 4),

                    Text(
                      'SMK Negeri 1 Beringin • Masuk Akun',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8E8E93),
                      ),
                    )
                        .animate(delay: 250.ms)
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 14),

                    // ── Apple Biometric Badge ──
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF007AFF).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.viewfinder,
                              size: 13,
                              color: Color(0xFF007AFF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Face ID & Biometrik Siap',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF007AFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 28),

                    // ── Error Banner ──
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF3B30).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              color: Color(0xFFFF3B30),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFFFF3B30),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 250.ms)
                          .shake(hz: 3, offset: const Offset(4, 0)),
                      const SizedBox(height: 18),
                    ],

                    // ── Apple iOS Grouped Input Fields ──
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE5E5EA),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // NISN / Username Field
                          TextFormField(
                            controller: _nisnController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'NISN atau Username Siswa',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFFC7C7CC),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                CupertinoIcons.person_crop_circle,
                                color: Color(0xFF8E8E93),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'NISN atau Username wajib diisi.';
                              }
                              return null;
                            },
                          ),

                          const Divider(
                              height: 1, indent: 48, color: Color(0xFFF2F2F7)),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Kata Sandi (Kosongkan jika login perdana)',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFFC7C7CC),
                                fontSize: 13.5,
                              ),
                              prefixIcon: const Icon(
                                CupertinoIcons.lock_fill,
                                color: Color(0xFF8E8E93),
                                size: 19,
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                behavior: HitTestBehavior.opaque,
                                child: Icon(
                                  _obscurePassword
                                      ? CupertinoIcons.eye_slash
                                      : CupertinoIcons.eye,
                                  color: const Color(0xFF8E8E93),
                                  size: 19,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                            ),
                            validator: (val) {
                              // Diperbolehkan kosong untuk siswa baru yang baru login pertama kali
                              return null;
                            },
                          ),
                        ],
                      ),
                    ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // ── Apple Tactile Login Button ──
                    GestureDetector(
                      onTap: _isLoading ? null : _handleLogin,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF007AFF),
                              Color(0xFF5856D6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Masuk ke Akun',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      CupertinoIcons.arrow_right_circle_fill,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // ── iOS Info Card ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE5E5EA), width: 0.8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.info_circle_fill,
                            size: 18,
                            color: Color(0xFF007AFF),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Gunakan NISN resmi dari sekolah. Jika lupa kata sandi atau akun terkunci, hubungi Walikelas atau Tim IT SMKN 1 Beringin.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8E8E93),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 450.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
