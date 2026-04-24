import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

extension BuildContextExtensions on BuildContext {
  // Screen
  double get screenWidth  => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  EdgeInsets get viewInsets  => MediaQuery.of(this).viewInsets;
  bool get isMobile    => screenWidth < 600;
  bool get isTablet    => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop   => screenWidth >= 1200;
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
  bool get isPortrait  => MediaQuery.of(this).orientation == Orientation.portrait;
  double get topPadding    => viewPadding.top;
  double get bottomPadding => viewPadding.bottom;

  // Theme
  ThemeData   get theme       => Theme.of(this);
  bool        get isDarkMode  => theme.brightness == Brightness.dark;
  ColorScheme get colorScheme => theme.colorScheme;

  // Theme-aware colors
  Color get bgPrimary  => isDarkMode ? AppColors.bgDark        : AppColors.bgLight;
  Color get bgCard     => isDarkMode ? AppColors.bgCard        : AppColors.bgCardLight;
  Color get bgSurface  => isDarkMode ? AppColors.bgSurface     : AppColors.bgSurfaceLight;
  Color get bgElevated => isDarkMode ? AppColors.bgElevated    : AppColors.bgElevatedLight;
  Color get bgSubtle   => isDarkMode ? AppColors.bgCard        : AppColors.bgSubtleLight;
  Color get textPrimary   => isDarkMode ? AppColors.textPrimary   : AppColors.textPrimaryLight;
  Color get textSecondary => isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryLight;
  Color get textMuted     => isDarkMode ? AppColors.textMuted     : AppColors.textMutedLight;
  Color get textDisabled  => isDarkMode ? AppColors.textMuted     : AppColors.textDisabledLight;
  Color get border       => isDarkMode ? AppColors.bgElevated : AppColors.borderLight;
  Color get borderSubtle => isDarkMode ? AppColors.bgSurface  : AppColors.borderSubtleLight;
  Color get divider      => isDarkMode ? AppColors.bgElevated : AppColors.dividerLight;
  Color get overlay => isDarkMode ? AppColors.bgDark.withOpacity(0.5) : AppColors.overlayLight;
  Color get shadow  => isDarkMode ? Colors.black.withOpacity(0.3)     : AppColors.shadowLight;

  // Brand colors (theme-aware)
  Color get primaryColor => AppColors.primary;
  Color get secondaryColor => AppColors.secondary;
  Color get accentColor => AppColors.accent;
  Color get successColor => AppColors.success;

  // Typography — delegates to ThemeData so colors are fully theme-aware
  TextStyle get displayLarge   => theme.textTheme.displayLarge!;
  TextStyle get displayMedium  => theme.textTheme.displayMedium!;
  TextStyle get displaySmall   => theme.textTheme.displaySmall!;
  TextStyle get headlineLarge  => theme.textTheme.headlineLarge!;
  TextStyle get headlineMedium => theme.textTheme.headlineMedium!;
  TextStyle get headlineSmall  => theme.textTheme.headlineSmall!;
  TextStyle get titleLarge     => theme.textTheme.titleLarge!;
  TextStyle get titleMedium    => theme.textTheme.titleMedium!;
  TextStyle get bodyLarge      => theme.textTheme.bodyLarge!;
  TextStyle get bodyMedium     => theme.textTheme.bodyMedium!;
  TextStyle get bodySmall      => theme.textTheme.labelSmall!;
  TextStyle get labelLarge     => theme.textTheme.labelLarge!;
  TextStyle get labelMedium    => theme.textTheme.labelMedium!;
  TextStyle get labelSmall     => theme.textTheme.labelSmall!;
  TextStyle get caption        => theme.textTheme.labelSmall!;

  // Spacing
  double get spacingXs  => AppDimensions.xs;
  double get spacingSm  => AppDimensions.sm;
  double get spacingMd  => AppDimensions.md;
  double get spacingLg  => AppDimensions.lg;
  double get spacingXl  => AppDimensions.xl;
  double get spacingXxl => AppDimensions.xxl;

  // Border radius
  BorderRadius get radiusSm  => AppDimensions.borderRadiusSm;
  BorderRadius get radiusMd  => AppDimensions.borderRadiusMd;
  BorderRadius get radiusLg  => AppDimensions.borderRadiusLg;
  BorderRadius get radiusXl  => AppDimensions.borderRadiusXl;
  BorderRadius get radiusXxl => AppDimensions.borderRadiusXxl;

  // Icon sizes
  double get iconSizeSm => AppDimensions.iconSm;
  double get iconSizeMd => AppDimensions.iconMd;
  double get iconSizeLg => AppDimensions.iconLg;
  double get iconSizeXl => AppDimensions.iconXl;

  // Button heights
  double get buttonHeightSm => AppDimensions.buttonHeightSm;
  double get buttonHeightMd => AppDimensions.buttonHeightMd;
  double get buttonHeightLg => AppDimensions.buttonHeightLg;

  // Gaps
  SizedBox get gapXs  => AppDimensions.gapXs;
  SizedBox get gapSm  => AppDimensions.gapSm;
  SizedBox get gapMd  => AppDimensions.gapMd;
  SizedBox get gapLg  => AppDimensions.gapLg;
  SizedBox get gapXl  => AppDimensions.gapXl;
  SizedBox get gapXxl => AppDimensions.gapXxl;

  // SnackBar helpers
  void showSnackBar(String message, {Duration duration = const Duration(seconds: 2), SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message, style: bodyMedium.copyWith(color: isDarkMode ? AppColors.textPrimary : Colors.white)),
      duration: duration,
      action: action,
      backgroundColor: isDarkMode ? AppColors.bgElevated : AppColors.textPrimaryLight,
      behavior: SnackBarBehavior.floating,
      margin: AppDimensions.paddingMd,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
    ));
  }

  void showErrorSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message, style: bodyMedium.copyWith(color: Colors.white)),
      duration: duration,
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: AppDimensions.paddingMd,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
    ));
  }

  void showSuccessSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message, style: bodyMedium.copyWith(color: Colors.white)),
      duration: duration,
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: AppDimensions.paddingMd,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
    ));
  }
}
