import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/storage_service.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _exitController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Apple-style pop-out expansion when transitioning out
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _startLaunchSequence();
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _startLaunchSequence() async {
    // Light haptic tap on launch
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    // Wait for the entrance spring animations to complete
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    // Pop-out exit transition
    await _exitController.forward();
    if (!mounted) return;

    final bool loggedIn = StorageService.isLoggedIn();
    final Widget destination =
        loggedIn ? const DashboardScreen() : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: destination,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Apple OLED True Black
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // ── Apple Pop-out Logo with Shockwave Ring ──
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glowing shockwave ring
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF007AFF).withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(),
                      )
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.35, 1.35),
                        duration: 1800.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeOut(duration: 1800.ms),

                  // Middle glass backdrop
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1C1C1E).withOpacity(0.8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.16),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withOpacity(0.28),
                          blurRadius: 36,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  // App Logo with Apple spring pop-out
                  Image.asset(
                    'assets/images/logo.png',
                    width: 76,
                    height: 76,
                    errorBuilder: (_, __, ___) => const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 64,
                      color: Color(0xFF007AFF),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.2, 0.2),
                        end: const Offset(1.0, 1.0),
                        duration: 750.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 400.ms)
                      .then(delay: 150.ms)
                      .shimmer(
                        duration: 1400.ms,
                        color: Colors.white.withOpacity(0.25),
                      ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Apple Typography ──
              Text(
                'PRESENSI SISWA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 3.5,
                ),
              )
                  .animate(delay: 350.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 6),

              Text(
                'SMK NEGERI 1 BERINGIN',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8E8E93),
                  letterSpacing: 1.5,
                ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 44),

              // ── Sleek iOS Progress Capsule ──
              Container(
                width: 140,
                height: 3.5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 400.ms),

              const Spacer(flex: 3),

              // ── Bottom Branding ──
              Text(
                'Portal Siswa • iOS Experience',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 0.6,
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 600.ms),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
