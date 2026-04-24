import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../session/data/models/slide_model.dart';
import '../../../session/data/models/response_model.dart';

class ResultBarChart extends StatefulWidget {
  final SlideModel slide;
  final List<ResponseModel> responses;
  final bool isLiveSession;
  final int totalParticipants;
  final bool allParticipantsResponded;

  const ResultBarChart({
    super.key,
    required this.slide,
    required this.responses,
    this.isLiveSession = true,
    this.totalParticipants = 0,
    this.allParticipantsResponded = false,
  });

  @override
  State<ResultBarChart> createState() => _ResultBarChartState();
}

class _ResultBarChartState extends State<ResultBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ResultBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when all participants respond
    if (widget.allParticipantsResponded && !oldWidget.allParticipantsResponded) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final barBackgroundColor = context.bgElevated;
    
    if (widget.slide.options.isEmpty) return const SizedBox.shrink();

    final counts = <int, int>{};
    for (var i = 0; i < widget.slide.options.length; i++) {
      counts[i] = 0;
    }
    for (final r in widget.responses) {
      if (r.selectedOptionIndex != null) {
        counts[r.selectedOptionIndex!] =
            (counts[r.selectedOptionIndex!] ?? 0) + 1;
      }
    }

    final maxCount = counts.values.isEmpty
        ? 1
        : counts.values.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Results',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.slide.options.asMap().entries.map((entry) {
          final i = entry.key;
          final option = entry.value;
          final count = counts[i] ?? 0;
          final ratio = count / maxCount;
          final isCorrect = widget.slide.correctOptionIndex == i;
          final color = isCorrect
              ? AppColors.success
              : AppColors.mcqColors[i % AppColors.mcqColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? color : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isCorrect && !widget.isLiveSession)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                    // Show animated checkmark when all participants respond
                    if (isCorrect && widget.allParticipantsResponded && widget.isLiveSession)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.success,
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(width: 8),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: barBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        height: 32,
                        width: ratio * (MediaQuery.of(context).size.width - 80),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.9),
                              color,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isCorrect && widget.allParticipantsResponded
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: 100 * i))
              .fadeIn()
              .slideX(begin: -0.1, end: 0);
        }),
      ],
    );
  }
}