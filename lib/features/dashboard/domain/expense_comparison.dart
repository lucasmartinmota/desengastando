import 'package:flutter/foundation.dart';

/// Variação percentual dos gastos em relação ao mês anterior.
@immutable
class ExpenseComparison {
  const ExpenseComparison._(this.percent);

  /// `null` quando não há base de comparação (mês anterior sem gastos).
  static ExpenseComparison? between({
    required int currentCents,
    required int previousCents,
  }) {
    if (previousCents <= 0) return null;
    final change = (currentCents - previousCents) * 100 / previousCents;
    return ExpenseComparison._(change.round());
  }

  /// Positivo = gastou mais; negativo = gastou menos.
  final int percent;

  @override
  bool operator ==(Object other) =>
      other is ExpenseComparison && other.percent == percent;

  @override
  int get hashCode => percent.hashCode;
}
