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
import '../../data/models/participant_model.dart';
import '../../domain/providers/session_provider.dart';

/// Unified final dashboard shown to both host and participants after session ends.
/// Role is determined by checking if participantId is provided.
class SessionFinalDashboard extends ConsumerWidget {
  final String sessionId;
  final String? participantId;  // null if host

  const SessionFinalDashboard({
    super.key,
    required this.sessionId,
    this.participantId,
  });

  bool get isHost => participantId == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionStreamProvider(sessionId));
    final participantsAsync = ref.watch(participantsStreamProvider(sessionId));

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: sessionAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => _buildErrorState(context, e),
            data: (session) {
              // Verify session is actually ended
              if (session.status != SessionStatus.ended) {
                return _buildRedirectingState(context);
              }

              return participantsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => _buildErrorState(context, e),
                data: (participants) => _buildFinalLeaderboard(
                  context,
                  session,
                  participants,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFinalLeaderboard(
    BuildContext context,
    SessionModel session,
    List<ParticipantModel> participants,
  ) {
    // Sort by score descending
    final sorted = List.from(participants)
      ..sort((a, b) => b.score.compareTo(a.score));

    // Find current user's rank (if participant)
    final currentRank = !isHost
        ? sorted.indexWhere((p) => p.id == participantId) + 1
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
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
            'Session Completed!',
            style: context.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${participants.length} participants',
            style: context.bodyLarge.copyWith(
              color: context.textMuted,
            ),
          ),
          const SizedBox(height: 32),

          // Personal rank (if participant)
          if (!isHost && currentRank != null)
            GlassCard(
              child: Column(
                children: [
                  Text(
                    'Your Rank',
                    style: context.bodySmall.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#$currentRank',
                        style: context.displayLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: currentRank == 1
                              ? AppColors.accentYellow
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${sorted[currentRank - 1].score}',
                        style: context.headlineMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentYellow,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'pts',
                        style: context.bodySmall.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(),

          const SizedBox(height: 32),
          Text(
            'Final Leaderboard',
            style: context.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Leaderboard list
          ...sorted.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final participant = entry.value;
            final isCurrent = !isHost && participant.id == participantId;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: rank == 1
                    ? const LinearGradient(
                        colors: [AppColors.accentYellow, AppColors.accentOrange],
                      )
                    : null,
                color: isCurrent
                    ? AppColors.primary.withOpacity(0.1)
                    : rank != 1
                        ? context.bgCard
                        : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primary.withOpacity(0.5)
                      : rank == 1
                          ? AppColors.accentYellow.withOpacity(0.4)
                          : context.bgElevated,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _getRankEmoji(rank),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    participant.avatar,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participant.name,
                          style: context.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (participant.streak > 0)
                          Text(
                            '🔥 ${participant.streak} streak',
                            style: context.bodySmall.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${participant.score}',
                        style: context.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: rank == 1 ? Colors.white : AppColors.accentYellow,
                        ),
                      ),
                      Text(
                        'pts',
                        style: context.labelSmall.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 80 * (rank - 1)))
                .fadeIn()
                .slideY(begin: 0.2, end: 0);
          }),

          const SizedBox(height: 32),
          PulseButton(
            label: isHost ? 'Back to Home' : 'Done',
            icon: Icon(
              isHost ? Icons.home_rounded : Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (isHost) {
                context.go('/host/dashboard');
              } else {
                // Participant - navigate to entry screen
                context.go('/participant/entry');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Error loading results:\n$error',
              textAlign: TextAlign.center,
              style: context.bodyLarge.copyWith(color: context.textPrimary),
            ),
          ),
          const SizedBox(height: 24),
          PulseButton(
            label: 'Back to Home',
            onPressed: () {
              if (isHost) {
                context.go('/host/dashboard');
              } else {
                context.go('/participant/entry');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRedirectingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Waiting for session to end...',
            style: context.bodyLarge.copyWith(
              color: context.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          PulseButton(
            label: 'Back',
            width: 150,
            onPressed: () {
              if (isHost) {
                context.go('/host/dashboard');
              } else {
                context.go('/participant/entry');
              }
            },
          ),
        ],
      ),
    );
  }
}
