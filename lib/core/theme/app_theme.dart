import 'package:flutter/material.dart';

/// Premium water-wellness design system for Smart Water Reminder.
/// Dark theme: deep navy + aqua/teal + cyan highlights.
/// Light theme: soft white + mint/aqua + clean wellness colors.
class AppTheme {
  // ─── Light palette ───────────────────────────────────────────────
  static const Color primaryLight       = Color(0xFF0EA5E9); // sky-500
  static const Color primaryDarkLight   = Color(0xFF0284C7); // sky-600
  static const Color secondaryLight     = Color(0xFF14B8A6); // teal-500
  static const Color tertiaryLight      = Color(0xFF06B6D4); // cyan-500
  static const Color errorLight         = Color(0xFFEF4444);
  static const Color backgroundLight    = Color(0xFFF0F9FF); // sky-50
  static const Color surfaceLight       = Color(0xFFFFFFFF);
  static const Color surfaceVarLight    = Color(0xFFE0F2FE); // sky-100
  static const Color onPrimaryLight     = Colors.white;
  static const Color onSurfaceLight     = Color(0xFF0C1A2B);
  static const Color onSurfaceVarLight  = Color(0xFF546E85);
  static const Color outlineLight       = Color(0xFFBAD4E8);

  // ─── Dark palette ────────────────────────────────────────────────
  static const Color primaryDark        = Color(0xFF38BDF8); // sky-400
  static const Color secondaryDark      = Color(0xFF2DD4BF); // teal-400
  static const Color tertiaryDark       = Color(0xFF22D3EE); // cyan-400
  static const Color errorDark          = Color(0xFFF87171);
  static const Color backgroundDark     = Color(0xFF04101C); // deep navy
  static const Color surfaceDark        = Color(0xFF0B1929); // navy-800
  static const Color surfaceVarDark     = Color(0xFF102033); // navy-700
  static const Color surface2Dark       = Color(0xFF162840); // navy-600
  static const Color onPrimaryDark      = Color(0xFF001E30);
  static const Color onSurfaceDark      = Color(0xFFE2F4FF);
  static const Color onSurfaceVarDark   = Color(0xFF7CB4CC);
  static const Color outlineDark        = Color(0xFF1E3A52);

  // ─── Shared semantic colors ──────────────────────────────────────
  static const Color success            = Color(0xFF10B981);
  static const Color warning            = Color(0xFFF59E0B);

  // ─── Water-themed gradient stops ─────────────────────────────────
  static const List<Color> waterGradientLight = [
    Color(0xFF0EA5E9),
    Color(0xFF06B6D4),
    Color(0xFF14B8A6),
  ];
  static const List<Color> waterGradientDark = [
    Color(0xFF0284C7),
    Color(0xFF0E7490),
    Color(0xFF0F766E),
  ];

  // ════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ════════════════════════════════════════════════════════════════
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary:                primaryLight,
      onPrimary:              onPrimaryLight,
      primaryContainer:       Color(0xFFBAE6FD), // sky-200
      onPrimaryContainer:     Color(0xFF003350),
      secondary:              secondaryLight,
      onSecondary:            Colors.white,
      secondaryContainer:     Color(0xFF99F6E4), // teal-200
      onSecondaryContainer:   Color(0xFF003D35),
      tertiary:               tertiaryLight,
      onTertiary:             Colors.white,
      tertiaryContainer:      Color(0xFFA5F3FC), // cyan-200
      onTertiaryContainer:    Color(0xFF003842),
      error:                  errorLight,
      onError:                Colors.white,
      surface:                surfaceLight,
      onSurface:              onSurfaceLight,
      onSurfaceVariant:       onSurfaceVarLight,
      surfaceContainerHighest: surfaceVarLight,
      surfaceContainerHigh:   Color(0xFFE8F4FD),
      surfaceContainer:       Color(0xFFF0F9FF),
      outline:                outlineLight,
      outlineVariant:         Color(0xFFD4ECF9),
      shadow:                 Color(0xFF0C1A2B),
      scrim:                  Color(0xFF0C1A2B),
    ),
    scaffoldBackgroundColor: backgroundLight,

    // Typography
    textTheme: _buildTextTheme(onSurfaceLight, onSurfaceVarLight),

    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      backgroundColor: surfaceLight,
      surfaceTintColor: primaryLight,
      foregroundColor: onSurfaceLight,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurfaceLight,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: onSurfaceLight, size: 24),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: surfaceLight,
      shadowColor: Color(0xFF0C1A2B),
    ),

    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        side: const BorderSide(color: primaryLight, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVarLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: outlineLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorLight, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: onSurfaceVarLight),
      hintStyle: const TextStyle(color: onSurfaceVarLight),
    ),

    // Navigation bar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceLight,
      indicatorColor: primaryLight.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryLight, size: 22);
        }
        return const IconThemeData(color: onSurfaceVarLight, size: 22);
      }),
      height: 68,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVarLight,
      selectedColor: primaryLight.withValues(alpha: 0.15),
      checkmarkColor: primaryLight,
      labelStyle: const TextStyle(color: onSurfaceLight, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: outlineLight,
      thickness: 1,
      space: 1,
    ),

    // Progress
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryLight,
      circularTrackColor: surfaceVarLight,
      linearTrackColor: surfaceVarLight,
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryLight,
      inactiveTrackColor: surfaceVarLight,
      thumbColor: primaryLight,
      overlayColor: primaryLight.withValues(alpha: 0.15),
      trackHeight: 5,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? primaryLight : const Color(0xFFB0CBD8)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? primaryLight.withValues(alpha: 0.45)
              : const Color(0xFFD4ECF9)),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      shadowColor: const Color(0x220C1A2B),
      titleTextStyle: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: onSurfaceLight, letterSpacing: -0.2,
      ),
      contentTextStyle: TextStyle(fontSize: 14, color: onSurfaceVarLight, height: 1.5),
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceLight,
      modalBackgroundColor: surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 0,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: onSurfaceLight,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
      actionTextColor: tertiaryLight,
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: Colors.white,
      elevation: 4,
      highlightElevation: 8,
      shape: CircleBorder(),
    ),

    // Icon
    iconTheme: const IconThemeData(color: onSurfaceLight, size: 22),
  );

  // ════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ════════════════════════════════════════════════════════════════
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:                primaryDark,
      onPrimary:              onPrimaryDark,
      primaryContainer:       Color(0xFF003D60),
      onPrimaryContainer:     Color(0xFFBAE6FD),
      secondary:              secondaryDark,
      onSecondary:            Color(0xFF00302A),
      secondaryContainer:     Color(0xFF004D42),
      onSecondaryContainer:   Color(0xFF99F6E4),
      tertiary:               tertiaryDark,
      onTertiary:             Color(0xFF003840),
      tertiaryContainer:      Color(0xFF004E5A),
      onTertiaryContainer:    Color(0xFFA5F3FC),
      error:                  errorDark,
      onError:                Color(0xFF690005),
      surface:                surfaceDark,
      onSurface:              onSurfaceDark,
      onSurfaceVariant:       onSurfaceVarDark,
      surfaceContainerHighest: surfaceVarDark,
      surfaceContainerHigh:   surface2Dark,
      surfaceContainer:       Color(0xFF091525),
      outline:                outlineDark,
      outlineVariant:         Color(0xFF142638),
      shadow:                 Color(0xFF000000),
      scrim:                  Color(0xFF000000),
    ),
    scaffoldBackgroundColor: backgroundDark,

    // Typography
    textTheme: _buildTextTheme(onSurfaceDark, onSurfaceVarDark),

    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      backgroundColor: surfaceDark,
      surfaceTintColor: primaryDark,
      foregroundColor: onSurfaceDark,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurfaceDark,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: onSurfaceDark, size: 24),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: surfaceDark,
      shadowColor: Colors.black,
    ),

    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: onPrimaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        side: const BorderSide(color: primaryDark, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVarDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: outlineDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorDark, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: onSurfaceVarDark),
      hintStyle: const TextStyle(color: onSurfaceVarDark),
    ),

    // Navigation bar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceDark,
      indicatorColor: primaryDark.withValues(alpha: 0.18),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryDark, size: 22);
        }
        return const IconThemeData(color: onSurfaceVarDark, size: 22);
      }),
      height: 68,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVarDark,
      selectedColor: primaryDark.withValues(alpha: 0.2),
      checkmarkColor: primaryDark,
      labelStyle: const TextStyle(color: onSurfaceDark, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: outlineDark,
      thickness: 1,
      space: 1,
    ),

    // Progress
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryDark,
      circularTrackColor: surfaceVarDark,
      linearTrackColor: surfaceVarDark,
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryDark,
      inactiveTrackColor: surfaceVarDark,
      thumbColor: primaryDark,
      overlayColor: primaryDark.withValues(alpha: 0.2),
      trackHeight: 5,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? primaryDark : const Color(0xFF3A5A6E)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? primaryDark.withValues(alpha: 0.4)
              : const Color(0xFF1E3A52)),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      shadowColor: Colors.black54,
      titleTextStyle: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: onSurfaceDark, letterSpacing: -0.2,
      ),
      contentTextStyle: TextStyle(fontSize: 14, color: onSurfaceVarDark, height: 1.5),
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceDark,
      modalBackgroundColor: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 0,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface2Dark,
      contentTextStyle: const TextStyle(color: onSurfaceDark, fontSize: 14, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
      actionTextColor: tertiaryDark,
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryDark,
      foregroundColor: onPrimaryDark,
      elevation: 4,
      highlightElevation: 8,
      shape: CircleBorder(),
    ),

    // Icon
    iconTheme: const IconThemeData(color: onSurfaceDark, size: 22),
  );

  // ─── Shared text theme ───────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w300, color: primary, letterSpacing: -0.25),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w300, color: primary, letterSpacing: -0.15),
      displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: primary),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
      headlineMedium:TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.2),
      titleLarge:    TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.2),
      titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.1),
      titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: primary, height: 1.5),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: secondary, height: 1.5),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondary, height: 1.4),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.1),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.1),
      labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.2),
    );
  }
}