import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../data/models/session_model.dart';
import '../../data/models/slide_model.dart';
import '../../data/models/response_model.dart';
import '../../domain/providers/session_provider.dart';
import '../../../slides/presentation/widgets/result_bar_chart.dart';
import '../../../slides/presentation/widgets/word_cloud_widget.dart';
import '../../../slides/presentation/widgets/timer_widget.dart';
import 'widgets/live_session_header_widget.dart';

class LiveResultsScreen extends ConsumerWidget {
  final String sessionId;
  const LiveResultsScreen({super.key, required this.sessionId});

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
          data: (session) {
            if (session.status == SessionStatus.ended) {
              return _buildEndedState(context, ref, session, participantsAsync);
            }

            return slidesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (slides) {
                final currentSlide = slides.isEmpty
                    ? null
                    : slides.firstWhere(
                        (s) => s.id == session.currentSlideId,
                        orElse: () => slides[session.currentSlideIndex.clamp(0, slides.length - 1)],
                      );

                return SafeArea(
                  child: Column(
                    children: [
                      LiveSessionHeaderWidget(
                        session: session,
                        slides: slides,
                        onPrevious: session.currentSlideIndex > 0
                            ? () => _navigateToPrevious(ref, sessionId, slides, session.currentSlideIndex)
                            : null,
                        onNext: session.currentSlideIndex < slides.length - 1
                            ? () => _navigateToNext(ref, sessionId, slides, session.currentSlideIndex)
                            : () => _endSessionAndNavigate(context, ref),
                        onEnd: () => _showEndConfirmation(context, ref),
                      ),
                      if (currentSlide != null)
                        Expanded(
                          child: _buildLiveContent(
                            context,
                            ref,
                            session,
                            currentSlide,
                            slides,
                            participantsAsync,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ─── DEPRECATED: These methods have been replaced by LiveSessionHeaderWidget ───

  Widget _buildLiveContent(
    BuildContext context,
    WidgetRef ref,
    SessionModel session,
    SlideModel currentSlide,
    List<SlideModel> slides,
    AsyncValue<List<dynamic>> participantsAsync,
  ) {
    final responsesAsync = ref.watch(responsesStreamProvider((
      sessionId: sessionId,
      slideId: currentSlide.id,
    )));

    return responsesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (responses) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _slideTypeBadge(currentSlide.type),
                        const Spacer(),
                        Text(
                          '${responses.length} response${responses.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentSlide.question,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    // Timer for all slide types
                    const SizedBox(height: 16),
                    TimerWidget(
                      sessionId: sessionId,
                      session: session,
                      onToggle: (active) => ref
                          .read(sessionControllerProvider.notifier)
                          .toggleTimer(sessionId, active),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              // Live Results
              participantsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (participants) => _buildResultsWidget(
                  context,
                  session,
                  currentSlide,
                  responses,
                  participants.length, // Total participants count
                ),
              ),

              const SizedBox(height: 20),

              // Participants list (top 5)
              _buildLeaderboardPreview(context, ref),
            ],
          ),
        );
      },
    );
  }

  Widget _slideTypeBadge(SlideType type) {
    final Map<SlideType, Map<String, dynamic>> config = {
      SlideType.mcq: {
        'label': 'Multiple Choice',
        'color': AppColors.primary,
        'icon': Icons.check_circle_outline,
      },
      SlideType.openText: {
        'label': 'Open Text',
        'color': AppColors.secondary,
        'icon': Icons.text_fields,
      },
      SlideType.wordCloud: {
        'label': 'Word Cloud',
        'color': AppColors.accent,
        'icon': Icons.cloud,
      },
    };

    final c = config[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (c['color'] as Color).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(c['icon'] as IconData, size: 12, color: c['color'] as Color),
          const SizedBox(width: 4),
          Text(
            c['label'] as String,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsWidget(
    BuildContext context,
    SessionModel session,
    SlideModel slide,
    List responses,
    int totalParticipants,
  ) {
    final isLiveSession = session.status == SessionStatus.live;
    switch (slide.type) {
      case SlideType.mcq:
        return ResultBarChart(
          slide: slide,
          responses: responses as List<ResponseModel>,
          isLiveSession: isLiveSession,
          totalParticipants: totalParticipants,
          allParticipantsResponded: responses.length == totalParticipants,
        );
      case SlideType.wordCloud:
        return WordCloudWidget(responses: responses as List<ResponseModel>);
      case SlideType.openText:
        return _buildOpenTextResults(context, responses);
    }
  }

  Widget _buildOpenTextResults(BuildContext context, List responses) {
    if (responses.isEmpty) {
      return GlassCard(
        child: Center(
          child: Text(
            'Waiting for responses...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.textMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responses',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...responses.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return KeyedSubtree(
            key: ValueKey(r.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.divider),
              ),
              child: Row(
                children: [
                  Text(
                    r.participantName.isNotEmpty
                        ? r.participantName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      color: context.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.participantName,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: context.textMuted,
                          ),
                        ),
                        Text(
                          r.value,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 50 * i))
                .fadeIn()
                .slideX(begin: 0.2, end: 0),
          );
        }),
      ],
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(participantsStreamProvider(sessionId));

    return participantsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (participants) {
        if (participants.isEmpty) return const SizedBox.shrink();
        final top5 = participants.take(5).toList();

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded,
                      color: AppColors.accentYellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Leaderboard',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...top5.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final p = entry.value;
                return KeyedSubtree(
                  key: ValueKey(p.id),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank.',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          p.avatar,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${p.score} pts',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentYellow,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: Duration(milliseconds: 80 * rank))
                      .fadeIn()
                      .slideX(begin: 0.1, end: 0),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEndedState(
    BuildContext context,
    WidgetRef ref,
    SessionModel session,
    AsyncValue participantsAsync,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.emoji_events_rounded,
              size: 80,
              color: AppColors.accentYellow,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.05, 1.05),
                  duration: 1.5.seconds,
                ),
            const SizedBox(height: 20),
            Text(
              'Session Ended!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${session.participantCount} participants',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 40),
            // Final leaderboard
            participantsAsync.when(
              loading: () => const CircularProgressIndicator(
                color: AppColors.primary,
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (participants) => Expanded(
                child: ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (context, i) {
                    final p = participants[i];
                    final rank = i + 1;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: rank == 1
                            ? (context.isDarkMode
                                ? AppColors.gradientPrimary
                                : AppColors.gradientPrimaryLight)
                            : null,
                        color: rank != 1
                            ? context.bgCard
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: rank == 1
                              ? AppColors.accentYellow.withOpacity(0.4)
                              : context.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank',
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(p.avatar, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: rank == 1 ? Colors.white : context.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${p.score}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppColors.accentYellow,
                            ),
                          ),
                          Text(
                            ' pts',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: rank == 1 ? Colors.white70 : context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: Duration(milliseconds: 80 * i))
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Back to Home button
            Builder(
              builder: (context) {
                return PulseButton(
                  label: 'Back to Home',
                  icon: Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _endSessionAndNavigate(context, ref),
                );
              },
            ),
          ],
        ),
      ),
    );
}

void _navigateToPrevious(
  WidgetRef ref,
  String sessionId,
  List<SlideModel> slides,
  int currentIndex,
) {
  ref
      .read(sessionControllerProvider.notifier)
      .navigateSlide(sessionId, slides, currentIndex - 1);
}

void _navigateToNext(
  WidgetRef ref,
  String sessionId,
  List<SlideModel> slides,
  int currentIndex,
) {
  ref
      .read(sessionControllerProvider.notifier)
      .navigateSlide(sessionId, slides, currentIndex + 1);
}

void _showEndConfirmation(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'End Session?',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          color: context.textPrimary,
        ),
      ),
      content: Text(
        'This will end the session for all participants.',
        style: TextStyle(
          fontFamily: 'Outfit',
          color: context.textMuted,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            _endSessionAndNavigate(context, ref);
          },
          child: const Text(
            'End Session',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}

/// Atomically end session and navigate to final dashboard.
/// Ensures backend update completes before navigation.
Future<void> _endSessionAndNavigate(BuildContext context, WidgetRef ref) async {
  try {
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: context.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Ending session...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

      // Atomically finish session (waits for backend confirmation)
      await ref
          .read(sessionFinishProvider.notifier)
          .finishSession(sessionId);

      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Navigate to final dashboard (backend already confirmed ended)
        context.go('/session/final/$sessionId');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);  // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending session: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}