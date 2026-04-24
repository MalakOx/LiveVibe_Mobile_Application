import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/extensions/context_extensions.dart';
import 'package:livevibe/features/session/data/models/slide_model.dart';
import 'glass_card.dart';

/// Reusable open text widget for rendering open-ended text questions
class OpenTextWidget extends StatelessWidget {
  final SlideModel slide;
  final TextEditingController controller;
  final bool isEnabled;
  final bool isSubmitted;
  final int maxLines;
  final String hintText;

  const OpenTextWidget({
    super.key,
    required this.slide,
    required this.controller,
    required this.isEnabled,
    this.isSubmitted = false,
    this.maxLines = 5,
    this.hintText = 'Share your thoughts...',
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.headlineMedium?.color;
    final hintColor = Theme.of(context).textTheme.bodyMedium?.color;
    
    return Column(
      children: [
        // Question Card
        GlassCard(
          child: Padding(
            padding: AppDimensions.paddingMd,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Text(
                    slide.question,
                    style: context.headlineMedium.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppDimensions.lg),

        // Input Field
        GlassCard(
          child: Padding(
            padding: AppDimensions.paddingMd,
            child: TextField(
              controller: controller,
              enabled: isEnabled && !isSubmitted,
              maxLines: maxLines,
              maxLength: 500,
              style: context.bodyLarge.copyWith(
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: context.bodyMedium.copyWith(
                  color: hintColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                counterStyle: context.caption.copyWith(
                  color: hintColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
