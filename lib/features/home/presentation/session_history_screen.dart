import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';
import '../../../shared/widgets/app_branding.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../session/data/models/session_model.dart';
import '../../auth/domain/providers/auth_provider.dart';

final endedSessionsProvider = StreamProvider.family<List<SessionModel>, String>((ref, hostId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('sessions')
      .where('hostId', isEqualTo: hostId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => SessionModel.fromFirestore(doc))
            .where((session) => session.status == SessionStatus.ended)
            .toList();
      });
});

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: authState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, st) => Center(
              child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
            ),
            data: (user) {
              if (user == null) {
                return const SizedBox.shrink();
              }

              final sessionsAsync = ref.watch(endedSessionsProvider(user.uid));

              return Column(
                children: [
                  Padding(
                    padding: AppDimensions.screenPadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppBranding(compact: true),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: sessionsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (e, st) => Center(
                        child: Text(
                          'Error loading sessions',
                          style: context.bodyLarge,
                        ),
                      ),
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return Center(
                            child: Text(
                              'No completed sessions yet',
                              style: context.bodyLarge.copyWith(
                                color: context.textMuted,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            return GlassCard(
                              onTap: () => context.push(
                                '/history/results/${session.id}',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.title,
                                      style: context.headlineMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Code: ${session.code}',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            color: context.textMuted,
                                          ),
                                        ),
                                        Text(
                                          'Participants: ${session.participantCount}',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            color: context.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
