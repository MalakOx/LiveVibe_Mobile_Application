import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/extensions/context_extensions.dart';

/// Widget for displaying empty states with consistent styling
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final EdgeInsets? padding;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final textSecondary = isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final buttonTextColor = isDarkMode ? AppColors.textPrimary : AppColors.bgCardLight;

    return Center(
      child: Padding(
        padding: padding ?? AppDimensions.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            AppDimensions.gapLg,
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.headlineMedium.copyWith(
                color: textPrimary,
              ),
            ),
            AppDimensions.gapMd,
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: textSecondary,
              ),
            ),
            // Action button (if provided)
            if (onAction != null && actionLabel != null) ...[
              AppDimensions.gapLg,
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: buttonTextColor,
                  padding: AppDimensions.paddingMd,
                  minimumSize: const Size(150, AppDimensions.buttonHeightMd),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple empty state for list views and similar
class EmptyListWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyListWidget({
    super.key,
    this.message = 'No items yet',
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDarkMode ? AppColors.textMuted : AppColors.textMutedLight;

    return Padding(
      padding: AppDimensions.paddingLg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: textMuted,
          ),
          AppDimensions.gapMd,
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.bodyMedium.copyWith(
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
