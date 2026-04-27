import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/providers/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  final bool compact;
  const ThemeToggleButton({super.key, this.compact = true});

  const ThemeToggleButton.compact({super.key}) : compact = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final isNarrowScreen = MediaQuery.of(context).size.width < 420;
    final useCompact = compact || isNarrowScreen;

    final horizontalPadding = useCompact ? AppDimensions.sm : AppDimensions.lg;
    final verticalPadding = useCompact ? AppDimensions.xs : AppDimensions.md;
    final iconSize = useCompact ? AppDimensions.iconSm : AppDimensions.iconMd;
    final borderWidth = useCompact ? 1.5 : 2.0;

    return Padding(
      padding: EdgeInsets.all(useCompact ? AppDimensions.xs : AppDimensions.md),
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
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                  ? AppColors.secondary.withOpacity(0.3)
                  : AppColors.shadowMediumLight,
                blurRadius: useCompact ? 8 : (isDarkMode ? 15 : 12),
                spreadRadius: useCompact ? 0 : (isDarkMode ? 2 : 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDarkMode ? AppColors.secondary : AppColors.primary,
                  size: iconSize,
                ),
                if (!useCompact) ...[
                  SizedBox(width: AppDimensions.md),
                  Text(
                    isDarkMode ? 'Dark Mode' : 'Light Mode',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isDarkMode ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
