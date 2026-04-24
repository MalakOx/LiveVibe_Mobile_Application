import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';

class ParticipantNameScreen extends ConsumerStatefulWidget {
  final String sessionCode;

  const ParticipantNameScreen({
    super.key,
    required this.sessionCode,
  });

  @override
  ConsumerState<ParticipantNameScreen> createState() =>
      _ParticipantNameScreenState();
}

class _ParticipantNameScreenState extends ConsumerState<ParticipantNameScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  
  // Avatar selection
  late int _selectedAvatarIndex;
  static const List<String> _avatarOptions = [
    '😊', '😎', '🤓', '😴', '🤩',
    '😍', '🥳', '🤔', '😤', '🚀',
    '⭐', '🎯', '🎨', '🎭', '🎪',
    '🦁', '🐯', '🐻', '🦊', '🐸',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAvatarIndex = 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _selectedAvatar => _avatarOptions[_selectedAvatarIndex];

  void _previousAvatar() {
    setState(() {
      _selectedAvatarIndex = (_selectedAvatarIndex - 1 + _avatarOptions.length) % _avatarOptions.length;
    });
  }

  void _nextAvatar() {
    setState(() {
      _selectedAvatarIndex = (_selectedAvatarIndex + 1) % _avatarOptions.length;
    });
  }

  void _joinSession() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    if (name.length < 2) {
      _showError('Name must be at least 2 characters');
      return;
    }

    setState(() => _isLoading = true);

    // Pass avatar as query parameter
    context.go(
      '/session/waiting/${widget.sessionCode}?name=$name&avatar=${Uri.encodeComponent(_selectedAvatar)}',
    );
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
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => context.pop(),
                    child: Container(
                      width: AppDimensions.minTouchTarget,
                      height: AppDimensions.minTouchTarget,
                      decoration: BoxDecoration(
                        color: context.bgCard.withOpacity(0.8),
                        borderRadius: AppDimensions.borderRadiusMd,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ).animate(delay: AppAnimations.staggerDelay(1)).fadeIn(),

                SizedBox(height: context.spacingXl),

                // Illustration
                Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: AppDimensions.borderRadiusLg,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 32,
                          spreadRadius: 4,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_add_rounded,
                        size: 50,
                      ),
                    ),
                  ).animate(delay: AppAnimations.staggerDelay(1))
                    .scale(duration: 800.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 2000.ms, delay: 400.ms),

                SizedBox(height: context.spacingLg),

                // Title
                Text(
                  'What\'s Your Name?',
                  style: context.displaySmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: AppAnimations.staggerDelay(2))
                  .fadeIn(duration: 700.ms)
                  .slideY(begin: -0.4, end: 0, duration: 700.ms),

                SizedBox(height: context.spacingMd),

                Text(
                  'Enter your name to join the quiz session',
                  style: context.bodyLarge.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? AppColors.textMuted 
                      : AppColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: AppAnimations.staggerDelay(3))
                  .fadeIn(duration: 700.ms)
                  .slideY(begin: 0.4, end: 0, duration: 700.ms),

                SizedBox(height: context.spacingXl),

                // Avatar selection carousel
                Text(
                  'Pick Your Avatar',
                  style: context.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate(delay: AppAnimations.staggerDelay(4))
                  .fadeIn(),

                SizedBox(height: context.spacingLg),

                // Avatar display - BIG and centered
                Container(
                  width: 98,
                  height: 98,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientPrimary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(1.0),
                        blurRadius: 60,
                        spreadRadius: 15,
                      ),
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.8),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _selectedAvatar,
                      style: const TextStyle(fontSize: 49),
                    ),
                  ),
                ).animate(delay: AppAnimations.staggerDelay(4))
                  .scale(duration: 600.ms)
                  .then()
                  .shimmer(duration: 2500.ms, delay: 500.ms),

                SizedBox(height: context.spacingMd),

                // Avatar counter
                Text(
                  '${_selectedAvatarIndex + 1}/${_avatarOptions.length}',
                  style: context.bodySmall.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? AppColors.textMuted 
                      : AppColors.textMutedLight,
                  ),
                ).animate(delay: AppAnimations.staggerDelay(5))
                  .fadeIn(),

                SizedBox(height: context.spacingLg),

                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous button
                    GestureDetector(
                      onTap: _isLoading ? null : _previousAvatar,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: context.bgCard,
                          borderRadius: AppDimensions.borderRadiusMd,
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(0.7),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ).animate(delay: AppAnimations.staggerDelay(5))
                      .fadeIn()
                      .scale(),

                    SizedBox(width: context.spacingLg),

                    // Next button
                    GestureDetector(
                      onTap: _isLoading ? null : _nextAvatar,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.3),
                          borderRadius: AppDimensions.borderRadiusMd,
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(1.0),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.7),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ),
                    ).animate(delay: AppAnimations.staggerDelay(6))
                      .fadeIn()
                      .scale(),
                  ],
                ),

                SizedBox(height: context.spacingXl),

                // Name input
                GlassCard(
                    child: TextField(
                      controller: _nameController,
                      enabled: !_isLoading,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: context.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: context.bodyLarge,
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.textMuted 
                            : AppColors.textMutedLight,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: context.spacingMd,
                          horizontal: context.spacingSm,
                        ),
                      ),
                    ),
                  ).animate(delay: AppAnimations.staggerDelay(4)).fadeIn(),

                SizedBox(height: context.spacingLg),

                // Join button
                PulseButton(
                  label: 'Join Session',
                  gradient: AppColors.gradientSecondary,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _joinSession,
                ).animate(delay: AppAnimations.staggerDelay(5)).fadeIn(),

                SizedBox(height: context.spacingXl),
                    ],
                  ),
                ),
              ),
              // Theme toggle button at the bottom
              const ThemeToggleButton(),
            ],
          ),
        ),
      ),
    );
  }
}

