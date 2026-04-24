import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';

/// Premium glass card with backdrop blur.
/// Adapts border, shadow, and background to light / dark mode.
class GlassCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final double blur;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.borderColor,
    this.blur = 8,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeNotifierProvider);

    final cardColor = isDark
        ? AppColors.bgCard.withOpacity(0.75)
        : AppColors.bgCardLight.withOpacity(0.97);

    final borderC = borderColor ??
        (isDark ? AppColors.bgElevated : AppColors.borderSubtleLight);

    final shadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderC, width: 1.5),
          boxShadow: shadows,
        ),
        child: child,
      ),
    );
  }
}
