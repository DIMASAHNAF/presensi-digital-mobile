import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/dashboard_full_model.dart';
import '../dialogs/classmate_detail_dialog.dart';
import '../../../core/theme/app_theme.dart';

class TemanTab extends StatefulWidget {
  final DashboardFullModel data;

  const TemanTab({super.key, required this.data});

  @override
  State<TemanTab> createState() => _TemanTabState();
}

class _TemanTabState extends State<TemanTab> {
  String _selectedFilter = 'Semua';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const String _storageBase =
      'https://presensi.smknegeri1beringin.sch.id/storage/';

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classmates = widget.data.temanSekelas;
    final user = widget.data.user;

    final hadirCount = classmates.where((c) => c.statusHariIni.toLowerCase() == 'hadir').length;
    final belumCount = classmates.length - hadirCount;
    final attendanceRatio = classmates.isNotEmpty ? hadirCount / classmates.length : 0.0;

    final filtered = classmates.where((cm) {
      if (_selectedFilter == 'Hadir' && cm.statusHariIni.toLowerCase() != 'hadir') {
        return false;
      }
      if (_selectedFilter == 'Belum Hadir' && cm.statusHariIni.toLowerCase() == 'hadir') {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = cm.name.toLowerCase().contains(q);
        final userMatch = cm.username.toLowerCase().contains(q);
        final bioMatch = (cm.bio ?? '').toLowerCase().contains(q);
        return nameMatch || userMatch || bioMatch;
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
          //  1. LIVE CLASS ATTENDANCE RADAR HEADER
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KEHADIRAN KELAS HARI INI',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color:  AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.kelas,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color:  AppColors.primaryDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:  AppColors.infoBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color:  AppColors.infoBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(
                            CupertinoIcons.person_2_fill,
                            size: 15,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${classmates.length} Siswa',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color:  AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Live Presence Ratio Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        if (hadirCount > 0)
                          Expanded(
                            flex: hadirCount,
                            child: Container(color:  AppColors.success),
                          ),
                        if (belumCount > 0)
                          Expanded(
                            flex: belumCount,
                            child: Container(color:  AppColors.border),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration:  BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$hadirCount Hadir di Sekolah (${(attendanceRatio * 100).toInt()}%)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:  AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$belumCount Belum Hadir',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:  AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),

          const SizedBox(height: 14),

          //  2. SEARCH FIELD
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
                hintText: 'Cari teman sekelas...',
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

          //  3. Filter chips (full-width mobile layout)
          Row(
            children: [
              Expanded(
                child: _buildFilterChip('Semua (${classmates.length})', 'Semua'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Hadir ($hadirCount)', 'Hadir'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Belum Hadir ($belumCount)', 'Belum Hadir'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          //  4. CLASSMATES LIST
          if (filtered.isEmpty)
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
                      CupertinoIcons.person_2,
                      size: 26,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada teman yang cocok',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color:  AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color:  AppColors.border, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color:  AppColors.shadow.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                     Divider(height: 1, indent: 70, color: AppColors.background),
                itemBuilder: (context, index) {
                  final cm = filtered[index];
                  final isHadir = cm.statusHariIni.toLowerCase() == 'hadir';

                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ClassmateDetailDialog.show(
                        context,
                        classmate: cm,
                        kelasNama: user.kelas,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          //  Clean Circular Avatar (Tanpa Titik Ganda)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:  AppColors.background,
                              border: Border.all(color:  AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              child: (cm.avatar != null && cm.avatar!.isNotEmpty)
                                  ? Image.network(
                                      '$_storageBase${cm.avatar}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          cm.initials,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color:  AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        cm.initials,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color:  AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Name (Title Case) & NISN (Tanpa @)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _toTitleCase(cm.name),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color:  AppColors.primaryDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NISN • ${cm.username}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color:  AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isHadir ?  AppColors.successBg :  AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isHadir ?  AppColors.successBorder :  AppColors.border,
                              ),
                            ),
                            child: Text(
                              isHadir
                                  ? (cm.jamAbsen != null && cm.jamAbsen!.isNotEmpty
                                      ? 'Hadir ${cm.jamAbsen}'
                                      : 'Hadir ')
                                  : 'Belum Hadir',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isHadir ?  AppColors.success :  AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ?  AppColors.primaryBlue : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ?  AppColors.primaryBlue :  AppColors.border,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:  AppColors.primaryBlue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white :  AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
