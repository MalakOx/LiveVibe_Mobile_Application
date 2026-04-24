import 'package:flutter/material.dart';

/// Standardized animation durations and curves
abstract class AppAnimations {
  // Duration presets
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSlower = Duration(milliseconds: 700);
  static const Duration durationHeroic = Duration(milliseconds: 800);
  static const Duration durationExtra = Duration(milliseconds: 1000);

  // Curve presets
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveQuick = Curves.easeOut;
  static const Curve curveSmooth = Curves.easeInOutCubic;
  static const Curve curveElastic = Curves.elasticOut;
  static const Curve curveSpring = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;

  // Common animation combinations
  static const Duration dialogDuration = durationNormal;
  static const Curve dialogCurve = curveDefault;

  static const Duration navigationDuration = durationSlow;
  static const Curve navigationCurve = curveSmooth;

  static const Duration buttonPressDuration = durationFast;
  static const Curve buttonPressCurve = Curves.easeOut;

  static const Duration cardEnterDuration = durationNormal;
  static const Curve cardEnterCurve = Curves.easeOut;

  // Stagger delays for multiple items
  static Duration staggerDelay(int index, {Duration baseDuration = durationFast}) {
    return Duration(milliseconds: index * baseDuration.inMilliseconds ~/ 3);
  }

  // Tween animations
  static Animation<double> createScaleAnimation({
    required AnimationController controller,
    double begin = 0.9,
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curveDefault),
    );
  }

  static Animation<double> createFadeAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curveDefault),
    );
  }

  static Animation<Offset> createSlideAnimation({
    required AnimationController controller,
    Offset begin = const Offset(0.0, 0.5),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curveDefault),
    );
  }
}
