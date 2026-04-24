import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../session/data/models/response_model.dart';

class WordCloudWidget extends StatelessWidget {
  final List<ResponseModel> responses;

  const WordCloudWidget({super.key, required this.responses});

  Map<String, int> _buildFrequencyMap() {
    final freq = <String, int>{};
    for (final r in responses) {
      final words = r.value
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty && w.length > 1)
          .toList();
      for (final word in words) {
        final clean = word.replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ]'), '');
        if (clean.isNotEmpty) {
          freq[clean] = (freq[clean] ?? 0) + 1;
        }
      }
    }
    return freq;
  }

  @override
  Widget build(BuildContext context) {
    final freq = _buildFrequencyMap();

    if (freq.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.bgElevated),
        ),
        child: Center(
          child: Text(
            'Waiting for words...',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: context.textMuted,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top30 = sorted.take(30).toList();
    final maxFreq = top30.first.value.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.bgElevated),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Word Cloud',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${freq.length} unique word${freq.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: context.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Word Cloud Layout
          SizedBox(
            height: 260,
            child: _WordCloudCanvas(words: top30, maxFreq: maxFreq),
          ),
          const SizedBox(height: 16),
          // Top Words Bar
          ...top30.take(5).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final word = entry.value;
            final ratio = word.value / maxFreq;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      word.key,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 18,
                            color: context.bgElevated,
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 400 + (i * 100).toInt()),
                            curve: Curves.easeOutCubic,
                            height: 18,
                            width: ratio * (MediaQuery.of(context).size.width - 180),
                            color: AppColors.wordCloudColors[
                                i % AppColors.wordCloudColors.length],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${word.value}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WordCloudCanvas extends StatelessWidget {
  final List<MapEntry<String, int>> words;
  final double maxFreq;

  const _WordCloudCanvas({required this.words, required this.maxFreq});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _WordCloudPainter(
            words: words,
            maxFreq: maxFreq,
          ),
        );
      },
    );
  }
}

class _WordCloudPainter extends CustomPainter {
  final List<MapEntry<String, int>> words;
  final double maxFreq;

  _WordCloudPainter({required this.words, required this.maxFreq});

  @override
  void paint(Canvas canvas, Size size) {
    final placed = <Rect>[];

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final freq = word.value / maxFreq;
      final fontSize = 12.0 + (freq * 32.0);
      final color = AppColors.wordCloudColors[i % AppColors.wordCloudColors.length];

      final textPainter = TextPainter(
        text: TextSpan(
          text: word.key,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.6 + freq * 0.4),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Spiral placement algorithm
      Offset? position;
      for (var t = 0.0; t < 100; t += 0.5) {
        final angle = t * 0.5;
        final radius = t * 3.0;
        final cx = size.width / 2 + radius * cos(angle) - textPainter.width / 2;
        final cy = size.height / 2 + radius * sin(angle) - textPainter.height / 2;

        final rect = Rect.fromLTWH(
          cx - 4,
          cy - 2,
          textPainter.width + 8,
          textPainter.height + 4,
        );

        if (rect.left < 0 ||
            rect.top < 0 ||
            rect.right > size.width ||
            rect.bottom > size.height) continue;

        bool overlap = false;
        for (final p in placed) {
          if (p.overlaps(rect)) {
            overlap = true;
            break;
          }
        }

        if (!overlap) {
          position = Offset(cx, cy);
          placed.add(rect);
          break;
        }
      }

      if (position != null) {
        textPainter.paint(canvas, position);
      }
    }
  }

  @override
  bool shouldRepaint(_WordCloudPainter old) =>
      old.words.length != words.length;
}