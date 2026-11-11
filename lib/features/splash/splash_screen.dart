import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/dashboard_full_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../auth/login_screen.dart';
import '../auth/onboarding_password_screen.dart';
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
  DashboardFullModel? _preloadedDashboardData;

  @override
  void initState() {
    super.initState();
    // Preload dashboard data in parallel while splash animation runs
    if (StorageService.isLoggedIn()) {
      ApiService.getDashboardFull().then((res) {
        if (res.success && res.data != null) {
          _preloadedDashboardData = res.data;
        }
      }).catchError((_) {});
    }

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Apple-style pop-out expansion when transitioning out
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
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
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    await _exitController.forward();
    if (!mounted) return;

    final bool loggedIn = StorageService.isLoggedIn();
    final user = StorageService.getUser();
    Widget destination;
    if (!loggedIn || user == null) {
      destination = const LoginScreen();
    } else if (!user.hasChangedPassword) {
      destination = OnboardingPasswordScreen(user: user);
    } else {
      destination = DashboardScreen(initialData: _preloadedDashboardData);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
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
      backgroundColor: const Color(0xFFF2F2F7), // Apple System Grouped Background
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: AnimatedBuilder(
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

                // ── Apple Pop-out Logo with Subtle Shockwave Ring ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer subtle shockwave ring
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF007AFF).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    )
                        .animate(
                          onPlay: (controller) => controller.repeat(),
                        )
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1.3, 1.3),
                          duration: 1800.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeOut(duration: 1800.ms),

                    // Middle pure white card backdrop
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFE5E5EA),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),

                    // App Logo
                    Image.asset(
                      'assets/images/logo.png',
                      width: 68,
                      height: 68,
                      errorBuilder: (_, __, ___) => const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 56,
                        color: Color(0xFF007AFF),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1.0, 1.0),
                          duration: 700.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 350.ms),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Apple Typography ──
                Text(
                  'PRESENSI SISWA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF000000),
                    letterSpacing: 2.0,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 6),

                Text(
                  'SMK NEGERI 1 BERINGIN',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF007AFF),
                    letterSpacing: 1.2,
                  ),
                )
                    .animate(delay: 450.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 40),

                // ── Sleek iOS Progress Capsule ──
                Container(
                  width: 130,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                )
                    .animate(delay: 550.ms)
                    .fadeIn(duration: 400.ms),

                const Spacer(flex: 3),

                // ── Bottom Branding ──
                Text(
                  'Portal Presensi Digital Siswa',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E8E93),
                    letterSpacing: 0.4,
                  ),
                ).animate(delay: 700.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
