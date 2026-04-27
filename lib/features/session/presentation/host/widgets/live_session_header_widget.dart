import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../data/models/session_model.dart';
import '../../../data/models/slide_model.dart';

/// Header widget showing live session progress and navigation.
/// Extracted from LiveResultsScreen for reusability.
class LiveSessionHeaderWidget extends ConsumerWidget {
  final SessionModel session;
  final List<SlideModel> slides;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onEnd;

  const LiveSessionHeaderWidget({
    super.key,
    required this.session,
    required this.slides,
    this.onPrevious,
    this.onNext,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = session.currentSlideIndex;
    final total = slides.length;
    final isLastSlide = currentIndex == total - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.bgCard.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: context.divider),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Slide ${currentIndex + 1} of $total',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: context.textMuted,
                ),
              ),
              const Spacer(),
              // Navigation buttons
              Row(
                children: [
                  _NavButton(
                    icon: Icons.skip_previous_rounded,
                    onTap: currentIndex > 0 ? onPrevious : null,
                  ),
                  const SizedBox(width: 8),
                  _NavButton(
                    icon: isLastSlide ? Icons.check_circle_rounded : Icons.skip_next_rounded,
                    color: isLastSlide ? AppColors.success : AppColors.primary,
                    onTap: currentIndex < total - 1 ? onNext : onEnd,
                  ),
                  const SizedBox(width: 8),
                  _NavButton(
                    icon: Icons.stop_rounded,
                    color: AppColors.error,
                    onTap: onEnd,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? (currentIndex + 1) / total : 0,
              backgroundColor: context.bgElevated,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable navigation button for header.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _NavButton({
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = onTap != null
        ? (context.isDarkMode ? context.textPrimary : Colors.white)
        : context.textMuted;
    final buttonColor = onTap != null ? (color ?? context.bgElevated) : context.bgSubtle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }
}
