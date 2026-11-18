import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:flutter/foundation.dart';

/// Lançamentos de um mesmo dia.
@immutable
class DayGroup {
  const DayGroup({required this.day, required this.items});

  final DateTime day;
  final List<TransactionWithCategory> items;

  /// Receitas menos despesas do dia, em centavos.
  int get balanceCents => items.fold(0, (sum, item) => sum + item.signedCents);
}

/// Agrupa por dia preservando a ordem recebida (espera-se mais recente
/// primeiro, como em `TransactionsDao.watchByMonth`).
List<DayGroup> groupByDay(List<TransactionWithCategory> items) {
  final groups = <DayGroup>[];
  for (final item in items) {
    final day = item.transaction.date.dateOnly;
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.items.add(item);
    } else {
      groups.add(DayGroup(day: day, items: [item]));
    }
  }
  return groups;
}
