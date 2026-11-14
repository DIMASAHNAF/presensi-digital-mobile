import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// C13. Placeholder skeleton: kotak abu + shimmer.
///
/// Dipakai untuk menggantikan spinner pada layar yang memuat daftar/kartu,
/// supaya tata letak tidak "melompat" saat data datang.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// C13. Membungkus pohon skeleton dengan animasi shimmer berulang.
class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: AppColors.surface.withOpacity(0.55));
  }
}
