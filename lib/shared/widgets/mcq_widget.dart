import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/constants/app_animations.dart';
import 'package:livevibe/features/session/data/models/slide_model.dart';
import 'glass_card.dart';

/// Reusable MCQ widget for rendering multiple choice questions
class MCQWidget extends StatelessWidget {
  final SlideModel slide;
  final Set<int> selectedIndices;
  final void Function(int index) onSelect;
  final bool isEnabled;
  final bool isSubmitted;

  const MCQWidget({
    super.key,
    required this.slide,
    required this.selectedIndices,
    required this.onSelect,
    required this.isEnabled,
    this.isSubmitted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Question Card
        GlassCard(
          child: Padding(
            padding: AppDimensions.paddingMd,
            child: Text(
              slide.question,
              style: context.headlineMedium.copyWith(
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.lg),

        // Options Grid
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppDimensions.md,
            mainAxisSpacing: AppDimensions.md,
            childAspectRatio: 1.6,
            children: slide.options.asMap().entries.map((entry) {
              return _buildMCQOption(
                context,
                entry.key,
                entry.value,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMCQOption(
    BuildContext context,
    int index,
    String option,
  ) {
    final isSelected = selectedIndices.contains(index);
    final isSingleMode = slide.answerMode == AnswerMode.single;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = isDarkMode ? AppColors.bgCard : AppColors.bgCardLight;
    final borderColor = isDarkMode ? AppColors.bgElevated : AppColors.borderLight;
    final textColor = isDarkMode ? AppColors.textSecondary : AppColors.textPrimaryLight;
    final mutedColor = isDarkMode ? AppColors.textMuted : AppColors.textMutedLight;

    return GestureDetector(
      onTap: isEnabled && !isSubmitted ? () => onSelect(index) : null,
      child: AnimatedContainer(
        duration: AppAnimations.durationNormal,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppDimensions.borderRadiusLg,
          border: Border.all(
            color: isSelected && isEnabled ? primaryColor : borderColor,
            width: isSelected && isEnabled ? 2.5 : 1.5,
          ),
          boxShadow: isSelected && isEnabled
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDarkMode
                        ? AppColors.bgDark.withOpacity(0.3)
                        : AppColors.shadowLight,
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Padding(
            padding: AppDimensions.paddingMd,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSingleMode
                      ? (isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded)
                      : (isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded),
                  color: isSelected && isEnabled ? primaryColor : mutedColor,
                  size: AppDimensions.iconMd,
                ),
                SizedBox(height: AppDimensions.sm),
                Flexible(
                  child: Text(
                    option,
                    style: context.labelSmall.copyWith(
                      color: isEnabled ? textColor : mutedColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
