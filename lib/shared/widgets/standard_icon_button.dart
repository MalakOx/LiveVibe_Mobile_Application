import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

class StandardIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? color;
  final String? tooltip;

  const StandardIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).iconTheme.color;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: AppDimensions.iconSm,
        color: effectiveColor,
      ),
    );
  }
}