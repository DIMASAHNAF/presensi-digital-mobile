import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onBack,
    required this.onLogout,
  });

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar dari Aplikasi?',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Anda harus memasukkan NISN dan kata sandi kembali untuk masuk.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: onBack,
        ),
        title: Text(
          'Profil Siswa',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Avatar & Name Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                      color: AppColors.surfaceMuted,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: user?.avatar != null && user!.avatar!.isNotEmpty
                        ? Image.network(
                            'https://presensi.smknegeri1beringin.sch.id/storage/${user!.avatar}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: AppColors.primaryBlue,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppColors.primaryBlue,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Nama Siswa',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user?.kelasNama ?? "Kelas"} • NISN ${user?.nisn ?? "-"}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Metadata
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildProfileRow(
                    label: 'Status Perekaman Wajah',
                    value: (user?.isFaceEnrolled ?? false) ? 'Terdaftar (ArcFace 512-D)' : 'Belum Terdaftar',
                    isBadge: true,
                    badgeColor: (user?.isFaceEnrolled ?? false) ? AppColors.success : AppColors.danger,
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _buildProfileRow(
                    label: 'Nama Orang Tua / Wali',
                    value: user?.namaOrtu ?? 'Belum diisi',
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _buildProfileRow(
                    label: 'WhatsApp Orang Tua',
                    value: user?.noHpOrtu ?? 'Belum diisi',
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _buildProfileRow(
                    label: 'Sekolah',
                    value: 'SMK Negeri 1 Beringin',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                label: Text(
                  'Keluar dari Akun',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.dangerBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.dangerBg,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Version Info
            Text(
              'Versi Aplikasi 1.0.0 (Native Flutter + Golang Engine)\nSMK Negeri 1 Beringin',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required String label,
    required String value,
    bool isBadge = false,
    Color? badgeColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppColors.primaryBlue).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor ?? AppColors.primaryBlue,
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
      ],
    );
  }
}

