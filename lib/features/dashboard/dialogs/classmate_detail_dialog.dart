import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/dashboard_full_model.dart';

class ClassmateDetailDialog extends StatelessWidget {
  final ClassmateModel classmate;
  final String kelasNama;

  const ClassmateDetailDialog({
    super.key,
    required this.classmate,
    required this.kelasNama,
  });

  static const String _storageBase =
      'https://presensi.smknegeri1beringin.sch.id/storage/';

  static Future<void> show(
    BuildContext context, {
    required ClassmateModel classmate,
    required String kelasNama,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClassmateDetailDialog(
        classmate: classmate,
        kelasNama: kelasNama,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHadir = classmate.statusHariIni.toLowerCase() == 'hadir';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── iOS Drag Handle ──
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),

          // ── Avatar with Presence Ring ──
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isHadir ? const Color(0xFF34C759) : const Color(0xFFE5E5EA),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: (classmate.avatar != null && classmate.avatar!.isNotEmpty)
                  ? Image.network(
                      '$_storageBase${classmate.avatar}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallback(),
                    )
                  : _buildFallback(),
            ),
          ),

          const SizedBox(height: 14),

          // ── Name & Status ──
          Text(
            classmate.nama,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isHadir ? const Color(0xFFE8F8ED) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isHadir
                        ? const Color(0xFF34C759)
                        : const Color(0xFF8E8E93),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isHadir ? 'Hadir Hari Ini' : 'Belum Hadir',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isHadir
                        ? const Color(0xFF248A3D)
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── iOS Inset Grouped Section ──
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildRow(
                  icon: CupertinoIcons.person_2_fill,
                  label: 'Kelas',
                  value: kelasNama,
                ),
                const Divider(height: 1, indent: 48, color: Color(0xFFE5E5EA)),
                _buildRow(
                  icon: CupertinoIcons.number,
                  label: 'NISN',
                  value: classmate.nisn,
                ),
                if (classmate.username.isNotEmpty) ...[
                  const Divider(height: 1, indent: 48, color: Color(0xFFE5E5EA)),
                  _buildRow(
                    icon: CupertinoIcons.at,
                    label: 'Username',
                    value: '@${classmate.username}',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Close Button (Cupertino) ──
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8E8E93)),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF8E8E93),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF007AFF),
      alignment: Alignment.center,
      child: Text(
        classmate.nama.isNotEmpty ? classmate.nama[0] : 'S',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
