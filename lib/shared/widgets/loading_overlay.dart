import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/extensions/context_extensions.dart';

/// Full-screen loading overlay with animated loading indicator
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool dismissible;

  const LoadingOverlay({
    super.key,
    this.message,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = isDarkMode
        ? AppColors.bgDark.withOpacity(0.5)
        : AppColors.overlayLight.withOpacity(0.8);
    final textColor = isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return PopScope(
      canPop: dismissible,
      child: Container(
        color: overlayColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loading indicator
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating circle
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 1.0).animate(
                        AlwaysStoppedAnimation(
                          DateTime.now().millisecond / 1000,
                        ),
                      ),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                    // Inner rotating circle (opposite direction)
                    RotationTransition(
                      turns: Tween(begin: 1.0, end: 0.0).animate(
                        AlwaysStoppedAnimation(
                          DateTime.now().millisecond / 1000,
                        ),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Center dot with gradient
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isDarkMode
                            ? AppColors.gradientPrimary
                            : AppColors.gradientPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (message != null) ...[
                AppDimensions.gapMd,
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(
                    color: textColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay widget to show loading state on top of existing content
class LoadingOverlayWidget extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;

  const LoadingOverlayWidget({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: LoadingOverlay(message: loadingMessage),
          ),
      ],
    );
  }
}
