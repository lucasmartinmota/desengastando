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

    Future<List<String>> expenseNames() async => [
      for (final c
          in await db.categoriesDao
              .watchCategories(type: TransactionType.expense)
              .first)
        c.name,
    ];

    test('createCategory coloca a nova no fim do seu tipo', () async {
      await db.categoriesDao.createCategory(
        name: 'Pets',
        iconKey: 'pets',
        color: 0xFF43AA8B,
        type: TransactionType.expense,
      );

      expect((await expenseNames()).last, 'Pets');
    });

    test('reorder grava a ordem nova', () async {
      final ids = [
        for (final c
            in await db.categoriesDao
                .watchCategories(type: TransactionType.expense)
                .first)
          c.id,
      ];
      await db.categoriesDao.reorder(ids.reversed.toList());

      final names = await expenseNames();
      expect(names.first, 'Outros');
      expect(names.last, 'Alimentação');
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

    test('watchProgress soma só o mês e mantém orçamento sem gasto', () async {
      final mercado = expense['Mercado']!;
      final lazer = expense['Lazer']!;
      await db.budgetsDao.setBudget(categoryId: mercado.id, limitCents: 50000);
      await db.budgetsDao.setBudget(categoryId: lazer.id, limitCents: 20000);
      await add(mercado, 30000, DateTime(2026, 11, 2));
      await add(mercado, 15000, DateTime(2026, 11, 30, 23, 59));
      await add(mercado, 99900, DateTime(2026, 10, 31));
      await add(mercado, 99900, DateTime(2026, 12));

      final progress = await db.budgetsDao.watchProgress(november).first;

      expect(progress.map((p) => p.category.name), ['Mercado', 'Lazer']);
      expect(progress.first.spentCents, 45000);
      expect(progress.first.percent, 90);
      expect(progress.last.spentCents, 0);
    });

    test('getProgress traz uma categoria ou null', () async {
      final mercado = expense['Mercado']!;
      await db.budgetsDao.setBudget(categoryId: mercado.id, limitCents: 10000);
      await add(mercado, 12000, DateTime(2026, 11, 5));

      final progress = await db.budgetsDao.getProgress(mercado.id, november);
      expect(progress?.spentCents, 12000);
      expect(
        await db.budgetsDao.getProgress(expense['Lazer']!.id, november),
        isNull,
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
