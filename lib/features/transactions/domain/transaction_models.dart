import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter/foundation.dart';

/// Transação com sua categoria, pronta para a listagem.
@immutable
class TransactionWithCategory {
  const TransactionWithCategory({
    required this.transaction,
    required this.category,
  });

  final Transaction transaction;
  final TransactionCategory category;

  /// Valor com sinal: negativo para despesa, positivo para receita.
  int get signedCents => category.type == TransactionType.expense
      ? -transaction.amountCents
      : transaction.amountCents;
}

/// Totais de um mês, em centavos.
@immutable
class MonthSummary {
  const MonthSummary({required this.incomeCents, required this.expenseCents});

  static const empty = MonthSummary(incomeCents: 0, expenseCents: 0);

  final int incomeCents;
  final int expenseCents;

  int get balanceCents => incomeCents - expenseCents;

  @override
  bool operator ==(Object other) =>
      other is MonthSummary &&
      other.incomeCents == incomeCents &&
      other.expenseCents == expenseCents;

  @override
  int get hashCode => Object.hash(incomeCents, expenseCents);

  @override
  String toString() =>
      'MonthSummary(income: $incomeCents, expense: $expenseCents)';
}

/// Total gasto em uma categoria num período.
@immutable
class CategoryTotal {
  const CategoryTotal({required this.category, required this.totalCents});

  final TransactionCategory category;
  final int totalCents;
}

/// Total de despesas de um mês, em centavos.
@immutable
class MonthTotal {
  const MonthTotal({required this.month, required this.totalCents});

  final YearMonth month;
  final int totalCents;

  @override
  bool operator ==(Object other) =>
      other is MonthTotal &&
      other.month == month &&
      other.totalCents == totalCents;

  @override
  int get hashCode => Object.hash(month, totalCents);

  @override
  String toString() => 'MonthTotal($month, $totalCents)';
}
