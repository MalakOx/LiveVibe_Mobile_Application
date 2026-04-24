import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
import '../../data/models/session_model.dart';
import '../../data/models/slide_model.dart';
import '../../domain/providers/session_provider.dart';

class HostSessionDashboardScreen extends ConsumerWidget {
  final String sessionId;
  const HostSessionDashboardScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionStreamProvider(sessionId));
    final slidesAsync = ref.watch(slidesStreamProvider(sessionId));
    final participantsAsync = ref.watch(participantsStreamProvider(sessionId));

    return Scaffold(
      body: AnimatedGradientBg(
        child: sessionAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (session) => SafeArea(
            child: Column(
              children: [
                _buildHeader(context, ref, session, slidesAsync),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppDimensions.screenPadding,
                    child: Column(
                      children: [
                        _buildSessionCard(context, session, participantsAsync),
                        SizedBox(height: context.spacingLg),
                        _buildQRSection(context, session),
                        SizedBox(height: context.spacingLg),
                        _buildSlidesSection(context, ref, session, slidesAsync),
                        SizedBox(height: context.spacingMd),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    SessionModel session,
    AsyncValue<List<SlideModel>> slidesAsync,
  ) {
    return Container(
      padding: AppDimensions.paddingMd.copyWith(top: AppDimensions.sm, bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        color: context.bgCard.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: context.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.textPrimary, size: 18),
            onPressed: () => context.go('/host/dashboard'),
          ),
          SizedBox(width: context.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: context.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: session.status == SessionStatus.live
                            ? AppColors.success
                            : session.status == SessionStatus.ended
                                ? AppColors.error
                                : AppColors.warning,
                      ),
                    ),
                    SizedBox(width: context.spacingMd),
                    Text(
                      session.status.name.toUpperCase(),
                      style: context.caption.copyWith(
                        color: context.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const ThemeToggleButton(),
          SizedBox(width: context.spacingMd),
          if (session.status == SessionStatus.waiting)
            TextButton.icon(
              onPressed: () => context.push('/host/editor/$sessionId'),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: context.labelMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          if (session.status == SessionStatus.live)
            TextButton.icon(
              onPressed: () => context.push('/host/live/$sessionId'),
              icon: const Icon(Icons.bar_chart_rounded, size: 16),
              label: const Text('Live'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                textStyle: context.labelMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    SessionModel session,
    AsyncValue participantsAsync,
  ) {
    final participantCount = participantsAsync.whenData((p) => p.length).value ?? 0;

    return GlassCard(
      child: Row(
        children: [
          _statItem(context, participantCount.toString(), 'Participants',
              Icons.people_alt_rounded, AppColors.primary),
          _divider(context),
          _statItem(context, session.code, 'Session Code',
              Icons.tag_rounded, AppColors.secondary),
          _divider(context),
          _statItem(
            context,
            session.status == SessionStatus.live ? 'LIVE' : session.status.name.toUpperCase(),
            'Status',
            Icons.fiber_manual_record_rounded,
            session.status == SessionStatus.live ? AppColors.success : AppColors.warning,
          ),
        ],
      ),
    ).animate().fadeIn(delay: AppAnimations.staggerDelay(1));
  }

  Widget _statItem(BuildContext context, String value, String label,
      IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: context.iconSizeLg),
          SizedBox(height: context.spacingMd),
          Text(
            value,
            style: context.headlineSmall.copyWith(
              fontSize: value.length > 6 ? 14 : 18,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: context.spacingXs),
          Text(
            label,
            style: context.caption.copyWith(
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: context.bgElevated,
    );
  }

  Widget _buildQRSection(BuildContext context, SessionModel session) {
    if (session.status == SessionStatus.ended) return const SizedBox.shrink();

    // Generate QR data with a URL for better scanning
    final qrData = 'https://livevibe.app/join?code=${session.code}';

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invite Participants',
                style: context.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: session.code));
                  context.showSuccessSnackBar('Code copied!');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical: AppDimensions.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: AppDimensions.borderRadiusMd,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: context.iconSizeSm, color: AppColors.primary),
                      SizedBox(width: context.spacingMd),
                      Text(
                        session.code,
                        style: context.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingLg),
          Center(
            child: Container(
              padding: AppDimensions.paddingMd,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDimensions.borderRadiusLg,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMediumLight,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                embeddedImage: null,
                errorStateBuilder: (cxt, err) {
                  return Center(
                    child: Text(
                      'Error creating QR',
                      style: context.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: context.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Scan with your phone or enter code: ${session.code}',
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  color: context.textMuted,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: context.spacingMd),
              Text(
                '💡 Keep QR code still and well-lit for better scanning',
                textAlign: TextAlign.center,
                style: context.bodySmall.copyWith(
                  color: context.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: AppAnimations.staggerDelay(2)).fadeIn();
  }

  Widget _buildSlidesSection(
    BuildContext context,
    WidgetRef ref,
    SessionModel session,
    AsyncValue<List<SlideModel>> slidesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Slides',
              style: context.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            if (session.status == SessionStatus.waiting)
              TextButton.icon(
                onPressed: () => context.push('/host/editor/$sessionId'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Slide'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
          ],
        ),
        SizedBox(height: context.spacingMd),
        slidesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (slides) {
            if (slides.isEmpty) {
              return GlassCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.slideshow_rounded,
                      size: context.iconSizeXl,
                      color: context.textMuted,
                    ),
                    SizedBox(height: context.spacingMd),
                    Text(
                      'No slides yet',
                      style: context.headlineMedium.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                    SizedBox(height: context.spacingXs),
                    Text(
                      'Add slides to get started',
                      style: context.bodyMedium.copyWith(
                        color: context.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: context.spacingLg),
                    if (session.status == SessionStatus.waiting)
                      PulseButton(
                        label: 'Add First Slide',
                        width: 200,
                        height: 48,
                        onPressed: () => context.push('/host/editor/$sessionId'),
                      ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                ...slides.asMap().entries.map((entry) {
                  final i = entry.key;
                  final slide = entry.value;
                  final isCurrent =
                      session.status == SessionStatus.live &&
                      session.currentSlideId == slide.id;

                  return _buildSlideCard(context, ref, slide, i, isCurrent, session)
                      .animate(delay: Duration(milliseconds: 100 * i))
                      .fadeIn()
                      .slideX(begin: 0.1, end: 0);
                }),
                const SizedBox(height: 20),
                // ✅ START SESSION BUTTON - Changes status to "live" + navigates to live results
                if (session.status == SessionStatus.waiting && slides.isNotEmpty)
                  PulseButton(
                    label: 'Start Live',
                    gradient: AppColors.gradientSecondary,
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () async {
                      try {
                        // ✅ ENFORCED: Change session status to "live"
                        // This triggers participants to see questions
                        await ref
                            .read(sessionControllerProvider.notifier)
                            .startSession(sessionId);
                        
                        if (context.mounted) {
                          context.push('/host/live/$sessionId');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSlideCard(
    BuildContext context,
    WidgetRef ref,
    SlideModel slide,
    int index,
    bool isCurrent,
    SessionModel session,
  ) {
    final typeConfig = _getSlideTypeConfig(slide.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppColors.secondary
              : context.divider.withOpacity(0.1),
          width: isCurrent ? 2 : 1,
        ),
        color: context.bgCard,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: typeConfig['color'].withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            typeConfig['icon'],
            color: typeConfig['color'],
            size: 20,
          ),
        ),
        title: Text(
          slide.question,
          style: context.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              typeConfig['label'],
              style: context.labelSmall.copyWith(
                color: typeConfig['color'],
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '● LIVE',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          '${index + 1}',
          style: context.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: context.textMuted,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getSlideTypeConfig(SlideType type) {
    switch (type) {
      case SlideType.mcq:
        return {
          'icon': Icons.check_circle_outline_rounded,
          'color': AppColors.primary,
          'label': 'Multiple Choice',
        };
      case SlideType.openText:
        return {
          'icon': Icons.text_fields_rounded,
          'color': AppColors.secondary,
          'label': 'Open Text',
        };
      case SlideType.wordCloud:
        return {
          'icon': Icons.cloud_rounded,
          'color': AppColors.accent,
          'label': 'Word Cloud',
        };
    }
  }
}