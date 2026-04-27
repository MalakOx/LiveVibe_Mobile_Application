import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/app_branding.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';

class ParticipantEntryScreen extends StatefulWidget {
  const ParticipantEntryScreen({super.key});

  @override
  State<ParticipantEntryScreen> createState() => _ParticipantEntryScreenState();
}

class _ParticipantEntryScreenState extends State<ParticipantEntryScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _joinWithCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showError('Please enter a session code');
      return;
    }

    if (code.length < 4) {
      _showError('Session code must be at least 4 characters');
      return;
    }

    setState(() => _isLoading = true);

    // Navigate to name entry screen with session code
    context.push('/participant/name/$code').then((_) {
      setState(() => _isLoading = false);
    });
  }

  void _joinWithQR() {
    context.push('/participant/qr');
  }

  void _showError(String message) {
    context.showErrorSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: AppDimensions.screenPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                // App Branding with Livevibe
                AppBranding(
                  showSubtitle: true,
                  subtitle: 'Interactive Live Presentations',
                ).animate(delay: AppAnimations.staggerDelay(1))
                  .fadeIn(duration: 600.ms)
                  .scale(duration: 700.ms),

                SizedBox(height: context.spacingXl),

                Text(
                  'Join a Session',
                  style: context.displaySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: AppAnimations.staggerDelay(2))
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.3, end: 0, duration: 600.ms),

                SizedBox(height: context.spacingMd),

                Text(
                  'Enter the session code or scan QR',
                  style: context.bodyLarge.copyWith(
                    color: context.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: AppAnimations.staggerDelay(3))
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, duration: 600.ms),

                SizedBox(height: context.spacingXl),

                // Code input
                GlassCard(
                    child: TextField(
                      controller: _codeController,
                      enabled: !_isLoading,
                      textAlign: TextAlign.center,
                      style: context.headlineSmall.copyWith(
                        color: context.textPrimary,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'SESSION CODE',
                        hintStyle: context.headlineSmall.copyWith(
                          letterSpacing: 2,
                          color: context.textMuted.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ).animate(delay: AppAnimations.staggerDelay(4)).fadeIn(),

                SizedBox(height: context.spacingLg),

                // Join button
                PulseButton(
                  label: 'Join Session',
                  gradient: AppColors.gradientPrimary,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _joinWithCode,
                ).animate(delay: AppAnimations.staggerDelay(5)).fadeIn(),

                SizedBox(height: context.spacingMd),

                // Divider
                Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: context.divider.withOpacity(0.2),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.spacingMd),
                        child: Text(
                          'OR',
                          style: context.labelMedium.copyWith(
                            color: context.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: context.divider.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ).animate(delay: AppAnimations.staggerDelay(5)).fadeIn(),

                SizedBox(height: context.spacingMd),

                // QR button
                GestureDetector(
                  onTap: _isLoading ? null : _joinWithQR,
                  child: Container(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightMd,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: AppDimensions.borderRadiusMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                        SizedBox(width: context.spacingMd),
                        Text(
                          'Scan QR Code',
                          style: context.labelLarge.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: AppAnimations.staggerDelay(6)).fadeIn(),

                SizedBox(height: context.spacingXl),

                // Host sign in button
                GestureDetector(
                  onTap: _isLoading ? null : () => context.push('/host/auth'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Are you a host? ',
                        style: context.bodySmall.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                      Text(
                        'Sign In',
                        style: context.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: AppAnimations.staggerDelay(7)).fadeIn(),
                    ],
                  ),
                ),
              ),
              // Theme toggle button at the bottom
              const ThemeToggleButton(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
