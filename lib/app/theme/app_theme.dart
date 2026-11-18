import 'package:desengastando/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const fontFamily = 'Manrope';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Estilo para valores monetários: números tabulares mantêm as colunas
  /// alinhadas em listas e evitam "pulos" quando o valor muda.
  static TextStyle money(TextStyle? base) => (base ?? const TextStyle())
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    var scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          surface: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
        );
    // No claro, mantemos a cor de marca exata como primária.
    if (!isDark) scheme = scheme.copyWith(primary: AppColors.primary);

    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: fontFamily,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [if (isDark) FinanceColors.dark else FinanceColors.light],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
