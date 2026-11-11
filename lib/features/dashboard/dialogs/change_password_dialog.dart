import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/api_service.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isLengthValid => _passwordController.text.length >= 6;
  bool get _isMatching =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmController.text;

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.updatePassword(
        _passwordController.text,
        _confirmController.text,
      );

      if (!mounted) return;

      if (res.success) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Color(0xFF34C759),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kata sandi berhasil diperbarui!',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: const Color(0xFF1C1C1E),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = res.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Terjadi kesalahan sistem saat menyimpan password.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuad,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F7), // Apple System Grouped Background
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Pill Drag Indicator ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7C7CC),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // ── Header Bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.lock_shield_fill,
                          color: Color(0xFF007AFF),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubah Kata Sandi',
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C1C1E),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Perbarui kata sandi akun siswa Anda',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5E5EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE5E5EA)),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Error Banner ──
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF3B30).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_circle_fill,
                                color: Color(0xFFFF3B30),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFFFF3B30),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 250.ms)
                            .shake(hz: 3, offset: const Offset(4, 0)),
                        const SizedBox(height: 14),
                      ],

                      // ── Grouped Input Box ──
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE5E5EA),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          children: [
                            // New Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Kata Sandi Baru (Min. 6 Karakter)',
                                hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFFC7C7CC),
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  CupertinoIcons.lock_fill,
                                  color: Color(0xFF8E8E93),
                                  size: 18,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                  behavior: HitTestBehavior.opaque,
                                  child: Icon(
                                    _obscurePassword
                                        ? CupertinoIcons.eye_slash
                                        : CupertinoIcons.eye,
                                    color: const Color(0xFF8E8E93),
                                    size: 18,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().length < 6) {
                                  return 'Kata sandi minimal 6 karakter.';
                                }
                                return null;
                              },
                            ),

                            const Divider(
                                height: 1,
                                indent: 44,
                                color: Color(0xFFF2F2F7)),

                            // Confirm Field
                            TextFormField(
                              controller: _confirmController,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) => _handleSave(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ulangi Kata Sandi Baru',
                                hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFFC7C7CC),
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  CupertinoIcons.checkmark_shield_fill,
                                  color: Color(0xFF8E8E93),
                                  size: 18,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                  behavior: HitTestBehavior.opaque,
                                  child: Icon(
                                    _obscureConfirm
                                        ? CupertinoIcons.eye_slash
                                        : CupertinoIcons.eye,
                                    color: const Color(0xFF8E8E93),
                                    size: 18,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Konfirmasi kata sandi wajib diisi.';
                                }
                                if (val != _passwordController.text) {
                                  return 'Konfirmasi kata sandi tidak cocok.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Validation Checklist ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            _buildCheckItem(
                              isValid: _isLengthValid,
                              text: 'Minimal 6 karakter kombinasi huruf / angka',
                            ),
                            const SizedBox(height: 5),
                            _buildCheckItem(
                              isValid: _isMatching,
                              text: 'Konfirmasi kata sandi cocok',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Action Buttons ──
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF007AFF).withOpacity(0.5),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                                radius: 9,
                              )
                            : Text(
                                'Simpan Kata Sandi Baru',
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem({required bool isValid, required String text}) {
    return Row(
      children: [
        Icon(
          isValid
              ? CupertinoIcons.checkmark_circle_fill
              : CupertinoIcons.circle,
          size: 14,
          color: isValid ? const Color(0xFF34C759) : const Color(0xFFC7C7CC),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isValid ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
            fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
