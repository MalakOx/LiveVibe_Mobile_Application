import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

class PageContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 600 ? AppDimensions.md : AppDimensions.lg;
    final effectiveMaxWidth = maxWidth ?? 1200.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppDimensions.md,
              ),
          child: child,
        ),
      ),
    );
  }
}