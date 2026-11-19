import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/reports/domain/report_period.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter/foundation.dart';

/// Total de uma categoria no relatório.
@immutable
class CategoryShare {
  const CategoryShare({
    required this.category,
    required this.totalCents,
    required this.count,
    required this.ratio,
  });

  final TransactionCategory category;
  final int totalCents;

  /// Quantidade de lançamentos.
  final int count;

  /// Fatia do total do mesmo tipo (0 a 1).
  final double ratio;
}

/// Tudo o que vai no relatório de um período, já calculado.
class ReportData {
  ReportData({
    required this.period,
    required this.transactions,
    required this.generatedAt,
  });

  final ReportPeriod period;

  /// Lançamentos do período, do mais antigo para o mais recente.
  final List<TransactionWithCategory> transactions;

  final DateTime generatedAt;

  bool get isEmpty => transactions.isEmpty;

  late final int incomeCents = _total(TransactionType.income);
  late final int expenseCents = _total(TransactionType.expense);
  int get balanceCents => incomeCents - expenseCents;

  /// Lançamentos com data depois da geração (fixos e parcelas previstos).
  late final int scheduledCount = transactions
      .where((t) => t.isScheduled(today: generatedAt))
      .length;

  late final List<CategoryShare> expensesByCategory = _byCategory(
    TransactionType.expense,
  );
  late final List<CategoryShare> incomeByCategory = _byCategory(
    TransactionType.income,
  );

  int _total(TransactionType type) => transactions
      .where((t) => t.category.type == type)
      .fold(0, (sum, t) => sum + t.transaction.amountCents);

  /// Do maior para o menor total; empate desempata pelo nome.
  List<CategoryShare> _byCategory(TransactionType type) {
    final totals = <int, (TransactionCategory, int, int)>{};
    for (final t in transactions) {
      if (t.category.type != type) continue;
      final (category, cents, count) =
          totals[t.category.id] ?? (t.category, 0, 0);
      totals[t.category.id] = (
        category,
        cents + t.transaction.amountCents,
        count + 1,
      );
    }
    final total = _total(type);
    return [
      for (final (category, cents, count) in totals.values)
        CategoryShare(
          category: category,
          totalCents: cents,
          count: count,
          ratio: total == 0 ? 0 : cents / total,
        ),
    ]..sort(
      (a, b) => b.totalCents != a.totalCents
          ? b.totalCents.compareTo(a.totalCents)
          : a.category.name.compareTo(b.category.name),
    );
  }
}
