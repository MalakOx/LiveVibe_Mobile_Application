import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/extensions/context_extensions.dart';

/// Status badge widget for displaying session or item status
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.md,
      vertical: AppDimensions.xs,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withOpacity(0.15),
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(
          color: backgroundColor ?? AppColors.primary,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppDimensions.iconSm,
              color: foregroundColor ?? AppColors.primary,
            ),
            SizedBox(width: AppDimensions.xs),
          ],
          Text(
            label,
            style: context.labelSmall.copyWith(
              color: foregroundColor ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge presets
class StatusBadgePresets {
  static Widget live({String label = 'LIVE'}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.success.withOpacity(0.15),
      foregroundColor: AppColors.success,
      icon: Icons.fiber_manual_record,
    );
  }

  static Widget ended({String label = 'ENDED'}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.textMuted.withOpacity(0.15),
      foregroundColor: AppColors.textMuted,
      icon: Icons.check_circle_outline,
    );
  }

  static Widget waiting({String label = 'WAITING'}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.warning.withOpacity(0.15),
      foregroundColor: AppColors.warning,
      icon: Icons.schedule,
    );
  }

  static Widget completed({String label = 'COMPLETED'}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.secondary.withOpacity(0.15),
      foregroundColor: AppColors.secondary,
      icon: Icons.check_circle,
    );
  }

  static Widget active({String label = 'ACTIVE'}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.primary.withOpacity(0.15),
      foregroundColor: AppColors.primary,
      icon: Icons.play_circle_outline,
    );
  }
}
