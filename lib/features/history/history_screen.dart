import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/history_model.dart';
import '../../core/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback onBack;

  const HistoryScreen({super.key, required this.onBack});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<HistoryItem> _historyList = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.getHistory(limit: 50);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _historyList = res.data!;
      }
    });
  }

  void _showPhotoDialog(String photoUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: const Text('Foto tidak dapat dimuat.'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
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
          onPressed: widget.onBack,
        ),
        title: Text(
          'Riwayat Presensi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              color: AppColors.primaryBlue,
              child: _historyList.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum Ada Riwayat Presensi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Data kehadiran Anda akan muncul di sini setelah melakukan presensi.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: _historyList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final item = _historyList[idx];
                        return _buildHistoryCard(item);
                      },
                    ),
            ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (item.status == 'hadir') {
      if (item.lateMinutes > 0) {
        badgeBg = AppColors.warningBg;
        badgeText = AppColors.warning;
        badgeLabel = 'Terlambat ${item.lateMinutes} mnt';
      } else {
        badgeBg = AppColors.successBg;
        badgeText = AppColors.success;
        badgeLabel = 'Tepat Waktu';
      }
    } else if (item.status == 'izin' || item.status == 'sakit') {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = AppColors.primaryBlue;
      badgeLabel = item.status.toUpperCase();
    } else {
      badgeBg = AppColors.dangerBg;
      badgeText = AppColors.danger;
      badgeLabel = 'Alpha';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Photo Thumbnail or Icon
          if (item.fotoUrl != null && item.fotoUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => _showPhotoDialog(
                item.fotoUrl!.startsWith('http')
                    ? item.fotoUrl!
                    : 'https://presensi.smknegeri1beringin.sch.id/storage/${item.fotoUrl}',
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  item.fotoUrl!.startsWith('http')
                      ? item.fotoUrl!
                      : 'https://presensi.smknegeri1beringin.sch.id/storage/${item.fotoUrl}',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.face_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
            ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.tanggal,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.jamPelajaran ?? 'Jam Kehadiran Reguler',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Pukul ${item.waktuScan} WIB',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (item.guruNama != null) ...[
                      const SizedBox(width: 8),
                      Text('•', style: GoogleFonts.inter(color: AppColors.textMuted)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.guruNama!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

