import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

//  IZIN & SAKIT QUICK MODAL — Siswa SMKN 1 Beringin
//  Upload Surat Keterangan Dokter / Wali & SOP Sekolah

class IzinSakitDialog extends StatefulWidget {
  final String namaSiswa;
  final String kelasSiswa;

  const IzinSakitDialog({
    super.key,
    required this.namaSiswa,
    required this.kelasSiswa,
  });

  static Future<bool?> show(BuildContext context, {required String namaSiswa, required String kelasSiswa}) {
    return showCupertinoModalPopup<bool>(
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
  bool _isSubmitting = false;

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

  Future<void> _handleSubmit() async {
    final alasan = _alasanController.text.trim();
    if (alasan.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Keterangan atau alasan permohonan wajib diisi.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor:  AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.submitIzin(
        jenis: _jenis,
        keterangan: alasan,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res.success) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop(true);
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(
              'Permohonan Terkirim',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Pengajuan $_jenis atas nama ${widget.namaSiswa} telah dicatat resmi ke sistem presensi sekolah.',
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
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor:  AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor:  AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration:  BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color:  AppColors.textQuaternary,
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
                    decoration:  BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child:  Icon(CupertinoIcons.xmark, size: 16, color: AppColors.textMuted),
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
                      color:  AppColors.infoBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color:  AppColors.infoBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Icon(CupertinoIcons.info_circle_fill, color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SOP Presensi Siswa: Siswa yang berhalangan hadir wajib melampirkan surat dokter (untuk Sakit) atau surat keterangan orang tua/wali (untuk Izin).',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color:  AppColors.primaryBlue,
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
                          child: Text(' Sakit', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        'Izin': Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text(' Izin', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color:  AppColors.border),
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
                            color:  AppColors.textMuted,
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _lampiranFile != null ?  AppColors.success :  AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _lampiranFile != null ?  AppColors.successBg :  AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _lampiranFile != null ? CupertinoIcons.checkmark_alt : CupertinoIcons.camera_fill,
                              color: _lampiranFile != null ?  AppColors.success :  AppColors.primaryBlue,
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
                                    color:  AppColors.textMuted,
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
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:  AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:  AppColors.primaryBlue.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const CupertinoActivityIndicator(color: Colors.white, radius: 9)
                          : Text(
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
