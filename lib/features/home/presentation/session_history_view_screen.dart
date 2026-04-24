import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pulse_button.dart';
import '../../session/data/models/session_model.dart';
import '../../session/data/models/slide_model.dart';
import '../../session/domain/providers/session_provider.dart';

class SessionHistoryViewScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionHistoryViewScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<SessionHistoryViewScreen> createState() =>
      _SessionHistoryViewScreenState();
}

class _SessionHistoryViewScreenState
    extends ConsumerState<SessionHistoryViewScreen> {
  late TextEditingController _sessionNameController;
  bool _isDuplicating = false;

  @override
  void initState() {
    super.initState();
    _sessionNameController = TextEditingController();
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  Future<void> _duplicateSession(SessionModel session, List<SlideModel> slides) async {
    // Show dialog to get new session name
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Session'),
        content: TextField(
          controller: _sessionNameController,
          decoration: InputDecoration(
            hintText: '${session.title} (Copy)',
            hintStyle: TextStyle(color: context.textSecondary),
          ),
          style: Theme.of(context).inputDecorationTheme.fillColor != null
              ? TextStyle(color: context.textPrimary)
              : null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDuplication(session, slides);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDuplication(SessionModel session, List<SlideModel> slides) async {
    setState(() => _isDuplicating = true);

    try {
      final newSessionName = _sessionNameController.text.trim().isNotEmpty
          ? _sessionNameController.text.trim()
          : '${session.title} (Copy)';

      // Create new session
      final firestore = FirebaseFirestore.instance;
      final newSessionDoc = await firestore.collection('sessions').add({
        'title': newSessionName,
        'code': IdGenerator.generateSessionCode(),
        'hostId': session.hostId,
        'hostName': session.hostName,
        'status': 'waiting',
        'currentSlideIndex': 0,
        'timerSeconds': 30,
        'timerActive': false,
        'participantCount': 0,
        'slideCount': slides.length,
        'createdAt': FieldValue.serverTimestamp(),
        'settings': {
          'showLeaderboard': true,
          'allowLateJoin': true,
          'shuffleOptions': false,
        },
      });

      // Copy all slides
      for (int i = 0; i < slides.length; i++) {
        final slide = slides[i];
        await newSessionDoc.collection('slides').add({
          'type': slide.type.name,
          'question': slide.question,
          'options': slide.options,
          'correctOptionIndex': slide.correctOptionIndex,
          'correctOptionIndices': slide.correctOptionIndices,
          'answerMode': slide.answerMode.name,
          'timeLimit': slide.timeLimit,
          'order': i,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        _sessionNameController.clear();
        // Navigate to the new session editor
        context.go('/host/editor/${newSessionDoc.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDuplicating = false);
      }
    }
  }



  Future<void> _deleteSession(String sessionId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Use theme-aware colors, NOT hardcoded dark colors
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Delete Session?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ) ?? const TextStyle(fontFamily: 'Outfit'),
        ),
        content: Text(
          'This action cannot be undone. All slides and data will be permanently deleted.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ) ?? const TextStyle(fontFamily: 'Outfit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final firestore = FirebaseFirestore.instance;
                // Delete all slides first
                final slidesRef = firestore.collection('sessions').doc(sessionId).collection('slides');
                final slides = await slidesRef.get();
                for (var doc in slides.docs) {
                  await doc.reference.delete();
                }
                // Delete the session
                await firestore.collection('sessions').doc(sessionId).delete();
                
                if (mounted) {
                  context.pop(); // Close the view
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting session: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionStreamProvider(widget.sessionId));
    final slidesAsync = ref.watch(slidesStreamProvider(widget.sessionId));

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: sessionAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, st) {
              // Session was deleted - close the view after a short delay
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session has been deleted')),
                  );
                }
              });
              return const SizedBox.shrink();
            },
            data: (session) {
              return slidesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, st) => Center(
                  child: Text('Error: $e', style: Theme.of(context).textTheme.bodyLarge),
                ),
                data: (slides) {
                  return Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Code: ${session.code} • ${slides.length} slides',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: Theme.of(context).iconTheme.color),
                              onPressed: () => context.pop(),
                            ),
                          ],
                        ),
                      ),

                      // Slides List
                      Expanded(
                        child: slides.isEmpty
                            ? Center(
                                child: Text(
                                  'No slides in this session',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: slides.length,
                                itemBuilder: (context, index) {
                                  final slide = slides[index];
                                  return GlassCard(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'Q${index + 1}',
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  slide.question,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontFamily: 'Outfit',
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (slide.options.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              '${slide.options.length} options',
                                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                fontFamily: 'Outfit',
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: PulseButton(
                                label: _isDuplicating
                                    ? 'Duplicating...'
                                    : 'Duplicate & Edit',
                                gradient: AppColors.gradientPrimary,
                                isLoading: _isDuplicating,
                                onPressed: _isDuplicating
                                    ? null
                                    : () => _duplicateSession(session, slides),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _deleteSession(session.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.error,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
