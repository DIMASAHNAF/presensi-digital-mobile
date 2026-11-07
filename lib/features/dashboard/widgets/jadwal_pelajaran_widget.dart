import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/session_model.dart';
import '../../../core/theme/app_theme.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  JADWAL PELAJARAN HARI INI — Interactive Student Timetable
//  Apple Calendar / Reminders Inset Grouped Timeline
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class JadwalPelajaranWidget extends StatelessWidget {
  final SessionDetail? activeSession;
  final String namaKelas;

  const JadwalPelajaranWidget({
    super.key,
    required this.activeSession,
    required this.namaKelas,
  });

  @override
  Widget build(BuildContext context) {
    // Standard schedule timetable for SMKN 1 Beringin (vocational software engineering)
    final items = [
      (
        jam: '07:15 - 08:35',
        mapel: activeSession?.namaMapel ?? 'Kewirausahaan (KWU)',
        guru: activeSession?.guruNama.isNotEmpty == true ? activeSession!.guruNama : 'Budi Santoso, S.Pd',
        ruangan: 'Lab RPL 2',
        isBreak: false,
        isCurrent: activeSession != null,
      ),
      (
        jam: '08:35 - 09:55',
        mapel: 'Pemrograman Web & Perangkat Bergerak',
        guru: 'Fajar Shidiq, M.Kom',
        ruangan: 'Lab RPL 2',
        isBreak: false,
        isCurrent: false,
      ),
      (
        jam: '09:55 - 10:15',
        mapel: 'Istirahat Pagi (Kantin & Relaksasi)',
        guru: '',
        ruangan: 'Area Kampus',
        isBreak: true,
        isCurrent: false,
      ),
      (
        jam: '10:15 - 11:45',
        mapel: 'Basis Data & SQL Server',
        guru: 'Dewi Lestari, S.Kom',
        ruangan: 'Lab RPL 1',
        isBreak: false,
        isCurrent: false,
      ),
      (
        jam: '11:45 - 12:45',
        mapel: 'Istirahat Siang & Sholat Dzuhur',
        guru: '',
        ruangan: 'Masjid Sekolah',
        isBreak: true,
        isCurrent: false,
      ),
      (
        jam: '12:45 - 14:15',
        mapel: 'Bahasa Inggris Terapan Kejuruan',
        guru: 'Siti Rahma, S.Pd',
        ruangan: 'Kelas Teori 3',
        isBreak: false,
        isCurrent: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      size: 16,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'JADWAL PELAJARAN HARI INI',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
              Text(
                namaKelas,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timeline items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final it = items[index];

              if (it.isBreak) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('☕', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 10),
                      Text(
                        it.jam,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          it.mapel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6C6C70),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: it.isCurrent ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: it.isCurrent ? const Color(0xFFBBF7D0) : const Color(0xFFE5E5EA),
                    width: it.isCurrent ? 1.2 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    // Time block
                    Container(
                      width: 85,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                      decoration: BoxDecoration(
                        color: it.isCurrent ? const Color(0xFFDCFCE7) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        it.jam,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: it.isCurrent ? const Color(0xFF15803D) : const Color(0xFF3C3C43),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Mapel & Guru
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
                                    color: it.isCurrent ? const Color(0xFF15803D) : AppColors.textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (it.isCurrent)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'AKTIF',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${it.guru} • ${it.ruangan}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
