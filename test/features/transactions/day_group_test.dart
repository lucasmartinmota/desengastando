import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/domain/day_group.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionCategory _category(TransactionType type) => TransactionCategory(
  id: type.index + 1,
  name: type.label,
  iconKey: 'more_horiz',
  color: 0xFF000000,
  type: type,
  archived: false,
  sortOrder: 0,
);

TransactionWithCategory _item(
  int id,
  DateTime date,
  int cents,
  TransactionType type,
) => TransactionWithCategory(
  transaction: Transaction(
    id: id,
    amountCents: cents,
    date: date,
    categoryId: type.index + 1,
    createdAt: date,
  ),
  category: _category(type),
);

void main() {
  test('agrupa por dia mantendo a ordem e soma o saldo do dia', () {
    final groups = groupByDay([
      _item(4, DateTime(2026, 11, 18, 20), 3000, TransactionType.expense),
      _item(3, DateTime(2026, 11, 18, 9), 10000, TransactionType.income),
      _item(2, DateTime(2026, 11, 16), 1500, TransactionType.expense),
      _item(1, DateTime(2026, 11, 16), 500, TransactionType.expense),
    ]);

    expect(groups.map((g) => g.day), [
      DateTime(2026, 11, 18),
      DateTime(2026, 11, 16),
    ]);
    expect(groups.first.items.map((i) => i.transaction.id), [4, 3]);
    expect(groups.first.balanceCents, 7000);
    expect(groups.last.balanceCents, -2000);
  });

  test('lista vazia gera nenhum grupo', () {
    expect(groupByDay(const []), isEmpty);
  });
}
