import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../../../shared/widgets/standard_app_bar.dart';
import '../../domain/providers/session_provider.dart';

class ParticipantResultsScreen extends ConsumerWidget {
  final String sessionId;
  final String participantId;

  const ParticipantResultsScreen({
    super.key,
    required this.sessionId,
    required this.participantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(participantsStreamProvider(sessionId));

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Final Results',
        onBackPressed: () => context.pop(),
      ),
      body: AnimatedGradientBg(
        child: SafeArea(
          top: false,
          child: participantsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (participants) {
              if (participants.isEmpty) {
                return _buildEmptyState(context);
              }

              // Sort by score descending
              final sorted = List.from(participants)
                ..sort((a, b) => b.score.compareTo(a.score));

              // Find current participant rank
              final currentParticipant = sorted.firstWhere(
                (p) => p.id == participantId,
                orElse: () => sorted.first,
              );
              final currentRank =
                  sorted.indexOf(currentParticipant) + 1;

              return PageContainer(
                child: Column(
                  children: [
                    SizedBox(height: context.spacingLg),
                    // Trophy animation
                    if (currentRank == 1)
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 80,
                        color: AppColors.accentYellow,
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1.1, 1.1),
                            duration: 1.5.seconds,
                          )
                    else
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 80,
                        color: context.textMuted,
                      ).animate().fadeIn(),

                    const SizedBox(height: 20),

                    // Your rank and score
                    Text(
                      'Your Rank',
                      style: context.bodyLarge.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#$currentRank',
                      style: context.displayLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: currentRank == 1
                            ? AppColors.accentYellow
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${currentParticipant.score}',
                                style: context.displaySmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentYellow,
                                ),
                              ),
                              Text(
                                'Points',
                                style: context.bodySmall.copyWith(
                                  color: context.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: context.bgElevated,
                          ),
                          Column(
                            children: [
                              Text(
                                currentParticipant.avatar,
                                style: const TextStyle(fontSize: 32),
                              ),
                              Text(
                                currentParticipant.name,
                                style: context.bodySmall.copyWith(
                                  color: context.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Leaderboard
                    Text(
                      'Final Leaderboard',
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, i) {
                          final p = sorted[i];
                          final rank = i + 1;
                          final isCurrentUser = p.id == participantId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isCurrentUser
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.2),
                                        AppColors.primary.withOpacity(0.05),
                                      ],
                                    )
                                  : null,
                              color: isCurrentUser
                                  ? null
                                  : context.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrentUser
                                    ? AppColors.primary
                                    : context.bgElevated,
                                width: isCurrentUser ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    rank == 1
                                        ? '🥇'
                                        : rank == 2
                                            ? '🥈'
                                            : rank == 3
                                                ? '🥉'
                                                : '$rank.',
                                    style: const TextStyle(fontSize: 18),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  p.avatar,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: context.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isCurrentUser)
                                        Text(
                                          'You',
                                          style: context.labelSmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${p.score}',
                                  style: context.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentYellow,
                                  ),
                                ),
                                Text(
                                  ' pts',
                                  style: context.labelSmall.copyWith(
                                    color: context.textMuted,
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

                    const SizedBox(height: 24),

                    // Back to home button
                    PulseButton(
                      label: 'Back to Home',
                      icon: const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => context.go('/participant/entry'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: context.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No participants found',
            style: context.titleMedium.copyWith(
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
