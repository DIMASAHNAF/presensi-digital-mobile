import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/kelas_model.dart';
import '../../core/services/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../enrollment/enroll_wajah_screen.dart';
import 'login_screen.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nisnController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _namaOrtuController = TextEditingController();
  final _noHpOrtuController = TextEditingController();

  KelasModel? _selectedKelas;
  List<KelasModel> _kelasList = [];
  bool _isLoadingKelas = true;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKelas();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _nisnController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _namaOrtuController.dispose();
    _noHpOrtuController.dispose();
    super.dispose();
  }

  Future<void> _loadKelas() async {
    final res = await ApiService.getKelas();
    if (!mounted) return;
    setState(() {
      _isLoadingKelas = false;
      if (res.success && res.data != null) {
        _kelasList = res.data!;
      } else {
        _errorMessage = res.message;
      }
    });
  }

  void _proceedToFace() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    if (_selectedKelas == null) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Kelas wajib dipilih.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok.');
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.of(context)
        .push(
      CupertinoPageRoute(
        builder: (_) => EnrollWajahScreen(
          onSubmitExternal: (images) => ApiService.register(
            name: _nameController.text,
            username: _usernameController.text,
            nisn: _nisnController.text,
            kelasId: _selectedKelas!.id,
            password: _passwordController.text,
            passwordConfirmation: _confirmController.text,
            faceImagesBase64: images,
            namaOrtu: _namaOrtuController.text.trim().isEmpty
                ? null
                : _namaOrtuController.text.trim(),
            noHpOrtu: _noHpOrtuController.text.trim().isEmpty
                ? null
                : _noHpOrtuController.text.trim(),
          ),
        ),
      ),
    )
        .then((registered) {
      if (registered == true && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color:  AppColors.border),
                          ),
                          child:  Icon(CupertinoIcons.back,
                              size: 18, color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Daftar Akun Siswa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SMK Negeri 1 Beringin • Pendaftaran Mandiri',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color:  AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildFieldCard(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                    const SizedBox(height: 18),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            CupertinoPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'Sudah punya akun? ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color:  AppColors.textMuted,
                            ),
                            children: [
                              TextSpan(
                                text: 'Masuk',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color:  AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildFieldCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color:  AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          _field(
            controller: _nameController,
            hint: 'Nama Lengkap',
            icon: CupertinoIcons.person,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi.' : null,
          ),
          _divider(),
          _field(
            controller: _usernameController,
            hint: 'Username (huruf/angka/_)',
            icon: CupertinoIcons.at,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username wajib diisi.';
              if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v.trim())) {
                return 'Username hanya huruf, angka, strip, underscore.';
              }
              return null;
            },
          ),
          _divider(),
          _field(
            controller: _nisnController,
            hint: 'NISN (10 digit)',
            icon: CupertinoIcons.number,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'NISN wajib diisi.';
              if (v.trim().length != 10) return 'NISN harus 10 digit angka.';
              return null;
            },
          ),
          _divider(),
          _buildKelasDropdown(),
          _divider(),
          _field(
            controller: _passwordController,
            hint: 'Password (min 6 karakter)',
            icon: CupertinoIcons.lock,
            obscure: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi.';
              if (v.length < 6) return 'Password minimal 6 karakter.';
              return null;
            },
          ),
          _divider(),
          _field(
            controller: _confirmController,
            hint: 'Konfirmasi Password',
            icon: CupertinoIcons.lock_shield,
            obscure: _obscureConfirm,
            onToggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) {
              if (v != _passwordController.text) {
                return 'Konfirmasi password tidak cocok.';
              }
              return null;
            },
          ),
          _divider(),
          _field(
            controller: _namaOrtuController,
            hint: 'Nama Orang Tua (opsional)',
            icon: CupertinoIcons.person_2,
            required: false,
          ),
          _divider(),
          _field(
            controller: _noHpOrtuController,
            hint: 'No. WhatsApp Orang Tua (opsional)',
            icon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
            required: false,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
       Divider(height: 1, indent: 48, color: AppColors.background);

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color:  AppColors.textQuaternary, fontSize: 14),
        prefixIcon: Icon(icon, color:  AppColors.textMuted, size: 20),
        suffixIcon: onToggleObscure != null
            ? GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  color:  AppColors.textMuted,
                  size: 18,
                ),
              )
            : null,
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      validator: validator,
    );
  }

  Widget _buildKelasDropdown() {
    if (_isLoadingKelas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<KelasModel>(
        value: _selectedKelas,
        isExpanded: true,
        icon:  Icon(CupertinoIcons.chevron_down,
            size: 16, color: AppColors.textMuted),
        decoration:  InputDecoration(
          prefixIcon:
              Icon(Icons.school_rounded, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
        hint: Text(
          'Pilih Kelas',
          style: GoogleFonts.inter(color:  AppColors.textQuaternary, fontSize: 14),
        ),
        items: _kelasList
            .map((k) => DropdownMenuItem<KelasModel>(
                  value: k,
                  child: Text(
                    k.namaKelas,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (k) => setState(() => _selectedKelas = k),
        validator: (_) => _selectedKelas == null ? 'Kelas wajib dipilih.' : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _proceedToFace,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient:  LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.primaryIndigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:  AppColors.primaryBlue.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lanjut Rekam Wajah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.arrow_right_circle_fill,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }
}
