import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/dashboard_full_model.dart';

class KehadiranTab extends StatefulWidget {
  final DashboardFullModel data;

  const KehadiranTab({super.key, required this.data});

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
      padding: const EdgeInsets.only(left: 18, right: 18, top: 4, bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. APPLE HEALTH STAT CARD ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
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
                      'TOTAL KEHADIRAN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8E8E93),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      widget.data.user.kelas,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF007AFF),
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
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF34C759),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Rasio kehadiran terverifikasi untuk seluruh sesi belajar aktif.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8E8E93),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Apple Activity Segmented Bar (Proportional) ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 7,
                    child: Row(
                      children: [
                        if (stats.hadir > 0)
                          Expanded(
                            flex: stats.hadir,
                            child: Container(color: const Color(0xFF34C759)),
                          ),
                        if (stats.izin > 0)
                          Expanded(
                            flex: stats.izin,
                            child: Container(color: const Color(0xFFFF9500)),
                          ),
                        if (stats.sakit > 0)
                          Expanded(
                            flex: stats.sakit,
                            child: Container(color: const Color(0xFF5856D6)),
                          ),
                        if (stats.alpa > 0)
                          Expanded(
                            flex: stats.alpa,
                            child: Container(color: const Color(0xFFFF3B30)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── 4 Crisp Apple Metric Columns (NO PASTEL BOXES) ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAppleMetric('Hadir', '${stats.hadir}', const Color(0xFF34C759)),
                    _buildAppleDivider(),
                    _buildAppleMetric('Izin', '${stats.izin}', const Color(0xFFFF9500)),
                    _buildAppleDivider(),
                    _buildAppleMetric('Sakit', '${stats.sakit}', const Color(0xFF5856D6)),
                    _buildAppleDivider(),
                    _buildAppleMetric('Alpa', '${stats.alpa}', const Color(0xFFFF3B30)),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          // ── 2. iOS SEARCH FIELD ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Cari mata pelajaran, guru, atau tanggal...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF8E8E93),
                ),
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  size: 18,
                  color: Color(0xFF8E8E93),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          CupertinoIcons.clear_thick_circled,
                          size: 16,
                          color: Color(0xFF8E8E93),
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

          const SizedBox(height: 14),

          // ── 3. iOS FILTER CAPSULES ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('Semua (${riwayatRaw.length})', 'Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Hadir', 'Hadir'),
                const SizedBox(width: 8),
                _buildFilterChip('Izin', 'Izin'),
                const SizedBox(width: 8),
                _buildFilterChip('Sakit', 'Sakit'),
                const SizedBox(width: 8),
                _buildFilterChip('Alpa', 'Alpa'),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── 4. RIWAYAT LIST ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RIWAYAT PRESENSI',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF8E8E93),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${filteredList.length} sesi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF007AFF),
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
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      CupertinoIcons.tray,
                      size: 26,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada catatan presensi',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF8E8E93),
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
                final status =
                    (item['status'] ?? 'hadir').toString().toLowerCase();

                Color badgeColor;
                Color badgeBg;
                String statusLabel;

                if (status == 'hadir') {
                  badgeColor = const Color(0xFF34C759);
                  badgeBg = const Color(0xFFE8F8ED);
                  statusLabel = 'HADIR';
                } else if (status == 'izin') {
                  badgeColor = const Color(0xFFFF9500);
                  badgeBg = const Color(0xFFFFF4E6);
                  statusLabel = 'IZIN';
                } else if (status == 'sakit') {
                  badgeColor = const Color(0xFF5856D6);
                  badgeBg = const Color(0xFFF2F1FD);
                  statusLabel = 'SAKIT';
                } else {
                  badgeColor = const Color(0xFFFF3B30);
                  badgeBg = const Color(0xFFFFEBEB);
                  statusLabel = 'ALPA';
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['mapel'] ?? item['keterangan'] ?? 'Presensi Pembelajaran',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item['tanggal'] ?? '-'} • ${item['jam'] ?? '-'} WIB',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
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

  Widget _buildAppleDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFE5E5EA),
    );
  }

  Widget _buildAppleMetric(String label, String value, Color dotColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF000000),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = value);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}
