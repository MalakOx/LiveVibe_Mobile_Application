import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/extensions/context_extensions.dart';
import 'glass_card.dart';

/// Reusable results card for displaying question results
class ResultsCard extends StatelessWidget {
  final String title;
  final Widget content;
  final String? subtitle;
  final EdgeInsets padding;
  final void Function()? onTap;

  const ResultsCard({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
    this.padding = const EdgeInsets.all(AppDimensions.md),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.headlineSmall.copyWith(
                            color: Theme.of(context).textTheme.headlineSmall?.color,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: AppDimensions.xs),
                          Text(
                            subtitle!,
                            style: context.caption.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                ],
              ),
              SizedBox(height: AppDimensions.md),
              // Content
              content,
            ],
          ),
        ),
      ),
    );
  }
}

/// Result stat card for displaying single metrics
class ResultStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;

  const ResultStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = accentColor ?? Theme.of(context).colorScheme.primary;
    
    return GlassCard(
      child: Padding(
        padding: AppDimensions.paddingMd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconLg,
              color: primaryColor,
            ),
            SizedBox(height: AppDimensions.md),
            Text(
              value,
              style: context.displaySmall.copyWith(
                color: primaryColor,
              ),
            ),
            SizedBox(height: AppDimensions.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal result item (for lists)
class ResultItemWidget extends StatelessWidget {
  final String label;
  final String count;
  final double percentage;
  final Color? barColor;
  final bool isCorrect;

  const ResultItemWidget({
    super.key,
    required this.label,
    required this.count,
    required this.percentage,
    this.barColor,
    this.isCorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = barColor ?? Theme.of(context).colorScheme.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: context.labelLarge.copyWith(
                color: Theme.of(context).textTheme.labelLarge?.color,
              ),
            ),
            const Spacer(),
            Text(
              count,
              style: context.labelLarge.copyWith(
                color: primaryColor,
              ),
            ),
            if (isCorrect) ...[
              SizedBox(width: AppDimensions.sm),
              const Icon(
                Icons.check_circle,
                size: AppDimensions.iconMd,
                color: AppColors.success,
              ),
            ],
          ],
        ),
        SizedBox(height: AppDimensions.sm),
        ClipRRect(
          borderRadius: AppDimensions.borderRadiusMd,
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(
              primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
