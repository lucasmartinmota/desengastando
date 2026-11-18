import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/data/database/default_categories.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  Future<int> anyCategoryId(TransactionType type) async =>
      (await db.categoriesDao.watchCategories(type: type).first).first.id;

  group('criação do banco', () {
    test('insere as categorias padrão', () async {
      final all = await db.categoriesDao
          .watchCategories(includeArchived: true)
          .first;
      expect(all, hasLength(defaultCategories.length));

      final expenses = await db.categoriesDao
          .watchCategories(type: TransactionType.expense)
          .first;
      final incomes = await db.categoriesDao
          .watchCategories(type: TransactionType.income)
          .first;
      expect(expenses.map((c) => c.name), contains('Alimentação'));
      expect(incomes.map((c) => c.name), contains('Salário'));
      expect(expenses.length + incomes.length, all.length);
    });

    test('chaves estrangeiras estão ativas', () async {
      final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.read<int>('foreign_keys'), 1);
    });
  });

  group('restrições', () {
    test('rejeita transação com categoria inexistente', () async {
      await expectLater(
        db.transactionsDao.addTransaction(
          TransactionsCompanion.insert(
            amountCents: 100,
            date: DateTime(2026, 11),
            categoryId: 9999,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejeita valor zero ou negativo', () async {
      final categoryId = await anyCategoryId(TransactionType.expense);
      for (final amount in [0, -500]) {
        await expectLater(
          db.transactionsDao.addTransaction(
            TransactionsCompanion.insert(
              amountCents: amount,
              date: DateTime(2026, 11),
              categoryId: categoryId,
            ),
          ),
          throwsA(isA<Exception>()),
          reason: 'amountCents = $amount',
        );
      }
    });

    test('não apaga categoria que tem lançamentos', () async {
      final categoryId = await anyCategoryId(TransactionType.expense);
      await db.transactionsDao.addTransaction(
        TransactionsCompanion.insert(
          amountCents: 100,
          date: DateTime(2026, 11),
          categoryId: categoryId,
        ),
      );
      await expectLater(
        (db.delete(
          db.categories,
        )..where((c) => c.id.equals(categoryId))).go(),
        throwsA(isA<Exception>()),
      );
    });

    test('rejeita categoria duplicada com o mesmo tipo', () async {
      await expectLater(
        db.categoriesDao.addCategory(
          CategoriesCompanion.insert(
            name: 'Alimentação',
            iconKey: 'restaurant',
            color: 0xFF000000,
            type: TransactionType.expense,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
