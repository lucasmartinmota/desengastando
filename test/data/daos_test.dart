import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Map<String, TransactionCategory> expense;
  late Map<String, TransactionCategory> income;

  const november = YearMonth(2026, 11);

  setUp(() async {
    db = createTestDatabase();
    final cats = await db.categoriesDao
        .watchCategories(includeArchived: true)
        .first;
    expense = {
      for (final c in cats.where((c) => c.type == TransactionType.expense))
        c.name: c,
    };
    income = {
      for (final c in cats.where((c) => c.type == TransactionType.income))
        c.name: c,
    };
  });
  tearDown(() => db.close());

  Future<int> add(
    TransactionCategory category,
    int cents,
    DateTime date, {
    String? description,
  }) => db.transactionsDao.addTransaction(
    TransactionsCompanion.insert(
      amountCents: cents,
      date: date,
      categoryId: category.id,
      description: Value(description),
      paymentMethod: const Value(PaymentMethod.pix),
    ),
  );

  group('TransactionsDao', () {
    test('watchByMonth traz só o mês, mais recentes primeiro', () async {
      await add(expense['Mercado']!, 5000, DateTime(2026, 11, 3));
      await add(expense['Lazer']!, 2000, DateTime(2026, 11, 20));
      await add(expense['Lazer']!, 9900, DateTime(2026, 10, 31, 23, 59));
      await add(expense['Lazer']!, 9900, DateTime(2026, 12));

      final list = await db.transactionsDao.watchByMonth(november).first;

      expect(list.map((t) => t.transaction.amountCents), [2000, 5000]);
      expect(list.first.category.name, 'Lazer');
      expect(list.first.transaction.paymentMethod, PaymentMethod.pix);
    });

    test('no mesmo dia, o lançado por último vem primeiro', () async {
      final day = DateTime(2026, 11, 5);
      await add(expense['Mercado']!, 100, day, description: 'primeiro');
      await add(expense['Mercado']!, 200, day, description: 'segundo');

      final list = await db.transactionsDao.watchByMonth(november).first;
      expect(list.map((t) => t.transaction.description), [
        'segundo',
        'primeiro',
      ]);
    });

    test('watchMonthSummary soma receitas e despesas', () async {
      await add(income['Salário']!, 500000, DateTime(2026, 11, 5));
      await add(expense['Moradia']!, 150000, DateTime(2026, 11, 10));
      await add(expense['Mercado']!, 45050, DateTime(2026, 11, 12));
      await add(expense['Mercado']!, 99999, DateTime(2026, 10, 12));

      final summary = await db.transactionsDao
          .watchMonthSummary(november)
          .first;

      expect(
        summary,
        const MonthSummary(incomeCents: 500000, expenseCents: 195050),
      );
      expect(summary.balanceCents, 304950);
    });

    test('watchMonthSummary de mês vazio é zero', () async {
      final summary = await db.transactionsDao
          .watchMonthSummary(november)
          .first;
      expect(summary, MonthSummary.empty);
    });

    test(
      'watchExpensesByCategory agrupa, ordena e ignora receitas',
      () async {
        await add(expense['Mercado']!, 3000, DateTime(2026, 11));
        await add(expense['Mercado']!, 4000, DateTime(2026, 11, 2));
        await add(expense['Moradia']!, 10000, DateTime(2026, 11, 3));
        await add(income['Salário']!, 500000, DateTime(2026, 11, 5));

        final totals = await db.transactionsDao
            .watchExpensesByCategory(november)
            .first;

        expect(
          totals.map((t) => (t.category.name, t.totalCents)),
          [('Moradia', 10000), ('Mercado', 7000)],
        );
      },
    );

    test('stream emite de novo quando um lançamento é removido', () async {
      final id = await add(expense['Mercado']!, 3000, DateTime(2026, 11));

      final emissions = db.transactionsDao
          .watchMonthSummary(november)
          .map((s) => s.expenseCents);
      final expectation = expectLater(emissions, emitsInOrder([3000, 0]));

      await pumpEventQueue();
      await db.transactionsDao.deleteTransaction(id);
      await expectation;
    });
  });

  group('CategoriesDao', () {
    test('arquivadas somem da listagem padrão', () async {
      await db.categoriesDao.setArchived(expense['Lazer']!.id, archived: true);

      final active = await db.categoriesDao
          .watchCategories(type: TransactionType.expense)
          .first;
      final all = await db.categoriesDao
          .watchCategories(type: TransactionType.expense, includeArchived: true)
          .first;

      expect(active.map((c) => c.name), isNot(contains('Lazer')));
      expect(all.map((c) => c.name), contains('Lazer'));
    });
  });

  group('BudgetsDao', () {
    test('setBudget cria e depois substitui o limite', () async {
      final mercado = expense['Mercado']!;
      await db.budgetsDao.setBudget(categoryId: mercado.id, limitCents: 80000);
      await db.budgetsDao.setBudget(categoryId: mercado.id, limitCents: 60000);

      final budgets = await db.budgetsDao.watchBudgets().first;
      expect(budgets, hasLength(1));
      expect(budgets.single.category.name, 'Mercado');
      expect(budgets.single.budget.limitCents, 60000);
    });

    test('rejeita orçamento em categoria de receita', () async {
      await expectLater(
        db.budgetsDao.setBudget(
          categoryId: income['Salário']!.id,
          limitCents: 1000,
        ),
        throwsArgumentError,
      );
    });

    test('orçamento de categoria arquivada não aparece', () async {
      final lazer = expense['Lazer']!;
      await db.budgetsDao.setBudget(categoryId: lazer.id, limitCents: 20000);
      await db.categoriesDao.setArchived(lazer.id, archived: true);

      expect(await db.budgetsDao.watchBudgets().first, isEmpty);
    });

    test('removeBudget apaga o limite', () async {
      final mercado = expense['Mercado']!;
      await db.budgetsDao.setBudget(categoryId: mercado.id, limitCents: 80000);
      await db.budgetsDao.removeBudget(mercado.id);

      expect(await db.budgetsDao.watchBudgets().first, isEmpty);
    });
  });
}
