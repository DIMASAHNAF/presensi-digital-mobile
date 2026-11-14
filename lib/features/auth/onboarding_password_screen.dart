import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import 'auth_router.dart';
import 'login_screen.dart';
import '../../core/theme/app_theme.dart';

class OnboardingPasswordScreen extends StatefulWidget {
  final UserModel user;

  const OnboardingPasswordScreen({super.key, required this.user});

  @override
  State<OnboardingPasswordScreen> createState() =>
      _OnboardingPasswordScreenState();
}

class _OnboardingPasswordScreenState extends State<OnboardingPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isLengthValid => _passwordController.text.length >= 6;
  bool get _isMatching =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  Future<void> _handleSubmit() async {
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
      final res = await ApiService.updatePassword(
        _passwordController.text,
        _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (res.success) {
        HapticFeedback.mediumImpact();
        final updatedUser = res.data ?? widget.user.copyWith(hasChangedPassword: true);
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (_) =>
                buildAuthDestination(resolveAuthStep(updatedUser), updatedUser),
          ),
        );
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
        _errorMessage = 'Terjadi kesalahan sistem: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Proses penyiapan akun belum selesai. Anda harus login kembali untuk melanjutkannya.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.name.split(' ').first;

    return Scaffold(
      backgroundColor:  AppColors.background, // Apple System Grouped Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(CupertinoIcons.square_arrow_left, size: 16),
            label: Text(
              'Keluar',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor:  AppColors.textMuted,
              padding: const EdgeInsets.only(right: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //  Onboarding Stepper Header
                    _buildStepperHeader(),

                    const SizedBox(height: 28),

                    //  Header Icon & Title
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient:  LinearGradient(
                            colors: [AppColors.primaryBlue,  AppColors.primaryBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:  AppColors.primaryBlue.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.lock_shield_fill,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ).animate().scale(
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                        ),

                    const SizedBox(height: 18),

                    Text(
                      'Amankan Akun Anda',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color:  AppColors.primaryDark,
                        letterSpacing: -0.6,
                      ),
                    ).animate(delay: 100.ms).fadeIn(duration: 350.ms),

                    const SizedBox(height: 6),

                    Text(
                      'Halo, $displayName! Karena ini login pertama Anda, silakan buat kata sandi baru pribadi untuk melindungi data presensi Anda.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color:  AppColors.textMuted,
                        height: 1.45,
                      ),
                    ).animate(delay: 200.ms).fadeIn(duration: 350.ms),

                    const SizedBox(height: 24),

                    //  Error Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color:  AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:  AppColors.danger.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                             Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              color: AppColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color:  AppColors.danger,
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

                    //  Grouped Input Fields Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:  AppColors.border,
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
                          // New Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Kata Sandi Baru (Min. 6 Karakter)',
                              hintStyle: GoogleFonts.inter(
                                color:  AppColors.textQuaternary,
                                fontSize: 13.5,
                              ),
                              prefixIcon:  Icon(
                                CupertinoIcons.lock_fill,
                                color: AppColors.textMuted,
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
                                  color:  AppColors.textMuted,
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
                              if (val == null || val.trim().length < 6) {
                                return 'Kata sandi minimal 6 karakter.';
                              }
                              return null;
                            },
                          ),

                           Divider(
                              height: 1, indent: 48, color: AppColors.background),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {}),
                            onFieldSubmitted: (_) => _handleSubmit(),
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ulangi Kata Sandi Baru',
                              hintStyle: GoogleFonts.inter(
                                color:  AppColors.textQuaternary,
                                fontSize: 13.5,
                              ),
                              prefixIcon:  Icon(
                                CupertinoIcons.checkmark_shield_fill,
                                color: AppColors.textMuted,
                                size: 19,
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                behavior: HitTestBehavior.opaque,
                                child: Icon(
                                  _obscureConfirm
                                      ? CupertinoIcons.eye_slash
                                      : CupertinoIcons.eye,
                                  color:  AppColors.textMuted,
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
                              if (val == null || val.isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi.';
                              }
                              if (val != _passwordController.text) {
                                return 'Konfirmasi kata sandi tidak cocok.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    //  Criteria Checklist
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          _buildCriterionItem(
                            isValid: _isLengthValid,
                            text: 'Minimal 6 karakter kombinasi huruf / angka',
                          ),
                          const SizedBox(height: 6),
                          _buildCriterionItem(
                            isValid: _isMatching,
                            text: 'Konfirmasi kata sandi cocok',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    //  Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:  AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                             AppColors.primaryBlue.withOpacity(0.5),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Colors.transparent,
                      ),
                      child: _isLoading
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                              radius: 10,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Simpan & Lanjut Rekam Wajah',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  CupertinoIcons.arrow_right,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 20),

                    // Security Note
                    Center(
                      child: Text(
                        'Langkah 1 dari 2: Pengaturan Keamanan Akun',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color:  AppColors.textMuted,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildStepperHeader() {
    return Row(
      children: [
        // Step 1: Active
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration:  BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kata Sandi',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color:  AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color:  AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Step 2: Upcoming
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration:  BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child:  Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rekam Wajah',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color:  AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color:  AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCriterionItem({required bool isValid, required String text}) {
    return Row(
      children: [
        Icon(
          isValid
              ? CupertinoIcons.checkmark_circle_fill
              : CupertinoIcons.circle,
          size: 15,
          color: isValid ?  AppColors.success :  AppColors.textQuaternary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isValid ?  AppColors.success :  AppColors.textMuted,
            fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
