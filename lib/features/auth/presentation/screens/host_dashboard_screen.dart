import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/app_branding.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
import '../../domain/providers/auth_provider.dart';
import '../../../session/data/models/session_model.dart';

// Provider for all host's sessions (active and completed) - refreshes automatically
final hostSessionsProvider = StreamProvider.family<List<SessionModel>, String>((ref, hostId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('sessions')
      .where('hostId', isEqualTo: hostId)
      .orderBy('createdAt', descending: true)  // Single orderBy - avoids index requirement
      .snapshots()
      .map((snapshot) {
        final sessions = snapshot.docs
            .map((doc) => SessionModel.fromFirestore(doc))
            .toList();
        // Sort client-side: active sessions first, then ended sessions by date
        sessions.sort((a, b) {
          // Active sessions come first
          if (a.status != SessionStatus.ended && b.status == SessionStatus.ended) return -1;
          if (a.status == SessionStatus.ended && b.status != SessionStatus.ended) return 1;
          
          // Within each group, sort by date (most recent first)
          if (a.status == SessionStatus.ended && b.status == SessionStatus.ended) {
            return (b.endedAt ?? b.createdAt).compareTo(a.endedAt ?? a.createdAt);
          }
          return b.createdAt.compareTo(a.createdAt);
        });
        return sessions;
      });
});

class HostDashboardScreen extends ConsumerWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: AnimatedGradientBg(

        child: authState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, st) => Center(
            child: Text('Error: $e'),
          ),
          data: (user) {
            if (user == null) {
              // Redirect to auth if not logged in
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/host/auth');
              });
              return const SizedBox.shrink();
            }

            // Watch host's sessions (active and completed)
            final sessionsAsync = ref.watch(hostSessionsProvider(user.uid));

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Header with Livevibe branding
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              AppBranding(compact: true),
                              const Spacer(),
                              const ThemeToggleButton(compact: true),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _showProfileMenu(context, ref, user),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${user.displayName ?? user.email.split('@')[0]}',
                                  style: context.bodyMedium.copyWith(
                                    color: context.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Create Quiz Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => context.push('/host/create'),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create New Quiz',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Design slides and engage your audience',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate(delay: 150.ms).fadeIn(),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Recent Sessions Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Sessions',
                            style: context.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/history'),
                            child: Text(
                              'View All',
                              style: context.labelMedium.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Sessions List
                  sessionsAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Center(child: Text('Error: $e')),
                    ),
                    data: (sessions) {
                      if (sessions.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Icon(
                                            Icons.history_rounded,
                                            color: AppColors.primary,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'No sessions yet',
                                                style: context.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Create your first quiz to get started',
                                                style: context.bodySmall.copyWith(
                                                  color: context.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate(delay: 200.ms).fadeIn(),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final session = sessions[index];
                            final isActive = session.status != SessionStatus.ended;

                            return Padding(
                              padding: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: index == sessions.length - 1 ? 20 : 12,
                              ),
                              child: GlassCard(
                                onTap: () => context.push(
                                  '/history/results/${session.id}',
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: isActive
                                                  ? AppColors.gradientPrimary
                                                  : LinearGradient(
                                                      colors: [
                                                        AppColors.primary.withOpacity(0.5),
                                                        AppColors.secondary.withOpacity(0.5),
                                                      ],
                                                    ),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              isActive
                                                  ? Icons.play_arrow_rounded
                                                  : Icons.done_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  session.title,
                                                  style: context.bodyLarge.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: context.textPrimary,
                                                      ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Code: ${session.code}',
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 12,
                                                        color: context.textMuted,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      '${session.slideCount} slides',
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
                                          // Status badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? AppColors.secondary.withOpacity(0.2)
                                                  : AppColors.primary.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isActive ? 'Active' : 'Ended',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isActive
                                                    ? AppColors.secondary
                                                    : AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate(delay: (100 + index * 50).ms).fadeIn();
                          },
                          childCount: sessions.length,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref, user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: context.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Email display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.bgElevated.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: context.bodySmall.copyWith(
                              color: context.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: context.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sign out button
                    PulseButton(
                      label: 'Sign Out',
                      gradient: LinearGradient(
                        colors: [AppColors.error.withOpacity(0.8), AppColors.error],
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/participant/entry');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
