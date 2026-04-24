import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/pulse_button.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../data/models/slide_model.dart';
import '../../domain/providers/session_provider.dart';

class SlideEditorScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SlideEditorScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SlideEditorScreen> createState() => _SlideEditorScreenState();
}

class _SlideEditorScreenState extends ConsumerState<SlideEditorScreen> {
  SlideType _selectedType = SlideType.mcq;
  AnswerMode _answerMode = AnswerMode.single;  // NEW
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctIndex = 0;
  Set<int> _correctIndices = {};  // NEW: For multiple answers
  int _timeLimit = 30;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) c.dispose();
    super.dispose();
  }

  Future<void> _saveSlide(List<SlideModel> existingSlides) async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question cannot be empty')),
      );
      return;
    }

    final options = _selectedType == SlideType.mcq
        ? _optionControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList()
        : <String>[];

    if (_selectedType == SlideType.mcq && options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 options')),
      );
      return;
    }

    // Validate correct answers
    if (_selectedType == SlideType.mcq) {
      if (_answerMode == AnswerMode.single && _correctIndex < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select the correct answer')),
        );
        return;
      }
      if (_answerMode == AnswerMode.multiple && _correctIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one correct answer')),
        );
        return;
      }
    }

    try {
      // Create the slide
      final slideId = await ref.read(sessionControllerProvider.notifier).addSlide(
        sessionId: widget.sessionId,
        type: _selectedType,
        order: existingSlides.length,
      );

      // Update the slide with the actual question, options, and correct answer
      await ref.read(sessionControllerProvider.notifier).updateSlide(
        widget.sessionId,
        slideId,
        {
          'question': _questionController.text.trim(),
          'options': options,
          if (_selectedType == SlideType.mcq && _answerMode == AnswerMode.single)
            'correctOptionIndex': _correctIndex,
          if (_selectedType == SlideType.mcq && _answerMode == AnswerMode.multiple)
            'correctOptionIndices': _correctIndices.toList(),
          'answerMode': _answerMode.name,
          'timeLimit': _timeLimit,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slide added!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Reset form
        setState(() {
          _questionController.clear();
          for (final c in _optionControllers) c.clear();
          _correctIndex = 0;
          _correctIndices.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _goLive(int slideCount) async {
    if (slideCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one slide to start')),
      );
      return;
    }

    try {
      // Navigate to host dashboard (QR code, code, participants)
      // Status remains "waiting" - host will click "Start Session" button from dashboard
      if (mounted) {
        context.go('/host/session/${widget.sessionId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final slidesAsync = ref.watch(slidesStreamProvider(widget.sessionId));

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: context.bgCard.withOpacity(0.8),
                  border: Border(
                    bottom: BorderSide(
                      color: context.divider,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.textPrimary,
                        size: 18,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Slide Editor',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const ThemeToggleButton(),
                    const SizedBox(width: 12),
                    slidesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (slides) => slides.isEmpty
                          ? Tooltip(
                              message: 'Add at least one slide to start',
                              child: Text(
                                'Add slides first',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: context.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _goLive(slides.length),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Start ${slides.length} Slide${slides.length != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Slide Type Selector
                      _buildTypeSelector(),
                      const SizedBox(height: 20),

                      // Question field
                      _buildQuestionField(),
                      const SizedBox(height: 16),

                      // Type-specific options
                      if (_selectedType == SlideType.mcq) ...[
                        _buildAnswerModeSelector(),
                        const SizedBox(height: 16),
                      ],
                      
                      if (_selectedType == SlideType.mcq)
                        _buildMCQOptions(),

                      if (_selectedType == SlideType.mcq) ...[
                        const SizedBox(height: 16),
                        _buildMCQSettings(),
                      ],

                      const SizedBox(height: 24),

                      // Save button
                      slidesAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (slides) => PulseButton(
                          label: 'Add Slide',
                          icon: Icon(
                            Icons.add_rounded,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textPrimary
                                : AppColors.bgCardLight,
                            size: 22,
                          ),
                          onPressed: () => _saveSlide(slides),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Existing slides
                      slidesAsync.when(
                        loading: () => const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        error: (e, _) => Text('Error: $e'),
                        data: (slides) => slides.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Added Slides',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 12),
                                  ...slides.asMap().entries.map((e) =>
                                      _buildExistingSlide(
                                          context, e.value, e.key + 1)),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [
      {
        'type': SlideType.mcq,
        'icon': Icons.check_circle_outline_rounded,
        'label': 'Multiple\nChoice',
        'color': context.primaryColor,
      },
      {
        'type': SlideType.openText,
        'icon': Icons.text_fields_rounded,
        'label': 'Open\nText',
        'color': context.secondaryColor,
      },
      {
        'type': SlideType.wordCloud,
        'icon': Icons.cloud_rounded,
        'label': 'Word\nCloud',
        'color': context.accentColor,
      },
    ];

    return Row(
      children: types.map((t) {
        final isSelected = _selectedType == t['type'];
        final color = t['color'] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = t['type'] as SlideType),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : context.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? color
                      : context.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(t['icon'] as IconData, color: color, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    t['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? color
                          : context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _questionController,
            maxLines: 3,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'What would you like to ask?',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerModeSelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Answer Mode',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _answerMode = AnswerMode.single;
                    _correctIndices.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _answerMode == AnswerMode.single
                          ? context.primaryColor.withOpacity(0.15)
                          : context.bgElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _answerMode == AnswerMode.single
                            ? context.primaryColor
                            : context.bgElevated,
                        width: _answerMode == AnswerMode.single ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.radio_button_checked_rounded,
                          color: _answerMode == AnswerMode.single
                              ? context.primaryColor
                              : context.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Single Answer',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _answerMode == AnswerMode.single
                                ? context.primaryColor
                                : context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _answerMode = AnswerMode.multiple;
                    _correctIndex = -1;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _answerMode == AnswerMode.multiple
                          ? context.secondaryColor.withOpacity(0.15)
                          : context.bgElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _answerMode == AnswerMode.multiple
                            ? context.secondaryColor
                            : context.bgElevated,
                        width: _answerMode == AnswerMode.multiple ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_box_rounded,
                          color: _answerMode == AnswerMode.multiple
                              ? context.secondaryColor
                              : context.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Multiple Answers',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _answerMode == AnswerMode.multiple
                                ? context.secondaryColor
                                : context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMCQOptions() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANSWER OPTIONS',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (i) {
            final color = AppColors.mcqColors[i];
            final isCorrect = _answerMode == AnswerMode.single
                ? _correctIndex == i
                : _correctIndices.contains(i);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_answerMode == AnswerMode.single) {
                          _correctIndex = i;
                        } else {
                          if (_correctIndices.contains(i)) {
                            _correctIndices.remove(i);
                          } else {
                            _correctIndices.add(i);
                          }
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? context.successColor.withOpacity(0.2)
                            : context.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect ? context.successColor : context.bgElevated,
                          width: isCorrect ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: _answerMode == AnswerMode.single
                            ? Text(
                                String.fromCharCode(65 + i),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isCorrect ? context.successColor : color,
                                ),
                              )
                            : Icon(
                                isCorrect
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                color: isCorrect ? context.successColor : context.textMuted,
                                size: 16,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _optionControllers[i],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Option ${String.fromCharCode(65 + i)}',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: color.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: color.withOpacity(0.2)),
                        ),
                      ),
                    ),
                  ),
                  if (isCorrect) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 18,
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            _answerMode == AnswerMode.single
                ? 'Tap letter to mark as correct answer'
                : 'Tap to select/deselect correct answers',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMCQSettings() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SETTINGS',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.timer_rounded, color: context.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Time Limit',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              ...[ 15, 30, 60, 90].map((t) => GestureDetector(
                    onTap: () => setState(() => _timeLimit = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _timeLimit == t
                            ? context.primaryColor.withOpacity(0.2)
                            : context.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _timeLimit == t
                              ? context.primaryColor
                              : context.bgElevated,
                        ),
                      ),
                      child: Text(
                        '${t}s',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _timeLimit == t
                              ? context.primaryColor
                              : context.textMuted,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExistingSlide(
      BuildContext context, SlideModel slide, int number) {
    final typeIcons = {
      SlideType.mcq: Icons.check_circle_outline_rounded,
      SlideType.openText: Icons.text_fields_rounded,
      SlideType.wordCloud: Icons.cloud_rounded,
    };
    final typeColors = {
      SlideType.mcq: context.primaryColor,
      SlideType.openText: context.secondaryColor,
      SlideType.wordCloud: context.accentColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: typeColors[slide.type]!.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            typeIcons[slide.type],
            color: typeColors[slide.type],
            size: 18,
          ),
        ),
        title: Text(
          slide.question,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$number',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await ref
                    .read(sessionControllerProvider.notifier)
                    .deleteSlide(widget.sessionId, slide.id);
              },
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * number))
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }
}