import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/dashboard_full_model.dart';
import '../../../core/theme/app_theme.dart';

//  REKAP KEHADIRAN DIALOG — Kartu Presensi Bulanan Siswa
//  Statistik Kehadiran, On-Time Rate & WhatsApp Gateway Log

class RekapKehadiranDialog extends StatelessWidget {
  final DashboardFullModel data;

  const RekapKehadiranDialog({super.key, required this.data});

  static void show(BuildContext context, {required DashboardFullModel data}) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => RekapKehadiranDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = data.stats;
    final user = data.user;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration:  BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color:  AppColors.textQuaternary,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kartu Rekap Presensi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration:  BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child:  Icon(CupertinoIcons.xmark, size: 16, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color:  AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.nama,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                Text(
                                  'NISN: ${user.nisn} • ${user.kelas}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color:  AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color:  AppColors.successBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${stats.persentase}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color:  AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                         Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 18),

                        // Stats Grid 2x2
                        Row(
                          children: [
                            Expanded(child: _buildMetricTile('Hadir', '${stats.hadir}',  AppColors.success)),
                            Expanded(child: _buildMetricTile('Izin', '${stats.izin}',  AppColors.warning)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildMetricTile('Sakit', '${stats.sakit}',  AppColors.primaryIndigo)),
                            Expanded(child: _buildMetricTile('Alpa', '${stats.alpa}',  AppColors.danger)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // WhatsApp Notification Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color:  AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration:  BoxDecoration(
                            color: AppColors.successBg,
                            shape: BoxShape.circle,
                          ),
                          child:  Icon(CupertinoIcons.phone_fill, color: AppColors.waGreen, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WhatsApp Gateway Orang Tua',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.noHpOrtu != null && user.noHpOrtu!.isNotEmpty
                                    ? 'Notifikasi dikirim otomatis ke ${user.noHpOrtu}'
                                    : 'Nomor WhatsApp belum diatur di Profil',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color:  AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Rules card (SOP Keterlambatan)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color:  AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOP KETEPATAN WAKTU SMKN 1 BERINGIN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color:  AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRuleRow('Senin - Kamis', 'Batas on-time pukul 07:15 WIB'),
                        const SizedBox(height: 6),
                        _buildRuleRow('Jumat', 'Batas on-time pukul 07:45 WIB'),
                        const SizedBox(height: 6),
                        _buildRuleRow('Radius Presensi', 'Maksimal 150 meter dari gerbang/gedung'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:  AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String day, String desc) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration:  BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$day: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color:  AppColors.primaryDark,
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 12,
              color:  AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
