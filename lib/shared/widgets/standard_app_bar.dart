import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/extensions/context_extensions.dart';
import 'standard_icon_button.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBackPressed;
  final List<Widget> actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBottomBorder;

  const StandardAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBackPressed,
    this.actions = const [],
    this.leading,
    this.centerTitle = false,
    this.showBottomBorder = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isMobile;

    return Material(
      color: context.bgCard.withOpacity(0.82),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: isCompact ? 56 : 64,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppDimensions.sm : AppDimensions.md,
          ),
          decoration: BoxDecoration(
            border: showBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: context.divider,
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              leading ??
                  StandardIconButton(
                    onPressed: onBackPressed,
                    icon: Icons.arrow_back_ios_new_rounded,
                    color: context.textPrimary,
                    tooltip: 'Back',
                  ),
              SizedBox(width: context.spacingSm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                      style: context.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodySmall.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}