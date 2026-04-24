import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/extensions/context_extensions.dart';

class AppBranding extends StatelessWidget {
  final bool showSubtitle;
  final String? subtitle;
  final bool compact;

  const AppBranding({
    super.key,
    this.showSubtitle = false,
    this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBranding(context);
    }
    return _buildFullBranding(context);
  }

  Widget _buildFullBranding(BuildContext context) {
    return Column(
      children: [
        // Logo container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: AppDimensions.borderRadiusLg,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.quiz_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: context.spacingLg),
        
        // App name
        Text(
          'LIVEVIBE',
          style: context.displaySmall.copyWith(
            fontWeight: FontWeight.w900,
            color: context.textPrimary,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        
        if (showSubtitle) ...[
          SizedBox(height: context.spacingXs),
          Text(
            subtitle ?? 'Interactive Live Presentations',
            style: context.bodyMedium.copyWith(
              color: context.textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildCompactBranding(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.quiz_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: context.spacingMd),
        Text(
          'LIVEVIBE',
          style: context.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
