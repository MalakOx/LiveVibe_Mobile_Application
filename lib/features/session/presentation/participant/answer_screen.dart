import 'dart:async';
import 'dart:math';
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
import '../../domain/providers/session_provider.dart';

class AnswerScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String participantId;

  const AnswerScreen({
    super.key,
    required this.sessionId,
    required this.participantId,
  });

  @override
  ConsumerState<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends ConsumerState<AnswerScreen> {
  final _textController = TextEditingController();
  int? _selectedOption;
  Set<int> _selectedOptions = {};  // NEW: for multiple answers
  bool _hasSubmitted = false;
  bool _isSubmitting = false;
  String? _lastSlideId;
  DateTime? _slideStartTime;
  bool? _wasCorrect;
  bool _isPartial = false;  // NEW: track partial answers
  int _pointsEarned = 0;
  
  // Timer tracking
  int _timerRemaining = 0;
  Timer? _timerCountdown;
  DateTime? _timerStartTime;

  @override
  void dispose() {
    _textController.dispose();
    _timerCountdown?.cancel();
    super.dispose();
  }

  void _onSlideChanged(String slideId) {
    if (_lastSlideId != slideId) {
      setState(() {
        _lastSlideId = slideId;
        _hasSubmitted = false;
        _selectedOption = null;
        _selectedOptions.clear();
        _wasCorrect = null;
        _isPartial = false;  // Reset partial state
        _pointsEarned = 0;
        _textController.clear();
        _slideStartTime = DateTime.now();
      });
      // Reset timer countdown
      _timerCountdown?.cancel();
      _timerRemaining = 0;
    }
  }

  void _startTimerCountdown(int seconds) {
    _timerCountdown?.cancel();
    _timerStartTime = DateTime.now();
    _timerRemaining = seconds;
    
    _timerCountdown = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      
      final elapsed = DateTime.now().difference(_timerStartTime!).inMilliseconds;
      final remaining = max(0, seconds * 1000 - elapsed) ~/ 1000;
      
      setState(() {
        _timerRemaining = remaining;
      });
      
      if (remaining <= 0) {
        _timerCountdown?.cancel();
      }
    });
  }

  void _toggleOption(SlideModel slide, int optionIndex, bool timerActive) {
    // Block if timer is not active
    if (!timerActive) {
      context.showErrorSnackBar('⏱️ Wait for the host to start the timer!');
      return;
    }
    
    if (_hasSubmitted) return;
    
    setState(() {
      if (slide.answerMode == AnswerMode.single) {
        _selectedOption = optionIndex;
      } else {
        if (_selectedOptions.contains(optionIndex)) {
          _selectedOptions.remove(optionIndex);
        } else {
          _selectedOptions.add(optionIndex);
        }
      }
    });
  }

  Future<void> _submitMCQ(SlideModel slide, bool timerActive) async {
    // Block if timer is not active
    if (!timerActive) {
      context.showErrorSnackBar('⏱️ The host must start the timer first!');
      return;
    }
    
    if (_hasSubmitted || _isSubmitting) return;

    final responseTime = DateTime.now()
            .difference(_slideStartTime ?? DateTime.now())
            .inMilliseconds;
    
    // Validate selection
    if (slide.answerMode == AnswerMode.single && _selectedOption == null) {
      context.showErrorSnackBar('Please select an answer');
      return;
    }
    if (slide.answerMode == AnswerMode.multiple && _selectedOptions.isEmpty) {
      context.showErrorSnackBar('Please select at least one answer');
      return;
    }

    // Check if answer is correct (support both single and multiple)
    // For multiple choice: allow partial answers
    final scoringService = ref.read(scoringServiceProvider);

    final bool isCorrect;
    bool isPartial = false; // Track if answer is partially correct

    if (slide.answerMode == AnswerMode.multiple) {
      isPartial = scoringService.isPartialCorrect(
        selectedIndices: _selectedOptions,
        correctIndices: slide.correctOptionIndices,
      );
      isCorrect = scoringService.isFullyCorrect(
        selectedIndex: null,
        correctIndex: null,
        selectedIndices: _selectedOptions,
        correctIndices: slide.correctOptionIndices,
      );
    } else {
      isCorrect = scoringService.isFullyCorrect(
        selectedIndex: _selectedOption,
        correctIndex: slide.correctOptionIndex,
        selectedIndices: {},
        correctIndices: [],
      );
      isPartial = false;
    }

    setState(() {
      _isSubmitting = true;
      _wasCorrect = isCorrect || isPartial ? true : false; // Show feedback for both
      _isPartial = isPartial;  // Store partial state
    });

    try {
      final selectedValue = slide.answerMode == AnswerMode.single
          ? slide.options[_selectedOption!]
          : _selectedOptions.map((i) => slide.options[i]).join(', ');

      // Calculate points using ScoringService
      final pointsEarned = scoringService.calculatePoints(
        isCorrect: isCorrect,
        isPartial: isPartial,
        responseTimeMs: responseTime,
        timeLimitSeconds: slide.timeLimit,
      );
      _pointsEarned = pointsEarned;

      await ref.read(responseControllerProvider.notifier).submitResponse(
        sessionId: widget.sessionId,
        slideId: slide.id,
        participantId: widget.participantId,
        participantName: 'Participant',
        type: SlideType.mcq,
        value: selectedValue,
        selectedOptionIndex: slide.answerMode == AnswerMode.single ? _selectedOption : null,
        isCorrect: isCorrect,
        correctOptionIndex: slide.correctOptionIndex,
        responseTimeMs: responseTime,
        timeLimit: slide.timeLimit,
      );

      setState(() {
        _hasSubmitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitText(SlideModel slide, bool timerActive) async {
    // Block if timer is not active
    if (!timerActive) {
      context.showErrorSnackBar('⏱️ The host must start the timer first!');
      return;
    }
    
    if (_hasSubmitted || _isSubmitting) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(responseControllerProvider.notifier).submitResponse(
        sessionId: widget.sessionId,
        slideId: slide.id,
        participantId: widget.participantId,
        participantName: 'Participant',
        type: slide.type,
        value: text,
        responseTimeMs: DateTime.now()
            .difference(_slideStartTime ?? DateTime.now())
            .inMilliseconds,
      );
      setState(() {
        _hasSubmitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionStreamProvider(widget.sessionId));
    final slidesAsync = ref.watch(slidesStreamProvider(widget.sessionId));
    final participantsAsync = ref.watch(participantsStreamProvider(widget.sessionId));

    ref.listen(sessionStreamProvider(widget.sessionId), (prev, next) {
      next.whenData((session) {
        if (session.status == SessionStatus.ended) {
          // Navigate to unified final dashboard
          context.pushReplacement(
            '/session/final/${widget.sessionId}/${widget.participantId}',
          );
        }
        
        // Handle timer state changes
        if (session.timerActive && !(_timerCountdown?.isActive ?? false)) {
          _startTimerCountdown(session.timerSeconds);
        } else if (!session.timerActive) {
          _timerCountdown?.cancel();
          setState(() {
            _timerRemaining = 0;
          });
        }
      });
    });

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: sessionAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (session) => slidesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (slides) {
                if (slides.isEmpty) return _buildWaitingState(context);

                final currentSlide = slides.firstWhere(
                  (s) => s.id == session.currentSlideId,
                  orElse: () => slides[session.currentSlideIndex
                      .clamp(0, slides.length - 1)],
                );

                // Detect slide change
                if (_lastSlideId != currentSlide.id) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _onSlideChanged(currentSlide.id);
                  });
                }

                return Column(
                  children: [
                    // Participants bar
                    _buildParticipantsBar(context, participantsAsync),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Slide progress header
                            _buildProgressHeader(
                                context, session, slides, currentSlide),
                            const SizedBox(height: 20),
                            Expanded(
                              child: _hasSubmitted
                                  ? _buildSubmittedState(
                                      context, currentSlide)
                                  : _buildAnswerContent(
                                      context, currentSlide, session),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsBar(BuildContext context, AsyncValue<List> participantsAsync) {
    return participantsAsync.when(
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox(height: 60),
      data: (participants) {
        if (participants.isEmpty) return const SizedBox(height: 60);
        
        // Sort by score descending
        final sorted = List.from(participants)
          ..sort((a, b) => b.score.compareTo(a.score));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.bgCard.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(color: context.divider.withOpacity(0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded,
                      size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    '${participants.length} Participants',
                    style: context.labelSmall.copyWith(
                      color: context.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final p = sorted[i];
                    return Container(
                      margin: EdgeInsets.only(right: i < sorted.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: i == 0
                              ? AppColors.accentYellow.withOpacity(0.5)
                              : context.bgElevated,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.avatar,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.name,
                                style: context.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${p.score} pts',
                                style: context.labelSmall.copyWith(
                                  fontSize: 9,
                                  color: context.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressHeader(
    BuildContext context,
    SessionModel session,
    List<SlideModel> slides,
    SlideModel currentSlide,
  ) {
    return Row(
      children: [
        ...slides.asMap().entries.map((e) {
          final isCurrent = e.value.id == currentSlide.id;
          final isPast = e.key < session.currentSlideIndex;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: e.key < slides.length - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: isPast
                    ? AppColors.secondary
                    : isCurrent
                        ? AppColors.primary
                        : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnswerContent(
    BuildContext context,
    SlideModel slide,
    SessionModel session,
  ) {
    switch (slide.type) {
      case SlideType.mcq:
        return _buildMCQAnswer(context, slide, session);
      case SlideType.openText:
        return _buildOpenTextAnswer(context, slide, session);
      case SlideType.wordCloud:
        return _buildWordCloudAnswer(context, slide, session);
    }
  }

  Widget _buildMCQAnswer(
    BuildContext context,
    SlideModel slide,
    SessionModel session,
  ) {
    return Column(
      children: [
        // Timer
        if (session.timerActive)
          _buildParticipantTimer(session)
        else
          _buildWaitingForTimerWidget(),

        // Answer Mode Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: slide.answerMode == AnswerMode.single
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.secondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                slide.answerMode == AnswerMode.single
                    ? Icons.radio_button_checked_rounded
                    : Icons.check_box_rounded,
                size: 14,
                color: slide.answerMode == AnswerMode.single
                    ? AppColors.primary
                    : AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                slide.answerMode == AnswerMode.single
                    ? 'Select one answer'
                    : 'Select multiple answers',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: slide.answerMode == AnswerMode.single
                      ? AppColors.primary
                      : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        GlassCard(
          child: Text(
            slide.question,
            style: context.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 20),

        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: slide.options.asMap().entries.map((entry) {
              final i = entry.key;
              final option = entry.value;
              final color = AppColors.mcqColors[i % AppColors.mcqColors.length];
              final isSelected = slide.answerMode == AnswerMode.single
                  ? _selectedOption == i
                  : _selectedOptions.contains(i);
              final isEnabled = session.timerActive && !_hasSubmitted;

              return GestureDetector(
                onTap: isEnabled ? () => _toggleOption(slide, i, session.timerActive) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected && isEnabled
                        ? LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          )
                        : null,
                    color: isSelected && isEnabled
                        ? null
                        : color.withOpacity(isEnabled ? 0.1 : 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected && isEnabled
                          ? color
                          : color.withOpacity(isEnabled ? 0.3 : 0.15),
                      width: isSelected && isEnabled ? 2 : 1.5,
                    ),
                    boxShadow: isSelected && isEnabled
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (slide.answerMode == AnswerMode.single)
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isEnabled ? color : color.withOpacity(0.4),
                              size: 20,
                            )
                          else
                            Icon(
                              isSelected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: isEnabled ? color : color.withOpacity(0.4),
                              size: 20,
                            ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected && isEnabled
                                    ? Colors.white
                                    : isEnabled
                                        ? context.textPrimary
                                        : color.withOpacity(0.4),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Submit button
        if (!_hasSubmitted)
          ElevatedButton.icon(
            onPressed: session.timerActive && !_isSubmitting ? () => _submitMCQ(slide, session.timerActive) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: session.timerActive ? AppColors.primary : AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              disabledBackgroundColor: AppColors.textMuted,
            ),
            icon: Icon(
              _isSubmitting ? Icons.hourglass_bottom_rounded : Icons.check_rounded,
              color: Colors.white,
            ),
            label: Text(
              _isSubmitting ? 'Submitting...' : 'Submit Response',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )
        else
          _buildSubmittedState(context, slide),
      ],
    );
  }

  Widget _buildParticipantTimer(SessionModel session) {
    final ratio = _timerRemaining / max(1, session.timerSeconds);
    final urgentColor = _timerRemaining <= 5
        ? AppColors.error
        : _timerRemaining <= 10
            ? AppColors.warning
            : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.bgElevated),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer circle
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  backgroundColor: context.bgElevated,
                  valueColor: AlwaysStoppedAnimation(urgentColor),
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '$_timerRemaining',
                    style: context.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: urgentColor,
                    ),
                  ).animate(
                    target: _timerRemaining <= 5 ? 1 : 0,
                  ).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 300.ms,
                  ).then().scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Remaining',
                  style: context.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: urgentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timerRemaining <= 5 ? '⏱️ Hurry up!' : 'Answer carefully',
                  style: context.labelSmall.copyWith(
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
      begin: 0.6,
      duration: 800.ms,
    );
  }

  Widget _buildWaitingForTimerWidget() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.15),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.secondary,
              size: 28,
            ).animate(onPlay: (c) => c.repeat()).rotate(
              duration: 2.seconds,
              begin: 0,
              end: 2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for Timer...',
                  style: context.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The host will start the timer soon',
                  style: context.labelSmall.copyWith(
                    color: context.textMuted,
                  ),
                ).animate(onPlay: (c) => c.repeat()).fadeIn(
                  duration: 1.seconds,
                ).then().fadeOut(
                  duration: 1.seconds,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
      begin: const Offset(0.98, 0.98),
      end: const Offset(1.02, 1.02),
      duration: 1.5.seconds,
    );
  }

  Widget _buildOpenTextAnswer(BuildContext context, SlideModel slide, SessionModel session) {
    return Column(
      children: [
        // Timer
        if (session.timerActive)
          _buildParticipantTimer(session)
        else
          _buildWaitingForTimerWidget(),

        GlassCard(
          child: Text(
            slide.question,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 20),

        GlassCard(
          child: TextField(
            controller: _textController,
            enabled: session.timerActive,
            maxLines: 5,
            style: context.bodyLarge.copyWith(
              color: context.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Share your thoughts...',
              hintStyle: context.bodyMedium.copyWith(color: context.textMuted),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ).animate(delay: 200.ms).fadeIn(),

        const Spacer(),

        PulseButton(
          label: 'Submit Answer',
          gradient: AppColors.gradientSecondary,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : () => _submitText(slide, session.timerActive),
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }

  Widget _buildWordCloudAnswer(BuildContext context, SlideModel slide, SessionModel session) {
    return Column(
      children: [
        // Timer
        if (session.timerActive)
          _buildParticipantTimer(session)
        else
          _buildWaitingForTimerWidget(),

        GlassCard(
          child: Column(
            children: [
              const Icon(Icons.cloud_rounded, color: AppColors.accent, size: 32),
              const SizedBox(height: 12),
              Text(
                slide.question,
                style: context.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Enter one or more words',
                style: context.bodySmall.copyWith(
                  color: context.textMuted,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 20),

        GlassCard(
          borderColor: AppColors.accent.withOpacity(0.3),
          child: TextField(
            controller: _textController,
            enabled: session.timerActive,
            style: context.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Type your word(s)...',
              hintStyle: context.headlineSmall.copyWith(
                color: context.textMuted.withOpacity(0.5),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ).animate(delay: 200.ms).fadeIn(),

        const Spacer(),

        PulseButton(
          label: 'Submit',
          gradient: LinearGradient(
            colors: [AppColors.accent, AppColors.accentOrange],
          ),
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : () => _submitText(slide, session.timerActive),
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }

  Widget _buildSubmittedState(BuildContext context, SlideModel slide) {
    final isCorrect = _wasCorrect;
    final isPartial = _isPartial;  // Use stored partial state
    final isMCQ = slide.type == SlideType.mcq;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Result icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMCQ
                ? (isCorrect == true
                    ? AppColors.success.withOpacity(0.15)
                    : isPartial == true
                        ? AppColors.warning.withOpacity(0.15)
                        : isCorrect == false
                            ? AppColors.error.withOpacity(0.15)
                            : AppColors.secondary.withOpacity(0.15))
                : AppColors.secondary.withOpacity(0.15),
            border: Border.all(
              color: isMCQ
                  ? (isCorrect == true
                      ? AppColors.success
                      : isPartial == true
                          ? AppColors.warning
                          : isCorrect == false
                              ? AppColors.error
                              : AppColors.secondary)
                  : AppColors.secondary,
              width: 2,
            ),
          ),
          child: Icon(
            isMCQ
                ? (isCorrect == true
                    ? Icons.check_rounded
                    : isPartial == true
                        ? Icons.trending_up_rounded
                        : isCorrect == false
                            ? Icons.close_rounded
                            : Icons.check_rounded)
                : Icons.check_rounded,
            size: 48,
            color: isMCQ
                ? (isCorrect == true
                    ? AppColors.success
                    : isPartial == true
                        ? AppColors.warning
                        : isCorrect == false
                            ? AppColors.error
                            : AppColors.secondary)
                : AppColors.secondary,
          ),
        )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 300.ms),

        const SizedBox(height: 24),

        // Main feedback message
        Text(
          isMCQ
              ? (isCorrect == true
                  ? '✅ Correct!'
                  : isPartial == true
                      ? '⭐ Partially Correct'
                      : '❌ Incorrect')
              : '✅ Submitted!',
          style: context.displaySmall.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

        const SizedBox(height: 8),

        // Subtitle for partial answers
        if (isMCQ && isPartial == true)
          Text(
            'You selected some correct answers, but not all',
            style: context.bodyMedium.copyWith(
              color: context.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ).animate(delay: 250.ms).fadeIn(),

        const SizedBox(height: 16),

        // Points display
        if (isMCQ && (isCorrect == true || isPartial == true) && _pointsEarned > 0)
          Text(
            '+$_pointsEarned points',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.accentYellow,
            ),
          )
              .animate(delay: 400.ms)
              .fadeIn()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),

        const SizedBox(height: 12),

        Text(
          'Waiting for next question...',
          style: context.bodyLarge.copyWith(color: context.textMuted),
        ).animate(delay: 600.ms).fadeIn(),

        const SizedBox(height: 40),

        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ).animate(delay: 800.ms).fadeIn(),
      ],
    );
  }

  Widget _buildWaitingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 64,
            color: context.textMuted,
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 1.5.seconds,
              ),
          const SizedBox(height: 20),
          Text(
            'Waiting for a question...',
            style: context.titleLarge.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }
}