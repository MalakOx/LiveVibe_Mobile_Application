import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.go('/host/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBg(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo - Enhanced with better sizing
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: AppDimensions.borderRadiusXxl,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(
                    duration: AppAnimations.durationSlower,
                    curve: AppAnimations.curveSpring,
                  )
                  .fadeIn(duration: AppAnimations.durationSlow),

              SizedBox(height: context.spacingLg),

              // App Title with gradient text
              ShaderMask(
                shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
                child: Text(
                  'Livevibe',
                  style: context.displayLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              )
                  .animate(delay: AppAnimations.staggerDelay(1))
                  .fadeIn(duration: AppAnimations.durationSlow)
                  .slideY(begin: 0.3, end: 0),

              SizedBox(height: context.spacingSm),

              // Subtitle
              Text(
                'Interactive Presentations, Reimagined',
                style: context.bodyMedium.copyWith(
                  color: context.textMuted,
                  letterSpacing: 0.5,
                ),
              )
                  .animate(delay: AppAnimations.staggerDelay(2))
                  .fadeIn(duration: AppAnimations.durationSlow)
                  .slideY(begin: 0.3, end: 0),

              SizedBox(height: AppDimensions.xxl),

              // Loading progress bar
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: AppDimensions.borderRadiusMd,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: context.bgElevated,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              )
                  .animate(delay: AppAnimations.staggerDelay(3))
                  .fadeIn(duration: AppAnimations.durationNormal),
            ],
          ),
        ),
      ),
    );
  }
}