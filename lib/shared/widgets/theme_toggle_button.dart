import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/providers/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);

    return Padding(
      padding: EdgeInsets.all(AppDimensions.md),
      child: GestureDetector(
        onTap: () => themeNotifier.toggleTheme(),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.bgElevated : AppColors.bgElevatedLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(
              color: isDarkMode
                ? AppColors.secondary.withOpacity(0.5)
                : AppColors.secondary.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                  ? AppColors.secondary.withOpacity(0.3)
                  : AppColors.shadowMediumLight,
                blurRadius: isDarkMode ? 15 : 12,
                spreadRadius: isDarkMode ? 2 : 1,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDarkMode ? AppColors.secondary : AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: AppDimensions.md),
                Text(
                  isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDarkMode ? AppColors.secondary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
