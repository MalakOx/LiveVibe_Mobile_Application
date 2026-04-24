import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/extensions/context_extensions.dart';

/// Widget for displaying error states with consistent styling
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.title = 'Oops! Something went wrong',
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final textSecondary = isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final buttonTextColor = isDarkMode ? AppColors.textPrimary : AppColors.bgCardLight;

    return Center(
      child: Padding(
        padding: AppDimensions.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.error,
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
            // Retry button (if provided)
            if (onRetry != null) ...[
              AppDimensions.gapLg,
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
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

/// Widget for displaying general error messages (inline)
class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final EdgeInsets? padding;
  final VoidCallback? onDismiss;

  const ErrorMessageWidget({
    super.key,
    required this.message,
    this.padding,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding ?? AppDimensions.paddingMd,
      padding: AppDimensions.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: AppDimensions.borderRadiusLg,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.error,
            size: AppDimensions.iconMd,
          ),
          AppDimensions.gapMd,
          Expanded(
            child: Text(
              message,
              style: context.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            AppDimensions.gapSm,
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: AppColors.error,
                size: AppDimensions.iconMd,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
