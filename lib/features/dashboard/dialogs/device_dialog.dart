import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';

/// B9. Layar "Perangkat Saya": lihat perangkat terikat & lepas ikatannya.
class DeviceDialog extends StatefulWidget {
  const DeviceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DeviceDialog(),
    );
  }

  @override
  State<DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<DeviceDialog> {
  bool _loading = true;
  bool _bound = false;
  String? _maskedId;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getDeviceInfo();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _bound = res.data!['bound'] == true;
        _maskedId = res.data!['device_id']?.toString();
        _error = '';
      } else {
        _error = res.message;
      }
    });
  }

  Future<void> _confirmReset() async {
    final password = await _askPassword();
    if (password == null || password.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _loading = true);

    final deviceId = await DeviceService.getDeviceId();
    final res = await ApiService.resetDevice(
      password: password,
      deviceId: deviceId,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: res.success
            ?  AppColors.primaryDark
            :  AppColors.danger,
        duration: const Duration(seconds: 4),
      ),
    );

    if (res.success) {
      HapticFeedback.heavyImpact();
      await _load();
    }
  }

  Future<String?> _askPassword() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Identitas',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan kata sandi akun Anda untuk melepas perangkat ini.',
              style: GoogleFonts.inter(fontSize: 13, color:  AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Kata sandi',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal', style: GoogleFonts.inter(color:  AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(
              'Lepas Perangkat',
              style: GoogleFonts.inter(
                color:  AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:  BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color:  AppColors.textQuaternary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Perangkat Saya',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color:  AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Demi keamanan, presensi wajah hanya bisa dilakukan dari perangkat yang terdaftar.',
            style: GoogleFonts.inter(fontSize: 12.5, color:  AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const SkeletonShimmer(
              child: SkeletonBox(
                  width: double.infinity, height: 96, radius: 16),
            )
          else if (_error.isNotEmpty)
            _buildErrorCard()
          else
            _buildDeviceCard(),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color:  AppColors.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
           Icon(CupertinoIcons.exclamationmark_triangle_fill,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error,
              style: GoogleFonts.inter(fontSize: 12.5, color:  AppColors.primaryDark),
            ),
          ),
          TextButton(
            onPressed: _load,
            child: Text('Coba lagi', style: GoogleFonts.inter(color:  AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard() {
    final active = _bound;
    final color = active ?  AppColors.success :  AppColors.warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color:  AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(CupertinoIcons.device_phone_portrait, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? 'Perangkat Terdaftar' : 'Belum Ada Perangkat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:  AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active
                          ? 'ID: ${_maskedId ?? '-'}'
                          : 'Perangkat akan terdaftar otomatis saat presensi pertama.',
                      style: GoogleFonts.inter(fontSize: 11.5, color:  AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (active)
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _confirmReset,
              style: FilledButton.styleFrom(
                backgroundColor:  AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link_off_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Lepas Perangkat Ini',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:  AppColors.warningBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color:  AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                 Icon(CupertinoIcons.info_circle, color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tidak ada perangkat yang perlu dilepas saat ini.',
                    style: GoogleFonts.inter(fontSize: 12, color:  AppColors.amberDeep),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
