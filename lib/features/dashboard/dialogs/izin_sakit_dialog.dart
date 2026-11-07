import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  IZIN & SAKIT QUICK MODAL — Siswa SMKN 1 Beringin
//  Upload Surat Keterangan Dokter / Wali & SOP Sekolah
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class IzinSakitDialog extends StatefulWidget {
  final String namaSiswa;
  final String kelasSiswa;

  const IzinSakitDialog({
    super.key,
    required this.namaSiswa,
    required this.kelasSiswa,
  });

  static void show(BuildContext context, {required String namaSiswa, required String kelasSiswa}) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => IzinSakitDialog(namaSiswa: namaSiswa, kelasSiswa: kelasSiswa),
    );
  }

  @override
  State<IzinSakitDialog> createState() => _IzinSakitDialogState();
}

class _IzinSakitDialogState extends State<IzinSakitDialog> {
  String _jenis = 'Sakit';
  final _alasanController = TextEditingController();
  XFile? _lampiranFile;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img != null) {
        setState(() => _lampiranFile = img);
      }
    } catch (_) {}
  }

  void _handleSubmit() {
    Navigator.of(context).pop();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          'Permohonan Terkirim',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Pengajuan $_jenis atas nama ${widget.namaSiswa} telah dicatat dan diteruskan ke Wali Kelas & Guru Piket SMKN 1 Beringin.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pengajuan Izin / Sakit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark, size: 16, color: Color(0xFF8E8E93)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SOP Info Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB9DBFF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF007AFF), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SOP Presensi Siswa: Siswa yang berhalangan hadir wajib melampirkan surat dokter (untuk Sakit) atau surat keterangan orang tua/wali (untuk Izin).',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF004085),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Segmented Control: Sakit vs Izin
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: _jenis,
                      children: const {
                        'Sakit': Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text('🤒 Sakit', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        'Izin': Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text('📝 Izin', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      },
                      onValueChanged: (v) {
                        if (v != null) setState(() => _jenis = v);
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Reason Input Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KETERANGAN / ALASAN',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8E8E93),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _alasanController,
                          placeholder: 'Contoh: Demam tinggi dan berobat ke klinik...',
                          maxLines: 3,
                          decoration: null,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMain),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Upload Surat Bukti
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _lampiranFile != null ? const Color(0xFF34C759) : const Color(0xFFE5E5EA),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _lampiranFile != null ? const Color(0xFFE8F8ED) : const Color(0xFFF2F2F7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _lampiranFile != null ? CupertinoIcons.checkmark_alt : CupertinoIcons.camera_fill,
                              color: _lampiranFile != null ? const Color(0xFF34C759) : const Color(0xFF007AFF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lampiranFile != null ? 'Lampiran Terpasang' : 'Lampirkan Foto Surat',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                Text(
                                  _lampiranFile != null
                                      ? _lampiranFile!.name
                                      : 'Foto surat dokter / surat izin orang tua',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF8E8E93),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Kirim Pengajuan $_jenis',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
