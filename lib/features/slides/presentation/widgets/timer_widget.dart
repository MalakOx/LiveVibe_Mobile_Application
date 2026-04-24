import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../session/data/models/session_model.dart';

class TimerWidget extends StatefulWidget {
  final String sessionId;
  final SessionModel session;
  final Function(bool active) onToggle;

  const TimerWidget({
    super.key,
    required this.sessionId,
    required this.session,
    required this.onToggle,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int _remaining;
  Timer? _timer;
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.session.timerSeconds;
    _syncTimer();
  }

  @override
  void didUpdateWidget(TimerWidget old) {
    super.didUpdateWidget(old);
    if (widget.session.timerActive && !_wasActive) {
      _remaining = widget.session.timerSeconds;
      _startCountdown();
    } else if (!widget.session.timerActive && _wasActive) {
      _stopCountdown();
    }
    _wasActive = widget.session.timerActive;
  }

  void _syncTimer() {
    _wasActive = widget.session.timerActive;
    if (widget.session.timerActive) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _stopCountdown();
          widget.onToggle(false);
        }
      });
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.session.timerActive;
    final ratio = _remaining / widget.session.timerSeconds.clamp(1, 999);
    final urgentColor = _remaining <= 5
        ? AppColors.error
        : _remaining <= 10
            ? AppColors.warning
            : AppColors.secondary;

    return Row(
      children: [
        // Timer circle
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: isActive ? ratio : 1.0,
                backgroundColor: AppColors.bgElevated,
                valueColor: AlwaysStoppedAnimation(urgentColor),
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  isActive ? '$_remaining' : '${widget.session.timerSeconds}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isActive ? urgentColor : AppColors.textMuted,
                  ),
                ).animate(
                  target: _remaining <= 5 && isActive ? 1 : 0,
                ).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  duration: 300.ms,
                ).then().scale(
                  begin: const Offset(1.15, 1.15),
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
                isActive ? 'Timer Running' : 'Timer Ready',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? urgentColor : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isActive ? 'Tap to stop' : 'Tap to start ${widget.session.timerSeconds}s',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: context.textMuted,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            if (isActive) {
              widget.onToggle(false);
            } else {
              setState(() => _remaining = widget.session.timerSeconds);
              widget.onToggle(true);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.error.withOpacity(0.15)
                  : AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? AppColors.error.withOpacity(0.4)
                    : AppColors.secondary.withOpacity(0.4),
              ),
            ),
            child: Icon(
              isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: isActive ? AppColors.error : AppColors.secondary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}