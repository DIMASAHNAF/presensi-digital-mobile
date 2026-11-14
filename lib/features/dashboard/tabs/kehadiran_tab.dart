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
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color:  AppColors.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color:  AppColors.shadow.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL KEHADIRAN SISWA',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color:  AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      widget.data.user.kelas,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:  AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${stats.persentase}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: stats.persentase >= 75
                            ?  AppColors.success
                            :  AppColors.danger,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Rasio kehadiran terverifikasi untuk seluruh sesi belajar aktif semester ini.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color:  AppColors.textMuted,
                          height: 1.35,
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
                         Icon(
                          CupertinoIcons.doc_text_search,
                          size: 15,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Lihat Rekap Lengkap Presensi →',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:  AppColors.primaryBlue,
                          ),
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

  //  2. DAPODIK SAFETY GAUGE CARD

  Widget _buildDapodikSafetyCard(StatsModel stats) {
    final isSafe = stats.persentase >= 75;
    // Calculate tolerance days: 25% of 60 days semester ~ 15 days max absence
    final totalAbsence = stats.izin + stats.sakit + stats.alpa;
    final maxAllowed = (stats.total > 0 ? (stats.total * 0.25).toInt() : 5);
    final remainingTolerance = (maxAllowed - totalAbsence).clamp(0, 30);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isSafe ?  AppColors.successBg :  AppColors.dangerBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSafe ?  AppColors.successBorder :  AppColors.dangerBg,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isSafe ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                    size: 18,
                    color: isSafe ?  AppColors.success :  AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STANDAR MINIMAL DAPODIK (75%)',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isSafe ?  AppColors.success :  AppColors.danger,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSafe ?  AppColors.successBg :  AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSafe ?  AppColors.successBorder :  AppColors.dangerBorder,
                  ),
                ),
                child: Text(
                  isSafe ? 'STATUS AMAN ' : 'BATAS RAWAN ',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isSafe ?  AppColors.success :  AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSafe
                ? 'Tingkat kehadiranmu aman untuk mengikuti Penilaian Akhir Semester (PAS). Pertahankan disiplin kehadiran pagimu!'
                : 'Perhatian: Kehadiranmu berada di bawah batas minimum 75% Dapodik. Segera penuhi kehadiran di sesi berikutnya agar memenuhi syarat ujian.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isSafe ?  AppColors.success :  AppColors.danger,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSafe ?  AppColors.successBorder :  AppColors.dangerBg,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sisa Toleransi Izin/Sakit Semester Ini:',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color:  AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$remainingTolerance Hari Lagi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSafe ?  AppColors.success :  AppColors.danger,
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
    final daysInMonth = calendar?.daysInMonth ?? now.day;
    final currentDay = calendar?.todayDay ?? now.day;
    final monthLabel = calendar != null
        ? DateFormat('MMMM yyyy', 'id_ID')
            .format(DateTime(calendar.year, calendar.month))
        : DateFormat('MMMM yyyy', 'id_ID').format(now);

    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color:  AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color:  AppColors.shadow.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:  AppColors.infoBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:  Icon(
                      CupertinoIcons.calendar,
                      size: 15,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'KALENDER KEHADIRAN',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color:  AppColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Text(
                monthLabel,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color:  AppColors.primaryBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Day of week labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dayNames.map((name) {
              return SizedBox(
                width: 34,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color:  AppColors.textMuted,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Calendar Grid
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(daysInMonth, (index) {
              final dayNumber = index + 1;
              final isToday = dayNumber == currentDay;
              final status = dayStatus[dayNumber];
              final isFuture = dayNumber > currentDay;

              Color cellBg;
              Color textColor;
              Border? cellBorder;

              if (status == 'hadir') {
                cellBg =  AppColors.success;
                textColor = Colors.white;
              } else if (status == 'izin') {
                cellBg =  AppColors.warning;
                textColor = Colors.white;
              } else if (status == 'sakit') {
                cellBg =  AppColors.info;
                textColor = Colors.white;
              } else if (status == 'alpa' || status == 'alpha') {
                cellBg =  AppColors.danger;
                textColor = Colors.white;
              } else if (isFuture) {
                cellBg =  AppColors.background;
                textColor =  AppColors.textQuaternary;
                cellBorder = Border.all(color:  AppColors.background);
              } else {
                cellBg =  AppColors.background;
                textColor =  AppColors.textMuted;
              }

              if (isToday) {
                cellBorder = Border.all(color:  AppColors.primaryBlue, width: 2.0);
              }

              return Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cellBg,
                  borderRadius: BorderRadius.circular(10),
                  border: cellBorder,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Legend Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendDot( AppColors.success, 'Hadir'),
              _buildLegendDot( AppColors.warning, 'Izin'),
              _buildLegendDot( AppColors.info, 'Sakit'),
              _buildLegendDot( AppColors.danger, 'Alpa'),
              _buildLegendDot( AppColors.primaryBlue, 'Hari Ini'),
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
