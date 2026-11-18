import 'package:desengastando/data/database/app_database.dart';
import 'package:flutter/foundation.dart';

/// Faixas de um orçamento. A ordem importa: serve para saber se um
/// lançamento "subiu" de faixa (e merece aviso).
enum BudgetStatus {
  /// Abaixo de [BudgetProgress.warningRatio] do limite.
  ok,

  /// Perto do limite (ou exatamente nele).
  warning,

  /// Passou do limite.
  over,
}

/// Quanto já foi gasto de um orçamento num mês.
@immutable
class BudgetProgress {
  const BudgetProgress({
    required this.category,
    required this.limitCents,
    required this.spentCents,
  });

  /// A partir de quanto do limite o orçamento entra em alerta.
  static const warningRatio = 0.8;

  final TransactionCategory category;
  final int limitCents;
  final int spentCents;

  double get ratio => spentCents / limitCents;

  /// Positivo: quanto ainda dá para gastar. Negativo: quanto passou.
  int get remainingCents => limitCents - spentCents;

  int get percent => (ratio * 100).round();

  BudgetStatus get status => spentCents > limitCents
      ? BudgetStatus.over
      : ratio >= warningRatio
      ? BudgetStatus.warning
      : BudgetStatus.ok;

  @override
  bool operator ==(Object other) =>
      other is BudgetProgress &&
      other.category == category &&
      other.limitCents == limitCents &&
      other.spentCents == spentCents;

  @override
  int get hashCode => Object.hash(category, limitCents, spentCents);
}

/// Soma de todos os orçamentos do mês.
@immutable
class BudgetTotals {
  const BudgetTotals({required this.limitCents, required this.spentCents});

  factory BudgetTotals.of(Iterable<BudgetProgress> items) => BudgetTotals(
    limitCents: items.fold(0, (sum, b) => sum + b.limitCents),
    spentCents: items.fold(0, (sum, b) => sum + b.spentCents),
  );

  final int limitCents;
  final int spentCents;

  int get remainingCents => limitCents - spentCents;
}

/// Mensagem a mostrar depois de um lançamento, se ele fez o orçamento
/// subir de faixa. `null` quando não há o que avisar.
String? budgetAlert({
  required BudgetProgress? before,
  required BudgetProgress? after,
}) {
  if (after == null) return null;
  final previous = before?.status ?? BudgetStatus.ok;
  if (after.status.index <= previous.index) return null;
  final name = after.category.name;
  return switch (after.status) {
    BudgetStatus.ok => null,
    BudgetStatus.warning =>
      'Atenção: você já usou ${after.percent}% do orçamento de $name',
    BudgetStatus.over => 'Orçamento de $name estourado neste mês',
  };
}
