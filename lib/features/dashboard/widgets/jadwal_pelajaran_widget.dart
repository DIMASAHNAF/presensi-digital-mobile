import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/session_model.dart';
import '../../../core/models/dashboard_full_model.dart';
import '../../../core/theme/app_theme.dart';

//  JADWAL PELAJARAN MINGGUAN — data real dari DB jadwal_pelajarans

class JadwalItemData {
  final String jam;
  final String startStr;
  final String endStr;
  final String mapel;
  final String guru;
  final String ruangan;
  final bool isBreak;
  final String lesLabel;

  const JadwalItemData({
    required this.jam,
    required this.startStr,
    required this.endStr,
    required this.mapel,
    required this.guru,
    required this.ruangan,
    this.isBreak = false,
    required this.lesLabel,
  });

  factory JadwalItemData.fromJadwalItem(JadwalItem item) {
    return JadwalItemData(
      jam: item.jamLabel,
      startStr: item.jamMulai,
      endStr: item.jamSelesai,
      mapel: item.mapel,
      guru: item.guru,
      ruangan: item.ruangan,
      isBreak: item.isBreak,
      lesLabel: item.lesLabel,
    );
  }
}

class JadwalPelajaranWidget extends StatefulWidget {
  final SessionDetail? activeSession;
  final String namaKelas;
  final bool sudahHadir;
  final List<JadwalItem> jadwal;

  const JadwalPelajaranWidget({
    super.key,
    required this.activeSession,
    required this.namaKelas,
    this.sudahHadir = false,
    this.jadwal = const [],
  });

  @override
  State<JadwalPelajaranWidget> createState() => _JadwalPelajaranWidgetState();
}

class _JadwalPelajaranWidgetState extends State<JadwalPelajaranWidget> {
  late int _selectedDayIndex; // 0: Senin, 1: Selasa, 2: Rabu, 3: Kamis, 4: Jumat

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
  ];

  static const List<String> _hariKeys = [
    'senin',
    'selasa',
    'rabu',
    'kamis',
    'jumat',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-select current day of week (Monday=1 -> index 0)
    final weekday = DateTime.now().weekday;
    if (weekday >= 1 && weekday <= 5) {
      _selectedDayIndex = weekday - 1;
    } else {
      _selectedDayIndex = 0; // Default to Senin on weekend
    }
  }

  List<JadwalItemData> _getScheduleForDay(int dayIndex) {
    final key = _hariKeys[dayIndex];
    return widget.jadwal
        .where((j) => j.hari.toLowerCase() == key)
        .map((j) => JadwalItemData.fromJadwalItem(j))
        .toList();
  }

  bool _isItemActive(JadwalItemData item, bool isToday) {
    if (!isToday) return false;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;

    try {
      final startParts = item.startStr.split(':').map(int.parse).toList();
      final endParts = item.endStr.split(':').map(int.parse).toList();
      final startMin = startParts[0] * 60 + startParts[1];
      final endMin = endParts[0] * 60 + endParts[1];

      return nowMin >= startMin && nowMin < endMin;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nowWeekday = DateTime.now().weekday;
    final isTodaySelected = (nowWeekday >= 1 && nowWeekday <= 5) && (_selectedDayIndex == nowWeekday - 1);
    final items = _getScheduleForDay(_selectedDayIndex);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppColors.cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title & Class Tag (overflow-safe)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Pelajaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Roster kelas aktif',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.namaKelas,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          //  Horizontal Day Selector Capsules (Senin - Jumat)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_dayNames.length, (idx) {
                final isSelected = _selectedDayIndex == idx;
                final isActualToday = (nowWeekday >= 1 && nowWeekday <= 5) && (idx == nowWeekday - 1);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDayIndex = idx);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ?  AppColors.primaryBlue
                            : (isActualToday ?  AppColors.infoBg :  AppColors.background),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ?  AppColors.primaryBlue
                              : (isActualToday ?  AppColors.info :  AppColors.border),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActualToday) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.surface :  AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            _dayNames[idx],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isActualToday ?  AppColors.primaryBlue :  AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          //  Timeline List of Periods
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color:  AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color:  AppColors.border),
              ),
              child: Column(
                children: [
                   Icon(Icons.event_busy_rounded,
                      size: 26, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada jadwal pelajaran',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final it = items[index];
              final isActive = _isItemActive(it, isTodaySelected);

              if (it.isBreak) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color:  AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color:  AppColors.border),
                  ),
                  child: Row(
                    children: [
                       Icon(
                        Icons.coffee_rounded,
                        size: 15,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        it.jam,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:  AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          it.mapel,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color:  AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.successBg : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? AppColors.successBorder
                        : AppColors.border.withOpacity(0.55),
                    width: isActive ? 1.2 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    // Time and Les badge
                    Container(
                      width: 88,
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            it.lesLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            it.jam,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Mapel & Guru details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.mapel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? AppColors.success
                                        : AppColors.textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Aktif',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else if (widget.sudahHadir && isTodaySelected)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Hadir',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  it.guru,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room_outlined,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  it.ruangan,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
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
}
