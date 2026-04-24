import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../data/models/session_model.dart';
import '../../domain/providers/session_provider.dart';

/// Waiting room shown to participants after joining (QR or code).
/// Shows:  session title  +  participant count
/// Does NOT show questions — questions only appear after host clicks Start Live.
class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String sessionCode;
  final String participantName;
  final String? avatar;

  const WaitingRoomScreen({
    super.key,
    required this.sessionCode,
    required this.participantName,
    this.avatar,
  });

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  late String _sessionId;
  late String _participantId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeParticipant();
  }

  Future<void> _initializeParticipant() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .where('code', isEqualTo: widget.sessionCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() { _error = 'Session not found'; _isLoading = false; });
        return;
      }

      final sessionDoc = querySnapshot.docs.first;
      _sessionId = sessionDoc.id;

      final participantRef = FirebaseFirestore.instance
          .collection('sessions')
          .doc(_sessionId)
          .collection('participants')
          .doc();
      _participantId = participantRef.id;

      final session = sessionDoc.data();
      final status = session['status'] ?? 'waiting';

      final participantData = {
        'name': widget.participantName,
        'isOnline': true,
        'joinedAt': FieldValue.serverTimestamp(),
        'score': 0,
        'rank': 0,
        'streak': 0,
        'avatar': widget.avatar ?? _fallbackAvatar(widget.participantName),
        'answeredSlides': <String>[],
      };

      if (status == 'ended') {
        await participantRef.set(participantData);
        if (mounted) context.go('/session/final/$_sessionId/$_participantId');
        return;
      }

      await participantRef.set(participantData);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = 'Error joining session: $e'; _isLoading = false; });
    }
  }

  String _fallbackAvatar(String name) =>
      name.isEmpty ? '👤' : name[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: AnimatedGradientBg(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.secondary),
                const SizedBox(height: 20),
                Text(
                  'Joining session…',
                  style: context.bodyMedium.copyWith(color: context.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: AnimatedGradientBg(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 72, color: AppColors.error),
                  const SizedBox(height: 20),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: context.bodyLarge.copyWith(color: context.textPrimary),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.go('/participant/entry'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to Entry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _WaitingRoomContent(
      sessionId: _sessionId,
      participantId: _participantId,
      participantName: widget.participantName,
    );
  }
}

class _WaitingRoomContent extends ConsumerStatefulWidget {
  final String sessionId;
  final String participantId;
  final String participantName;

  const _WaitingRoomContent({
    required this.sessionId,
    required this.participantId,
    required this.participantName,
  });

  @override
  ConsumerState<_WaitingRoomContent> createState() => _WaitingRoomContentState();
}

class _WaitingRoomContentState extends ConsumerState<_WaitingRoomContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync    = ref.watch(sessionStreamProvider(widget.sessionId));
    final participantsAsync = ref.watch(participantsStreamProvider(widget.sessionId));

    // Listen for session status changes — navigate when host starts or ends
    ref.listen(sessionStreamProvider(widget.sessionId), (_, next) {
      next.whenData((session) {
        if (session.status == SessionStatus.live) {
          context.pushReplacement(
            '/session/answer/${widget.sessionId}/${widget.participantId}',
          );
        } else if (session.status == SessionStatus.ended) {
          context.go('/session/final/${widget.sessionId}/${widget.participantId}');
        }
      });
    });

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: sessionAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (session) => _buildContent(context, session, participantsAsync),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SessionModel session,
    AsyncValue<List> participantsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // ── Animated Waiting Orb ──────────────────────────────
          ScaleTransition(
            scale: _pulseAnim,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientSecondary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Session Title (KEY FIX) ───────────────────────────
          Text(
            session.title,
            textAlign: TextAlign.center,
            style: context.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          // ── Status Label ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 700.ms),
                const SizedBox(width: 8),
                Text(
                  'Waiting for host to start',
                  style: context.labelMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 40),

          // ── Participant Count Card ────────────────────────────
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                participantsAsync.when(
                  loading: () => const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('–'),
                  data: (participants) => Text(
                    '${participants.length}',
                    style: context.displaySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'players joined',
                  style: context.bodyLarge.copyWith(color: context.textMuted),
                ),
              ],
            ),
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),

          const SizedBox(height: 24),

          // ── Your Name Badge ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Playing as ',
                  style: context.bodyMedium.copyWith(color: context.textMuted),
                ),
                Text(
                  widget.participantName,
                  style: context.bodyMedium.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(),

          const Spacer(),

          // ── Bottom Hint ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              'Questions will appear once the session begins.',
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(
                color: context.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ).animate(delay: 600.ms).fadeIn(),
        ],
      ),
    );
  }
}
