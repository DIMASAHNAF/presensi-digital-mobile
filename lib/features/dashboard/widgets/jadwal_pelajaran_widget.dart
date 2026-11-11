import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/session_model.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  JADWAL PELAJARAN HARI INI & MINGGUAN (XI PPLG 3 / XI-RPL 3)
//  Sinkronisasi Penuh Roster Resmi Semester Ganjil & Jam Bel Sekolah
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
}

class JadwalPelajaranWidget extends StatefulWidget {
  final SessionDetail? activeSession;
  final String namaKelas;
  final bool sudahHadir;

  const JadwalPelajaranWidget({
    super.key,
    required this.activeSession,
    required this.namaKelas,
    this.sudahHadir = false,
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

  // ── Master Weekly Timetable for XI PPLG 3 (XI-RPL 3) ──
  // Source: Roster Semester Ganjil SMKN 1 Beringin 2026/2027 & Bell Timings JSON
  List<JadwalItemData> _getScheduleForDay(int dayIndex) {
    switch (dayIndex) {
      // ── 1. SENIN (Upacara Bendera Day) ──
      case 0:
        return const [
          JadwalItemData(
            jam: '07:15 - 08:30',
            startStr: '07:15',
            endStr: '08:30',
            mapel: 'Upacara Bendera',
            guru: 'Seluruh Guru & Pembina',
            ruangan: 'Lapangan Utama',
            isBreak: false,
            lesLabel: 'Les 1',
          ),
          JadwalItemData(
            jam: '08:30 - 09:05',
            startStr: '08:30',
            endStr: '09:05',
            mapel: 'Basis Data',
            guru: 'Yulis, S.Kom [YS]',
            ruangan: 'Lab RPL 2',
            isBreak: false,
            lesLabel: 'Les 2',
          ),
          JadwalItemData(
            jam: '09:05 - 09:40',
            startStr: '09:05',
            endStr: '09:40',
            mapel: 'Basis Data',
            guru: 'Yulis, S.Kom [YS]',
            ruangan: 'Lab RPL 2',
            isBreak: false,
            lesLabel: 'Les 3',
          ),
          JadwalItemData(
            jam: '09:40 - 10:15',
            startStr: '09:40',
            endStr: '10:15',
            mapel: 'Pemrograman Mobile',
            guru: 'Dian Nugraha, S.Kom [DN]',
            ruangan: 'Lab RPL 2',
            isBreak: false,
            lesLabel: 'Les 4',
          ),
          JadwalItemData(
            jam: '10:15 - 10:50',
            startStr: '10:15',
            endStr: '10:50',
            mapel: 'Pemrograman Mobile',
            guru: 'Dian Nugraha, S.Kom [DN]',
            ruangan: 'Lab RPL 2',
            isBreak: false,
            lesLabel: 'Les 5',
          ),
          JadwalItemData(
            jam: '10:50 - 11:05',
            startStr: '10:50',
            endStr: '11:05',
            mapel: 'Istirahat Pagi (Kantin & Bersih Kelas)',
            guru: '',
            ruangan: 'Area Kampus',
            isBreak: true,
            lesLabel: 'IST 1',
          ),
          JadwalItemData(
            jam: '11:05 - 11:40',
            startStr: '11:05',
            endStr: '11:40',
            mapel: 'Teks-Grafis & Multimedia',
            guru: 'Yulis, S.Kom [YS]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 6',
          ),
          JadwalItemData(
            jam: '11:40 - 12:15',
            startStr: '11:40',
            endStr: '12:15',
            mapel: 'Teks-Grafis & Multimedia',
            guru: 'Yulis, S.Kom [YS]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 7',
          ),
          JadwalItemData(
            jam: '12:15 - 14:00',
            startStr: '12:15',
            endStr: '14:00',
            mapel: 'Istirahat Siang & Sholat Dzuhur',
            guru: '',
            ruangan: 'Masjid Sekolah',
            isBreak: true,
            lesLabel: 'IST 2',
          ),
          JadwalItemData(
            jam: '14:00 - 14:30',
            startStr: '14:00',
            endStr: '14:30',
            mapel: 'Teks-Grafis & Multimedia',
            guru: 'Yulis, S.Kom [YS]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 8',
          ),
          JadwalItemData(
            jam: '14:30 - 15:00',
            startStr: '14:30',
            endStr: '15:00',
            mapel: 'Teks-Grafis & Multimedia',
            guru: 'Yulis, S.Kom [YS]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 9',
          ),
          JadwalItemData(
            jam: '15:00 - 15:50',
            startStr: '15:00',
            endStr: '15:50',
            mapel: 'Pendidikan Jasmani & Olahraga (PJOK)',
            guru: 'Fajar Putra, S.Pd [FP]',
            ruangan: 'Lapangan Olahraga',
            isBreak: false,
            lesLabel: 'Les 10-11',
          ),
        ];

      // ── 2. SELASA ──
      case 1:
        return const [
          JadwalItemData(
            jam: '07:15 - 08:27',
            startStr: '07:15',
            endStr: '08:27',
            mapel: 'Pendidikan Pancasila',
            guru: 'Purwanto, S.Pd [PW]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 1-2',
          ),
          JadwalItemData(
            jam: '08:27 - 09:39',
            startStr: '08:27',
            endStr: '09:39',
            mapel: 'Bahasa Inggris',
            guru: 'Wahyuni Rahayu, S.Pd [WR]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 3-4',
          ),
          JadwalItemData(
            jam: '09:39 - 10:15',
            startStr: '09:39',
            endStr: '10:15',
            mapel: 'Bahasa Indonesia',
            guru: 'M. Syarif, S.Pd [MS]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 5',
          ),
          JadwalItemData(
            jam: '10:15 - 10:32',
            startStr: '10:15',
            endStr: '10:32',
            mapel: 'Istirahat Pagi (Kantin & Relaksasi)',
            guru: '',
            ruangan: 'Area Kampus',
            isBreak: true,
            lesLabel: 'IST 1',
          ),
          JadwalItemData(
            jam: '10:32 - 11:44',
            startStr: '10:32',
            endStr: '11:44',
            mapel: 'Bahasa Indonesia',
            guru: 'M. Syarif, S.Pd [MS]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 6-7',
          ),
          JadwalItemData(
            jam: '11:44 - 12:20',
            startStr: '11:44',
            endStr: '12:20',
            mapel: 'Pemrograman Mobile (Praktik)',
            guru: 'Dian Nugraha, S.Kom [DN]',
            ruangan: 'Lab RPL 2',
            isBreak: false,
            lesLabel: 'Les 8',
          ),
          JadwalItemData(
            jam: '12:20 - 14:00',
            startStr: '12:20',
            endStr: '14:00',
            mapel: 'Istirahat Siang & Sholat Dzuhur',
            guru: '',
            ruangan: 'Masjid Sekolah',
            isBreak: true,
            lesLabel: 'IST 2',
          ),
          JadwalItemData(
            jam: '14:00 - 15:50',
            startStr: '14:00',
            endStr: '15:50',
            mapel: 'Pemrograman Mobile (Praktik)',
            guru: 'Dian Nugraha, S.Kom [DN]',
            ruangan: 'Lab RPL 2',
            isBreak: false,
            lesLabel: 'Les 9-11',
          ),
        ];

      // ── 3. RABU ──
      case 2:
        return const [
          JadwalItemData(
            jam: '07:15 - 09:03',
            startStr: '07:15',
            endStr: '09:03',
            mapel: 'Matematika Terapan',
            guru: 'Evi Elida, S.Pd [EE]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 1-3',
          ),
          JadwalItemData(
            jam: '09:03 - 10:15',
            startStr: '09:03',
            endStr: '10:15',
            mapel: 'Pendidikan Agama & Budi Pekerti',
            guru: 'Pendi, S.Ag [PN]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 4-5',
          ),
          JadwalItemData(
            jam: '10:15 - 10:32',
            startStr: '10:15',
            endStr: '10:32',
            mapel: 'Istirahat Pagi (Kantin & Relaksasi)',
            guru: '',
            ruangan: 'Area Kampus',
            isBreak: true,
            lesLabel: 'IST 1',
          ),
          JadwalItemData(
            jam: '10:32 - 11:08',
            startStr: '10:32',
            endStr: '11:08',
            mapel: 'Pendidikan Agama & Budi Pekerti',
            guru: 'Pendi, S.Ag [PN]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 6',
          ),
          JadwalItemData(
            jam: '11:08 - 12:20',
            startStr: '11:08',
            endStr: '12:20',
            mapel: 'Sejarah Indonesia',
            guru: 'Mardiana, S.Pd [MD]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 7-8',
          ),
          JadwalItemData(
            jam: '12:20 - 14:00',
            startStr: '12:20',
            endStr: '14:00',
            mapel: 'Istirahat Siang & Sholat Dzuhur',
            guru: '',
            ruangan: 'Masjid Sekolah',
            isBreak: true,
            lesLabel: 'IST 2',
          ),
          JadwalItemData(
            jam: '14:00 - 15:50',
            startStr: '14:00',
            endStr: '15:50',
            mapel: 'Konsentrasi Keahlian / Koding Industri (KIN)',
            guru: 'Dian Nugraha, S.Kom [DN]',
            ruangan: 'Lab RPL 2',
            isBreak: false,
            lesLabel: 'Les 9-11',
          ),
        ];

      // ── 4. KAMIS ──
      case 3:
        return const [
          JadwalItemData(
            jam: '07:15 - 09:59',
            startStr: '07:15',
            endStr: '09:59',
            mapel: 'Koding & Algoritma (KA)',
            guru: 'Dian Nugraha, S.Kom [DN]',
            ruangan: 'Lab RPL 2',
            isBreak: false,
            lesLabel: 'Les 1-4',
          ),
          JadwalItemData(
            jam: '09:59 - 10:17',
            startStr: '09:59',
            endStr: '10:17',
            mapel: 'Istirahat Pagi (Kantin & Relaksasi)',
            guru: '',
            ruangan: 'Area Kampus',
            isBreak: true,
            lesLabel: 'IST 1',
          ),
          JadwalItemData(
            jam: '10:17 - 11:39',
            startStr: '10:17',
            endStr: '11:39',
            mapel: 'Bahasa Inggris Kejuruan',
            guru: 'Wahyuni Rahayu, S.Pd [WR]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 5-6',
          ),
          JadwalItemData(
            jam: '11:39 - 12:20',
            startStr: '11:39',
            endStr: '12:20',
            mapel: 'Pemrograman Web (Frontend & Backend)',
            guru: 'Lutfi W, S.Kom [LW]',
            ruangan: 'Lab RPL 1',
            isBreak: false,
            lesLabel: 'Les 7',
          ),
          JadwalItemData(
            jam: '12:20 - 14:00',
            startStr: '12:20',
            endStr: '14:00',
            mapel: 'Istirahat Siang & Sholat Dzuhur',
            guru: '',
            ruangan: 'Masjid Sekolah',
            isBreak: true,
            lesLabel: 'IST 2',
          ),
          JadwalItemData(
            jam: '14:00 - 15:50',
            startStr: '14:00',
            endStr: '15:50',
            mapel: 'Pemrograman Web (Frontend & Backend)',
            guru: 'Lutfi W, S.Kom [LW]',
            ruangan: 'Lab RPL 1',
            isBreak: false,
            lesLabel: 'Les 8-10',
          ),
        ];

      // ── 5. JUMAT ──
      case 4:
      default:
        return const [
          JadwalItemData(
            jam: '07:00 - 07:45',
            startStr: '07:00',
            endStr: '07:45',
            mapel: 'Senam Anak Indonesia Hebat & Jumat Bersih',
            guru: 'Guru Pembina & OSIS',
            ruangan: 'Lapangan Utama',
            isBreak: true,
            lesLabel: 'Pembiasaan',
          ),
          JadwalItemData(
            jam: '07:45 - 09:05',
            startStr: '07:45',
            endStr: '09:05',
            mapel: 'Kewirausahaan (KWU)',
            guru: 'Budi Santoso, S.Pd [DJ]',
            ruangan: 'Ruang Teori XI PPLG 3',
            isBreak: false,
            lesLabel: 'Les 1-2',
          ),
          JadwalItemData(
            jam: '09:05 - 10:25',
            startStr: '09:05',
            endStr: '10:25',
            mapel: 'Pemrograman Web',
            guru: 'Lutfi W, S.Kom [LW]',
            ruangan: 'Lab RPL 1',
            isBreak: false,
            lesLabel: 'Les 3-4',
          ),
          JadwalItemData(
            jam: '10:25 - 10:40',
            startStr: '10:25',
            endStr: '10:40',
            mapel: 'ISHM (Istirahat & Membuang Sampah)',
            guru: '',
            ruangan: 'Area Kampus',
            isBreak: true,
            lesLabel: 'ISHM',
          ),
          JadwalItemData(
            jam: '10:40 - 12:00',
            startStr: '10:40',
            endStr: '12:00',
            mapel: 'Desain Antarmuka Pengguna (UI/UX)',
            guru: 'Lutfi W, S.Kom [LW]',
            ruangan: 'Lab RPL 1',
            isBreak: false,
            lesLabel: 'Les 5-6',
          ),
          JadwalItemData(
            jam: '12:00 - 13:45',
            startStr: '12:00',
            endStr: '13:45',
            mapel: 'Pengembangan Mandiri Berbasis Agama / Shalat Jumat',
            guru: 'Guru Agama & Takmir',
            ruangan: 'Masjid Sekolah',
            isBreak: true,
            lesLabel: 'Ibadah',
          ),
          JadwalItemData(
            jam: '14:00 - 16:00',
            startStr: '14:00',
            endStr: '16:00',
            mapel: 'Kegiatan Ekstrakurikuler Kejuruan & Minat',
            guru: 'Pembina Ekskul',
            ruangan: 'Area Kampus',
            isBreak: false,
            lesLabel: 'Ekskul',
          ),
        ];
    }
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title & Class Tag ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      size: 17,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROSTER MAPEL RESMI',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Semester Ganjil 2026/2027',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 12,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.namaKelas,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Horizontal Day Selector Capsules (Senin - Jumat) ──
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
                            ? const Color(0xFF2563EB)
                            : (isActualToday ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isActualToday ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                          width: 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.25),
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
                                color: isSelected ? Colors.white : const Color(0xFF2563EB),
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
                                  : (isActualToday ? const Color(0xFF1D4ED8) : const Color(0xFF475569)),
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

          // ── Timeline List of Periods ──
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
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.coffee_rounded,
                        size: 15,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        it.jam,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          it.mapel,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
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
                  color: isActive ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                    width: isActive ? 1.5 : 1.0,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Time and Les badge
                    Container(
                      width: 90,
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            it.lesLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: isActive ? const Color(0xFF15803D) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            it.jam,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive ? const Color(0xFF15803D) : const Color(0xFF0F172A),
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isActive ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'AKTIF',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else if (widget.sudahHadir && isTodaySelected)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Text(
                                    'Otomatis Hadir ✓',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  it.guru,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
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
                              const Icon(
                                Icons.meeting_room_outlined,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                it.ruangan,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFF94A3B8),
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
