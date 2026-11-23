import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/dashboard_full_model.dart';
import '../../../core/theme/app_theme.dart';

class KehadiranTab extends StatefulWidget {
  final DashboardFullModel data;
  final VoidCallback? onOpenRekap;

  const KehadiranTab({
    super.key,
    required this.data,
    this.onOpenRekap,
  });

  @override
  State<KehadiranTab> createState() => _KehadiranTabState();
}

class _KehadiranTabState extends State<KehadiranTab> {
  String _selectedFilter = 'Semua';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.data.stats;
    final riwayatRaw = widget.data.riwayat;

    final hadirCount = riwayatRaw.where((i) => (i['status'] ?? '').toString().toLowerCase() == 'hadir').length;
    final izinCount = riwayatRaw.where((i) => (i['status'] ?? '').toString().toLowerCase() == 'izin').length;
    final sakitCount = riwayatRaw.where((i) => (i['status'] ?? '').toString().toLowerCase() == 'sakit').length;
    final alpaCount = riwayatRaw.where((i) {
      final s = (i['status'] ?? '').toString().toLowerCase();
      return s == 'alpa' || s == 'alpha';
    }).length;

    // Filter items based on tab and search
    final filteredList = riwayatRaw.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      if (_selectedFilter == 'Hadir' && status != 'hadir') return false;
      if (_selectedFilter == 'Izin' && status != 'izin') return false;
      if (_selectedFilter == 'Sakit' && status != 'sakit') return false;
      if (_selectedFilter == 'Alpa' && status != 'alpa' && status != 'alpha') {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final mapel = (item['mapel'] ?? '').toString().toLowerCase();
        final guru = (item['guru'] ?? '').toString().toLowerCase();
        final tgl = (item['tanggal'] ?? '').toString().toLowerCase();
        final q = _searchQuery.toLowerCase();
        return mapel.contains(q) || guru.contains(q) || tgl.contains(q);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(left: 18, right: 18, top: 4, bottom: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //  1. APPLE HEALTH STAT CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppColors.cardDecoration(radius: 22, elevated: true),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RINGKASAN KEHADIRAN',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.data.user.kelas,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${stats.persentase}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.attendanceStatusColor(stats.persentase),
                        letterSpacing: -1.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Rasio kehadiran terverifikasi pada sesi belajar aktif semester ini.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                //  Segmented Activity Bar (Proportional)
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        if (stats.hadir > 0)
                          Expanded(
                            flex: stats.hadir,
                            child: Container(color:  AppColors.success),
                          ),
                        if (stats.izin > 0)
                          Expanded(
                            flex: stats.izin,
                            child: Container(color:  AppColors.warning),
                          ),
                        if (stats.sakit > 0)
                          Expanded(
                            flex: stats.sakit,
                            child: Container(color:  AppColors.primaryIndigo),
                          ),
                        if (stats.alpa > 0)
                          Expanded(
                            flex: stats.alpa,
                            child: Container(color:  AppColors.danger),
                          ),
                        if (stats.total == 0)
                          Expanded(
                            child: Container(color:  AppColors.border),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //  4 Crisp Metric Columns
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricColumn('Hadir', '${stats.hadir}',  AppColors.success),
                    _buildMetricDivider(),
                    _buildMetricColumn('Izin', '${stats.izin}',  AppColors.warning),
                    _buildMetricDivider(),
                    _buildMetricColumn('Sakit', '${stats.sakit}',  AppColors.primaryIndigo),
                    _buildMetricDivider(),
                    _buildMetricColumn('Alpa', '${stats.alpa}',  AppColors.danger),
                  ],
                ),

                const SizedBox(height: 14),
                 Divider(height: 1, color: AppColors.background),
                const SizedBox(height: 10),

                //  Lihat Rekap Lengkap Presensi Action
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (widget.onOpenRekap != null) {
                      widget.onOpenRekap!();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lihat Rekap Lengkap',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 13,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          //  2. DAPODIK 75% SAFE-ZONE GAUGE (Academic Standing)
          _buildDapodikSafetyCard(stats)
              .animate()
              .fadeIn(duration: 400.ms, delay: 80.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          //  3. MONTHLY ATTENDANCE HEATMAP (Apple Health / GitHub Grid)
          _buildMonthlyHeatmap()
              .animate()
              .fadeIn(duration: 400.ms, delay: 120.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          //  4. SEARCH FIELD
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color:  AppColors.border, width: 1.0),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.inter(fontSize: 13.5, color:  AppColors.primaryDark),
              decoration: InputDecoration(
                hintText: 'Cari mata pelajaran, guru, atau tanggal...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color:  AppColors.textMuted,
                ),
                prefixIcon:  Icon(
                  CupertinoIcons.search,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child:  Icon(
                          CupertinoIcons.clear_thick_circled,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          //  5. FILTER CAPSULES
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('Semua (${riwayatRaw.length})', 'Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Hadir ($hadirCount)', 'Hadir'),
                const SizedBox(width: 8),
                _buildFilterChip('Izin ($izinCount)', 'Izin'),
                const SizedBox(width: 8),
                _buildFilterChip('Sakit ($sakitCount)', 'Sakit'),
                const SizedBox(width: 8),
                _buildFilterChip('Alpa ($alpaCount)', 'Alpa'),
              ],
            ),
          ),

          const SizedBox(height: 18),

          //  6. RIWAYAT PRESENSI LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RIWAYAT PRESENSI',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color:  AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${filteredList.length} sesi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:  AppColors.primaryBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color:  AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:  Icon(
                      CupertinoIcons.tray,
                      size: 26,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada catatan presensi',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color:  AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = filteredList[idx];
                final status = (item['status'] ?? 'hadir').toString().toLowerCase();

                Color badgeColor;
                Color badgeBg;
                String statusLabel;

                if (status == 'hadir') {
                  badgeColor =  AppColors.success;
                  badgeBg =  AppColors.successBg;
                  statusLabel = 'HADIR';
                } else if (status == 'izin') {
                  badgeColor =  AppColors.warning;
                  badgeBg =  AppColors.warningBg;
                  statusLabel = 'IZIN';
                } else if (status == 'sakit') {
                  badgeColor =  AppColors.primaryIndigo;
                  badgeBg =  AppColors.indigoBg;
                  statusLabel = 'SAKIT';
                } else {
                  badgeColor =  AppColors.danger;
                  badgeBg =  AppColors.dangerBg;
                  statusLabel = 'ALPA';
                }

                final photoRaw = (item['photo'] ?? '').toString();
                final String? proofPhoto = photoRaw.isEmpty
                    ? null
                    : '${ApiConstants.storageBaseUrl}/${photoRaw.replaceFirst(RegExp(r'^/?(storage/)?'), '')}';
                final proofDistance = (item['distance'] as num?)?.toDouble();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color:  AppColors.border, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color:  AppColors.shadow.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (proofPhoto != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: proofPhoto,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 46,
                              height: 46,
                              color: badgeBg,
                              child: const Center(
                                child: CupertinoActivityIndicator(radius: 7),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              status == 'hadir'
                                  ? Icons.check_circle_rounded
                                  : status == 'izin'
                                      ? Icons.assignment_outlined
                                      : status == 'sakit'
                                          ? Icons.local_hospital_rounded
                                          : Icons.cancel_outlined,
                              size: 20,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: () {
                          final rawMapel = (item['mapel'] ?? item['keterangan'] ?? 'Presensi Pembelajaran').toString();
                          String mapelTitle = rawMapel;
                          String? sesiDetail;

                          if (rawMapel.contains('(') && rawMapel.endsWith(')')) {
                            final reg = RegExp(r'^(.*?)\s*\((.*?)\)$');
                            final m = reg.firstMatch(rawMapel);
                            if (m != null) {
                              final prefix = m.group(1)!.trim();
                              final inside = m.group(2)!.trim();
                              if (RegExp(r'^Les\s*\d+', caseSensitive: false).hasMatch(prefix)) {
                                var cleanTime = inside.replaceAllMapped(RegExp(r'(\d{2}):(\d{2}):\d{2}'), (match) => '${match.group(1)}:${match.group(2)}');
                                cleanTime = cleanTime.replaceAll(RegExp(r'[\u2013\u2014-]'), ' - ');
                                sesiDetail = '$prefix • $cleanTime WIB';
                                mapelTitle = 'Presensi Pembelajaran';
                              } else {
                                mapelTitle = prefix;
                                var cleanInside = inside.replaceAllMapped(RegExp(r'(\d{2}):(\d{2}):\d{2}'), (match) => '${match.group(1)}:${match.group(2)}');
                                cleanInside = cleanInside.replaceAll(RegExp(r'[\u2013\u2014-]'), ' - ');
                                if (!cleanInside.contains('WIB') && RegExp(r'\d{1,2}[:.]\d{2}').hasMatch(cleanInside)) {
                                  cleanInside += ' WIB';
                                }
                                sesiDetail = cleanInside;
                              }
                            }
                          }

                          final rawJam = (item['jam'] ?? '').toString().replaceAll('WIB', '').trim();
                          final isHadir = status == 'hadir';
                          final hasJam = isHadir && rawJam.isNotEmpty && rawJam != '-';
                          final timeStr = hasJam ? '${item['tanggal'] ?? '-'} • $rawJam WIB' : (item['tanggal'] ?? '-');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mapelTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color:  AppColors.primaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (sesiDetail != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  sesiDetail,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color:  AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      timeStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color:  AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item['guru'] != null && (item['guru'] as String).isNotEmpty) ...[
                                     Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textQuaternary)),
                                    Flexible(
                                      child: Text(
                                        'Guru: ${item['guru']}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color:  AppColors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (isHadir && (proofDistance != null || proofPhoto != null)) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                     Icon(
                                      CupertinoIcons.location_solid,
                                      size: 11,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        proofDistance != null
                                          ? 'Terverifikasi • ${proofDistance.toStringAsFixed(0)} m dari sekolah'
                                          : 'Terverifikasi • GPS sekolah',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color:  AppColors.success,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        }(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  //  2. DAPODIK SAFETY CARD (Clean Apple Health inset card, zero overflow)

  Widget _buildDapodikSafetyCard(StatsModel stats) {
    final isSafe = stats.persentase >= 75;
    final totalAbsence = stats.izin + stats.sakit + stats.alpa;
    final maxAllowed = stats.total > 0 ? (stats.total * 0.25).toInt() : 5;
    final remainingTolerance = (maxAllowed - totalAbsence).clamp(0, 30);

    final accentColor = isSafe ? AppColors.success : AppColors.danger;
    final badgeBg = isSafe ? AppColors.successBg : AppColors.dangerBg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  isSafe
                      ? CupertinoIcons.checkmark_shield_fill
                      : CupertinoIcons.exclamationmark_triangle_fill,
                  size: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Standar Dapodik 75%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isSafe ? 'Aman' : 'Perlu Perhatian',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isSafe
                ? 'Kehadiranmu memenuhi syarat minimal Penilaian Akhir Semester (PAS). Pertahankan kedisiplinan pagi.'
                : 'Kehadiranmu di bawah batas minimum 75% Dapodik. Penuhi sesi berikutnya agar memenuhi syarat ujian.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sisa toleransi ketidakhadiran',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$remainingTolerance hari',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyHeatmap() {
    final calendar = widget.data.calendar;

    // Fallback: derive dari riwayat bila backend belum mengirim calendar.
    final Map<int, String> dayStatus = {};
    if (calendar != null) {
      for (final d in calendar.days) {
        if (d.status != null) dayStatus[d.day] = d.status!;
      }
    } else {
      for (final r in widget.data.riwayat) {
        final tglStr = (r['tanggal'] ?? '').toString();
        final match = RegExp(r'(\d{1,2})').firstMatch(tglStr);
        if (match == null) continue;
        final d = int.tryParse(match.group(1)!) ?? 0;
        final st = (r['status'] ?? '').toString().toLowerCase();
        if (d < 1) continue;
        if (st == 'hadir' || dayStatus[d] == null) {
          dayStatus[d] = st;
        }
      }
    }

    final now = DateTime.now();
    final year = calendar?.year ?? now.year;
    final month = calendar?.month ?? now.month;
    final daysInMonth = calendar?.daysInMonth ?? DateTime(year, month + 1, 0).day;
    final currentDay = calendar?.todayDay ?? now.day;
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));
    // Monday=1 -> 0 leading empty slots, Sunday=7 -> 6 leading empty slots
    final leadingBlanks = DateTime(year, month, 1).weekday - 1;

    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppColors.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kalender Kehadiran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                    letterSpacing: -0.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                monthLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Day of week headers aligned 1:1 with the 7-column GridView below
          Row(
            children: dayNames.map((name) {
              return Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Proper 7-column aligned calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) {
                return const SizedBox.shrink();
              }
              final dayNumber = index - leadingBlanks + 1;
              final isToday = dayNumber == currentDay;
              final status = dayStatus[dayNumber];
              final isFuture = dayNumber > currentDay;

              Color cellBg;
              Color textColor;
              Border? cellBorder;

              if (status == 'hadir') {
                cellBg = AppColors.success;
                textColor = Colors.white;
              } else if (status == 'izin') {
                cellBg = AppColors.warning;
                textColor = Colors.white;
              } else if (status == 'sakit') {
                cellBg = AppColors.info;
                textColor = Colors.white;
              } else if (status == 'alpa' || status == 'alpha') {
                cellBg = AppColors.danger;
                textColor = Colors.white;
              } else if (isFuture) {
                cellBg = AppColors.background.withOpacity(0.55);
                textColor = AppColors.textQuaternary;
              } else {
                cellBg = AppColors.background;
                textColor = AppColors.textMuted;
              }

              if (isToday) {
                cellBorder =
                    Border.all(color: AppColors.primaryBlue, width: 1.8);
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellBg,
                  borderRadius: BorderRadius.circular(10),
                  border: cellBorder,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: textColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // Legend Bar (wraps gracefully on small screens)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendDot(AppColors.success, 'Hadir'),
              _buildLegendDot(AppColors.warning, 'Izin'),
              _buildLegendDot(AppColors.info, 'Sakit'),
              _buildLegendDot(AppColors.danger, 'Alpa'),
              _buildLegendDot(AppColors.primaryBlue, 'Hari Ini'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color:  AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  //  METRIC HELPERS & FILTERS

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color:  AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 28,
      color:  AppColors.border,
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = filterKey);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ?  AppColors.primaryBlue : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ?  AppColors.primaryBlue :  AppColors.border,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:  AppColors.primaryBlue.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white :  AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
