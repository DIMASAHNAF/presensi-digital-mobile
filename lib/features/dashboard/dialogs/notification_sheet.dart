import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/theme/app_theme.dart';

/// C14. Kotak masuk notifikasi siswa.
class NotificationSheet extends StatefulWidget {
  const NotificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationSheet(),
    );
  }

  static const _seenKey = 'seen_notification_ids_v1';

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
  bool _loading = true;
  List<AppNotification> _items = [];
  Set<String> _seen = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await NotificationService.fetch();
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(NotificationSheet._seenKey) ?? []).toSet();
    if (!mounted) return;
    setState(() {
      _items = items;
      _seen = seen;
      _loading = false;
    });
    // Tandai semua sudah dibaca setelah ditampilkan.
    final ids = items.map((e) => e.id).toList();
    await prefs.setStringList(NotificationSheet._seenKey, ids);
  }

  Color _toneColor(String tone) {
    switch (tone) {
      case 'success':
        return AppColors.success;
      case 'danger':
        return AppColors.danger;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _toneIcon(String category) {
    return category == 'late'
        ? CupertinoIcons.time_solid
        : CupertinoIcons.doc_text_fill;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 20,
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
                color: AppColors.textQuaternary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Notifikasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const SkeletonShimmer(
              child: Column(
                children: [
                  _NotifSkeletonCard(),
                  SizedBox(height: 10),
                  _NotifSkeletonCard(),
                  SizedBox(height: 10),
                  _NotifSkeletonCard(),
                ],
              ),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(CupertinoIcons.bell_slash,
                      size: 40, color: AppColors.textQuaternary),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada notifikasi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = _items[i];
                  final color = _toneColor(n.tone);
                  final isNew = !_seen.contains(n.id);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isNew
                            ? color.withOpacity(0.5)
                            : AppColors.border,
                        width: isNew ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_toneIcon(n.category),
                              color: color, size: 19),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                  ),
                                  if (isNew)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                n.body,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (n.time.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  n.time,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}


/// C13. Kerangka kartu notifikasi sambil menunggu data.
class _NotifSkeletonCard extends StatelessWidget {
  const _NotifSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 38, height: 38, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 11),
                SizedBox(height: 6),
                SkeletonBox(width: 90, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
