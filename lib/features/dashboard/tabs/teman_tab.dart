import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/dashboard_full_model.dart';
import '../dialogs/classmate_detail_dialog.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classmates = widget.data.temanSekelas;
    final user = widget.data.user;

    final filtered = classmates.where((cm) {
      if (_selectedFilter == 'Hadir' &&
          cm.statusHariIni.toLowerCase() != 'hadir') {
        return false;
      }
      if (_selectedFilter == 'Belum Hadir' &&
          cm.statusHariIni.toLowerCase() == 'hadir') {
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
      padding: const EdgeInsets.only(left: 18, right: 18, top: 4, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. HEADER CARD ──
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KOMUNITAS KELAS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8E8E93),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.kelas,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_2_fill,
                        size: 16,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${classmates.length} Siswa',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),

          const SizedBox(height: 14),

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
                hintText: 'Cari teman sekelas...',
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

          const SizedBox(height: 12),

          // ── 3. iOS FILTER CHIPS ──
          Row(
            children: [
              _buildFilterChip('Semua (${classmates.length})', 'Semua'),
              const SizedBox(width: 8),
              _buildFilterChip('Hadir', 'Hadir'),
              const SizedBox(width: 8),
              _buildFilterChip('Belum Hadir', 'Belum Hadir'),
            ],
          ),

          const SizedBox(height: 16),

          // ── 4. CLASSMATES LIST (iOS Contacts Group) ──
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
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_2,
                      size: 26,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada teman yang cocok',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
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
                    const Divider(height: 1, indent: 68, color: Color(0xFFF2F2F7)),
                itemBuilder: (context, idx) {
                  final c = filtered[idx];
                  final isHadir = c.statusHariIni.toLowerCase() == 'hadir';

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ClassmateDetailDialog.show(
                        context,
                        classmate: c,
                        kelasNama: user.kelas,
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Avatar
                          Stack(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isHadir
                                        ? const Color(0xFF34C759)
                                        : const Color(0xFFE5E5EA),
                                    width: isHadir ? 2 : 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: (c.avatar != null &&
                                          c.avatar!.isNotEmpty)
                                      ? Image.network(
                                          '$_storageBase${c.avatar}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildFallback(c),
                                        )
                                      : _buildFallback(c),
                                ),
                              ),
                              if (isHadir)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34C759),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(width: 14),

                          // Name & Username
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.nama,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${c.username.isNotEmpty ? c.username : c.nisn}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isHadir
                                  ? const Color(0xFFE8F8ED)
                                  : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isHadir ? 'Hadir' : 'Belum Hadir',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isHadir
                                    ? const Color(0xFF248A3D)
                                    : const Color(0xFF8E8E93),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

  Widget _buildFallback(ClassmateModel c) {
    return Container(
      color: const Color(0xFFF2F2F7),
      alignment: Alignment.center,
      child: Text(
        c.nama.isNotEmpty ? c.nama[0] : 'S',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8E8E93),
        ),
      ),
    );
  }
}
