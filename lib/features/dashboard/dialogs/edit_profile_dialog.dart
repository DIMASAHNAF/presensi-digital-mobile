import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class EditProfileDialog extends StatefulWidget {
  final UserModel user;
  final ValueChanged<UserModel> onProfileUpdated;

  const EditProfileDialog({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required UserModel user,
    required ValueChanged<UserModel> onProfileUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileDialog(
        user: user,
        onProfileUpdated: onProfileUpdated,
      ),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _picker = ImagePicker();

  late TextEditingController _usernameController;
  late TextEditingController _websiteController;
  late TextEditingController _namaOrtuController;
  late TextEditingController _noHpOrtuController;
  late TextEditingController _bioController;

  XFile? _newAvatarFile;
  XFile? _newBannerFile;
  bool _removeAvatar = false;
  bool _removeBanner = false;

  bool _isSaving = false;
  String? _alertMessage;
  bool _isAlertError = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _usernameController = TextEditingController(text: u.username);
    _websiteController = TextEditingController(
      text: (u.website ?? '').replaceAll(RegExp(r'^https?:\/\/'), ''),
    );
    _namaOrtuController = TextEditingController(text: u.namaOrtu ?? '');
    _noHpOrtuController = TextEditingController(text: u.noHpOrtu ?? '');
    _bioController = TextEditingController(text: u.bio ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _websiteController.dispose();
    _namaOrtuController.dispose();
    _noHpOrtuController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    try {
      final img = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (img != null) {
        setState(() {
          _newBannerFile = img;
          _removeBanner = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickAvatar() async {
    try {
      final img = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (img != null) {
        setState(() {
          _newAvatarFile = img;
          _removeAvatar = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _alertMessage = 'Username tidak boleh kosong.';
        _isAlertError = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _alertMessage = null;
    });

    final res = await ApiService.updateProfile(
      username: username,
      website: _websiteController.text.trim(),
      namaOrtu: _namaOrtuController.text.trim(),
      noHpOrtu: _noHpOrtuController.text.trim(),
      bio: _bioController.text.trim(),
      avatarFile: _newAvatarFile,
      bannerFile: _newBannerFile,
      removeAvatar: _removeAvatar,
      removeBanner: _removeBanner,
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      widget.onProfileUpdated(res.data!);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _isSaving = false;
        _alertMessage = res.message;
        _isAlertError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.xmark,
                        size: 16, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // ── Scrollable Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Banner Preview
                  _buildBannerSection(),

                  // 2. Avatar Circle overlapping banner
                  _buildAvatarSection(),

                  // 3. Form Inputs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_alertMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isAlertError
                                  ? AppColors.dangerBg
                                  : AppColors.successBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isAlertError
                                    ? AppColors.dangerBorder
                                    : AppColors.successBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isAlertError
                                      ? CupertinoIcons.exclamationmark_circle_fill
                                      : CupertinoIcons.checkmark_circle_fill,
                                  size: 16,
                                  color: _isAlertError
                                      ? AppColors.danger
                                      : AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _alertMessage!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isAlertError
                                          ? AppColors.danger
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 200.ms)
                              .shake(hz: 3, offset: const Offset(3, 0)),
                          const SizedBox(height: 14),
                        ],

                        // Nama Lengkap (Locked)
                        _buildLockedField(
                          label: 'Nama Lengkap',
                          value: widget.user.name,
                          helper:
                              'Nama siswa diverifikasi langsung sesuai data Dapodik sekolah.',
                        ),
                        const SizedBox(height: 14),

                        // NISN & Kelas
                        Row(
                          children: [
                            Expanded(
                              child: _buildLockedField(
                                label: 'NISN',
                                value: widget.user.nisn.isNotEmpty
                                    ? widget.user.nisn
                                    : '-',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildLockedField(
                                label: 'Kelas',
                                value:
                                    widget.user.kelasNama ?? 'Reguler',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Username (Editable)
                        _buildEditableField(
                          label: 'Username',
                          controller: _usernameController,
                          prefix: const Icon(CupertinoIcons.at,
                              size: 18, color: AppColors.textMuted),
                          suffix: const Icon(CupertinoIcons.checkmark_seal_fill,
                              size: 18, color: AppColors.success),
                        ),
                        const SizedBox(height: 14),

                        // Website
                        _buildWebsiteField(),
                        const SizedBox(height: 14),

                        // Kontak Orang Tua
                        _buildKontakOrtuCard(),
                        const SizedBox(height: 14),

                        // Bio
                        _buildBioField(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer Action Buttons ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: AppColors.borderLight, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                          color: AppColors.borderLight, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : Text(
                            'Simpan Perubahan',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      height: 120,
      width: double.infinity,
      color: const Color(0xFF0F172A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_removeBanner && _newBannerFile != null)
            Image.network(_newBannerFile!.path, fit: BoxFit.cover)
          else if (!_removeBanner &&
              widget.user.banner != null &&
              widget.user.banner!.isNotEmpty)
            Image.network(
              'https://presensi.smknegeri1beringin.sch.id/storage/${widget.user.banner}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          else
            Container(color: const Color(0xFF1E293B)),

          Container(color: Colors.black.withOpacity(0.35)),

          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickBanner,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.camera_fill,
                        size: 18, color: Colors.white),
                  ),
                ),
                if (!_removeBanner &&
                    (_newBannerFile != null ||
                        (widget.user.banner != null &&
                            widget.user.banner!.isNotEmpty))) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _newBannerFile = null;
                        _removeBanner = true;
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.xmark,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Transform.translate(
      offset: const Offset(0, -36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    color: AppColors.background,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: !_removeAvatar && _newAvatarFile != null
                      ? Image.network(_newAvatarFile!.path,
                          fit: BoxFit.cover)
                      : !_removeAvatar &&
                              widget.user.avatar != null &&
                              widget.user.avatar!.isNotEmpty
                          ? Image.network(
                              'https://presensi.smknegeri1beringin.sch.id/storage/${widget.user.avatar}',
                              fit: BoxFit.cover,
                            )
                          : const Icon(CupertinoIcons.person_fill,
                              size: 40, color: AppColors.primaryBlue),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.camera_fill,
                          size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Maks 2MB',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedField({
    required String label,
    required String value,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            if (helper != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.lock_fill,
                        size: 10, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Data Resmi Terkunci',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textQuaternary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    Widget? prefix,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
            decoration: InputDecoration(
              prefixIcon: prefix,
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebsiteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Website / Instagram / Portfolio',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(13)),
                  border: Border(
                      right: BorderSide(color: AppColors.border)),
                ),
                child: Text(
                  'https://',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _websiteController,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textMain),
                  decoration: const InputDecoration(
                    hintText: 'dimas.tiksmkn1beringin.my.id',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKontakOrtuCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.phone_fill,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontak Orang Tua / Wali',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      'Notifikasi presensi otomatis akan dikirim ke nomor WhatsApp ini.',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nama Orang Tua / Wali',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF065F46)),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: TextField(
              controller: _namaOrtuController,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textMain),
              decoration: const InputDecoration(
                hintText: 'Contoh: Bpk. Budi Santoso',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No. WhatsApp Orang Tua',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF065F46)),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: TextField(
              controller: _noHpOrtuController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textMain),
              decoration: const InputDecoration(
                hintText: '083111536065',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Biografi',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _bioController,
              builder: (_, val, __) => Text(
                '${180 - val.text.length} karakter tersisa',
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textQuaternary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _bioController,
            maxLines: 3,
            maxLength: 180,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: 'Tulis bio singkat tentang kamu...',
              hintStyle: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textQuaternary),
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
