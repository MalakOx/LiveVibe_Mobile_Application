import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';

/// Full-screen animated gradient background.
/// Animates smoothly between two gradient positions for a living feel.
/// Colors adapt to light / dark mode.
class AnimatedGradientBg extends ConsumerStatefulWidget {
  final Widget child;

  const AnimatedGradientBg({super.key, required this.child});

  @override
  ConsumerState<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends ConsumerState<AnimatedGradientBg>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _topLeft;
  late Animation<Alignment> _bottomRight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _topLeft = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topLeft, end: Alignment.topCenter),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topCenter, end: Alignment.centerLeft),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _bottomRight = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomCenter),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomCenter, end: Alignment.centerRight),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeNotifierProvider);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _topLeft.value,
              end: _bottomRight.value,
              colors: isDark
                  ? const [
                      AppColors.bgDark,
                      Color(0xFF1C2138),
                      AppColors.bgDark,
                    ]
                  : const [
                      AppColors.bgLight,
                      AppColors.bgSurfaceLight,
                      AppColors.bgLight,
                    ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
