import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/app_branding.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../domain/providers/auth_provider.dart';

class HostAuthScreen extends ConsumerStatefulWidget {
  const HostAuthScreen({super.key});

  @override
  ConsumerState<HostAuthScreen> createState() => _HostAuthScreenState();
}

class _HostAuthScreenState extends ConsumerState<HostAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (!email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }

    // Call signIn - error handling is done in didChangeDependencies listener
    await ref.read(authNotifierProvider.notifier).signIn(
      email: email,
      password: password,
    );
  }

  void _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (!email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    // Call signUp - error handling is done in didChangeDependencies listener
    await ref.read(authNotifierProvider.notifier).signUp(
      email: email,
      password: password,
    );
  }

  void _showError(String message) {
    context.showErrorSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    // Listen to auth state for automatic redirection
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          // User is authenticated, redirect to dashboard
          context.go('/host/dashboard');
        }
      });
    });

    // Listen to auth notifier for error messages
    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        error: (error, stackTrace) {
          // Extract the actual error message with multiple fallbacks
          String errorMessage = 'An error occurred';
          
          print('Raw error object: $error');
          print('Error type: ${error.runtimeType}');
          
          if (error is Exception) {
            String msg = error.toString();
            print('Exception string: $msg');
            
            // Try to extract message from various exception formats
            if (msg.startsWith('Exception: ')) {
              errorMessage = msg.substring(10).trim();
            } else if (msg.startsWith('_Exception: ')) {
              errorMessage = msg.substring(12).trim();
            } else if (msg == 'Exception: Error' || msg == 'Error') {
              // Fallback: try to get more detailed error
              errorMessage = 'Account creation failed. Please try again.';
            } else {
              errorMessage = msg.trim();
            }
          } else {
            errorMessage = error.toString().trim();
          }
          
          // Final validation
          if (errorMessage.isEmpty || errorMessage == 'Error') {
            errorMessage = 'Account creation failed. Please check your details and try again.';
          }
          
          print('Final error message: $errorMessage');
          _showError(errorMessage);
        },
        orElse: () {},
      );
    });

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: Column(
            children: [
              // Header with Livevibe branding
              Padding(
                padding: AppDimensions.paddingMd,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: isLoading ? null : () => context.pop(),
                      child: Container(
                        width: AppDimensions.minTouchTarget,
                        height: AppDimensions.minTouchTarget,
                        decoration: BoxDecoration(
                          color: context.bgCard.withOpacity(0.6),
                          borderRadius: AppDimensions.borderRadiusMd,
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AppBranding(compact: true),
                    const Spacer(),
                    SizedBox(width: AppDimensions.minTouchTarget), // Spacing for symmetry
                  ],
                ),
              ),

              // Tab bar - Enhanced styling
              Container(
                margin: AppDimensions.paddingHorizontalLg,
                decoration: BoxDecoration(
                  borderRadius: AppDimensions.borderRadiusMd,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: context.textMuted,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: context.labelMedium,
                  unselectedLabelStyle: context.labelMedium,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Sign In Tab
                    _buildSignInTab(isLoading),
                    // Sign Up Tab
                    _buildSignUpTab(isLoading),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInTab(bool isLoading) {
    return SingleChildScrollView(
      padding: AppDimensions.screenPadding,
      child: Column(
        children: [
          SizedBox(height: context.spacingLg),

          // Icon - Enhanced design
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: AppDimensions.borderRadiusXxl,
            ),
            child: const Center(
              child: Icon(
                Icons.lock_open_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ).animate().scale(
            duration: AppAnimations.durationSlow,
            curve: AppAnimations.curveSpring,
          ),

          SizedBox(height: context.spacingLg),

          // Email field - Enhanced with context
          GlassCard(
            child: TextField(
              controller: _emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              style: context.bodyLarge.copyWith(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: context.bodyMedium.copyWith(
                  color: context.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: context.textMuted,
                  size: context.iconSizeMd,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.spacingMd,
                  horizontal: AppDimensions.xs,
                ),
              ),
            ),
          ).animate(delay: AppAnimations.staggerDelay(1)).fadeIn(),

          SizedBox(height: context.spacingMd),

          // Password field - Enhanced
          GlassCard(
            child: TextField(
              controller: _passwordController,
              enabled: !isLoading,
              obscureText: !_showPassword,
              style: context.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: context.bodyMedium.copyWith(
                  color: context.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: context.textMuted,
                  size: context.iconSizeMd,
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: context.textMuted,
                    size: context.iconSizeMd,
                  ),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.spacingMd,
                  horizontal: AppDimensions.xs,
                ),
              ),
            ),
          ).animate(delay: AppAnimations.staggerDelay(2)).fadeIn(),

          SizedBox(height: context.spacingXl),

          // Sign in button
          PulseButton(
            label: 'Sign In',
            gradient: AppColors.gradientPrimary,
            isLoading: isLoading,
            onPressed: isLoading ? null : _signIn,
          ).animate(delay: AppAnimations.staggerDelay(3)).fadeIn(),

          SizedBox(height: context.spacingMd),

          Text(
            'Don\'t have an account? Switch to Sign Up tab above',
            style: context.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpTab(bool isLoading) {
    return SingleChildScrollView(
      padding: AppDimensions.screenPadding,
      child: Column(
        children: [
          SizedBox(height: context.spacingLg),

          // Icon - Enhanced design
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppColors.gradientSecondary,
              borderRadius: AppDimensions.borderRadiusXxl,
            ),
            child: const Center(
              child: Icon(
                Icons.person_add_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ).animate().scale(
            duration: AppAnimations.durationSlow,
            curve: AppAnimations.curveSpring,
          ),

          SizedBox(height: context.spacingLg),

          // Email field
          GlassCard(
            child: TextField(
              controller: _emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              style: context.bodyLarge.copyWith(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: context.bodyMedium.copyWith(
                  color: context.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: context.textMuted,
                  size: context.iconSizeMd,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.spacingMd,
                  horizontal: AppDimensions.xs,
                ),
              ),
            ),
          ).animate(delay: AppAnimations.staggerDelay(1)).fadeIn(),

          SizedBox(height: context.spacingMd),

          // Password field
          GlassCard(
            child: TextField(
              controller: _passwordController,
              enabled: !isLoading,
              obscureText: !_showPassword,
              style: context.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Password (min 6 characters)',
                hintStyle: context.bodyMedium.copyWith(
                  color: context.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: context.textMuted,
                  size: context.iconSizeMd,
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: context.textMuted,
                    size: context.iconSizeMd,
                  ),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.spacingMd,
                  horizontal: AppDimensions.xs,
                ),
              ),
            ),
          ).animate(delay: AppAnimations.staggerDelay(2)).fadeIn(),

          SizedBox(height: context.spacingMd),

          // Confirm password field
          GlassCard(
            child: TextField(
              controller: _confirmPasswordController,
              enabled: !isLoading,
              obscureText: !_showConfirmPassword,
              style: context.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                hintStyle: context.bodyMedium.copyWith(
                  color: context.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: context.textMuted,
                  size: context.iconSizeMd,
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  child: Icon(
                    _showConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: context.textMuted,
                    size: context.iconSizeMd,
                  ),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.spacingMd,
                  horizontal: AppDimensions.xs,
                ),
              ),
            ),
          ).animate(delay: AppAnimations.staggerDelay(3)).fadeIn(),

          SizedBox(height: context.spacingXl),

          // Sign up button
          PulseButton(
            label: 'Create Account',
            gradient: AppColors.gradientSecondary,
            isLoading: isLoading,
            onPressed: isLoading ? null : _signUp,
          ).animate(delay: AppAnimations.staggerDelay(4)).fadeIn(),

          const SizedBox(height: 16),

          Text(
            'Already have an account? Switch to Sign In tab above',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: context.textMuted,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
