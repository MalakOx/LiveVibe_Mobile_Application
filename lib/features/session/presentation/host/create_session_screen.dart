import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/session_provider.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() =>
      _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _titleController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _hostNameController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider);
    final user = authState.maybeWhen(
      data: (u) => u,
      orElse: () => null,
    );

    if (user == null) {
      if (mounted) {
        context.showErrorSnackBar('User not authenticated');
      }
      return;
    }

    final controller = ref.read(sessionControllerProvider.notifier);
    try {
      final sessionId = await controller.createSession(
        title: _titleController.text.trim(),
        hostId: user.uid,
        hostName: _hostNameController.text.trim(),
      );
      if (mounted) context.pushReplacement('/host/editor/$sessionId');
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: Padding(
            padding: AppDimensions.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: context.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                  ).animate().fadeIn(),

                  SizedBox(height: context.spacingLg),

                  Text(
                    'Create Session',
                    style: context.displaySmall,
                  ).animate(delay: AppAnimations.staggerDelay(1)).fadeIn().slideX(begin: -0.2, end: 0),

                  SizedBox(height: context.spacingMd),

                  Text(
                    'Set up your live interactive session',
                    style: context.bodyLarge.copyWith(
                      color: context.textMuted,
                    ),
                  ).animate(delay: AppAnimations.staggerDelay(2)).fadeIn(),

                  SizedBox(height: context.spacingXl),

                  _buildField(
                    context,
                    controller: _titleController,
                    label: 'Session Title',
                    hint: 'e.g. Flutter Workshop Q&A',
                    icon: Icons.title_rounded,
                    validator: (v) => v!.isEmpty ? 'Title is required' : null,
                    delay: 3,
                  ),

                  SizedBox(height: context.spacingMd),

                  _buildField(
                    context,
                    controller: _hostNameController,
                    label: 'Your Name',
                    hint: 'e.g. Dr. Karim',
                    icon: Icons.person_rounded,
                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    delay: 4,
                  ),

                  const Spacer(),

                  PulseButton(
                    label: 'Create & Configure',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _createSession,
                    icon: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ).animate(delay: AppAnimations.staggerDelay(5)).fadeIn().slideY(begin: 0.3, end: 0),

                  SizedBox(height: context.spacingMd),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int delay = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.labelLarge.copyWith(
            color: context.textSecondary,
          ),
        ),
        SizedBox(height: context.spacingMd),
        TextFormField(
          controller: controller,
          validator: validator,
          style: context.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: context.iconSizeMd),
          ),
        ),
      ],
    ).animate(delay: AppAnimations.staggerDelay(delay)).fadeIn().slideY(begin: 0.2, end: 0);
  }
}