import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late int expenseId;
  late int incomeId;

  setUp(() async {
    db = createTestDatabase();
    expenseId =
        (await db.categoriesDao
                .watchCategories(type: TransactionType.expense)
                .first)
            .first
            .id;
    incomeId =
        (await db.categoriesDao
                .watchCategories(type: TransactionType.income)
                .first)
            .first
            .id;
  });
  tearDown(() => db.close());

  Future<void> add(int categoryId, int cents, DateTime date) =>
      db.transactionsDao.addTransaction(
        TransactionsCompanion.insert(
          amountCents: cents,
          date: date,
          categoryId: categoryId,
        ),
      );

  test('soma por mês, preenche zeros e ignora receitas', () async {
    await add(expenseId, 1000, DateTime(2026, 11, 3));
    await add(expenseId, 500, DateTime(2026, 11, 30, 23, 59));
    await add(expenseId, 2000, DateTime(2026, 9));
    await add(incomeId, 999999, DateTime(2026, 11, 5));
    // Fora da janela de 3 meses:
    await add(expenseId, 7777, DateTime(2026, 8, 31));
    await add(expenseId, 7777, DateTime(2026, 12));

    final totals = await db.transactionsDao
        .watchMonthlyExpenses(last: const YearMonth(2026, 11), months: 3)
        .first;

    expect(totals, const [
      MonthTotal(month: YearMonth(2026, 9), totalCents: 2000),
      MonthTotal(month: YearMonth(2026, 10), totalCents: 0),
      MonthTotal(month: YearMonth(2026, 11), totalCents: 1500),
    ]);
  });

  test('janela atravessa a virada do ano', () async {
    await add(expenseId, 300, DateTime(2025, 12, 15));
    await add(expenseId, 400, DateTime(2026, 1, 15));

    final totals = await db.transactionsDao
        .watchMonthlyExpenses(last: const YearMonth(2026, 1), months: 2)
        .first;

    expect(totals.map((t) => (t.month, t.totalCents)), [
      (const YearMonth(2025, 12), 300),
      (const YearMonth(2026, 1), 400),
    ]);
  });
}
