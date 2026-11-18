import 'package:flutter/material.dart';

/// Paleta base do Desengastando.
abstract final class AppColors {
  static const primary = Color(0xFF0F766E); // verde-petróleo
  static const expense = Color(0xFFF25F5C); // coral
  static const income = Color(0xFF2EC4B6); // menta
  static const warning = Color(0xFFF4A261); // âmbar
  static const backgroundLight = Color(0xFFF7F9F8);
  static const backgroundDark = Color(0xFF0E1513);
}

/// Cores semânticas de finanças, acessíveis via `context.finance`.
///
/// No tema claro usamos variações mais escuras para manter contraste
/// legível em texto (menta e coral puros ficam fracos sobre fundo claro).
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.expense,
    required this.income,
    required this.warning,
  });

  final Color expense;
  final Color income;
  final Color warning;

  static const light = FinanceColors(
    expense: Color(0xFFD64541),
    income: Color(0xFF0E8A7E),
    warning: Color(0xFFB8641F),
  );

  static const dark = FinanceColors(
    expense: AppColors.expense,
    income: AppColors.income,
    warning: AppColors.warning,
  );

  @override
  FinanceColors copyWith({Color? expense, Color? income, Color? warning}) {
    return FinanceColors(
      expense: expense ?? this.expense,
      income: income ?? this.income,
      warning: warning ?? this.warning,
    );
  }

  @override
  FinanceColors lerp(FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      expense: Color.lerp(expense, other.expense, t)!,
      income: Color.lerp(income, other.income, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension FinanceColorsX on BuildContext {
  FinanceColors get finance => Theme.of(this).extension<FinanceColors>()!;
}
