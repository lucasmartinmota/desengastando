import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late int compras;

  setUp(() async {
    db = createTestDatabase();
    compras =
        (await db.categoriesDao
                .watchCategories(type: TransactionType.expense)
                .first)
            .firstWhere((c) => c.name == 'Compras')
            .id;
  });
  tearDown(() => db.close());

  Future<List<Transaction>> transactions() => (db.select(
    db.transactions,
  )..orderBy([(t) => OrderingTerm.asc(t.date)])).get();

  Future<int> fridge() => db.transactionsDao.addInstallments(
    TransactionsCompanion.insert(
      amountCents: 0,
      date: DateTime(2026, 11, 20),
      categoryId: compras,
      description: const Value('Geladeira'),
    ),
    count: 3,
    totalCents: 100000,
  );

  test('cria uma parcela por mês com os centavos certos', () async {
    await fridge();
    final list = await transactions();
    expect(list.map((t) => t.date), [
      DateTime(2026, 11, 20),
      DateTime(2026, 12, 20),
      DateTime(2027, 1, 20),
    ]);
    expect(list.map((t) => t.amountCents), [33334, 33333, 33333]);
    expect(list.map((t) => t.installmentNumber), [1, 2, 3]);
    expect(list.every((t) => t.description == 'Geladeira'), isTrue);
  });

  test('apagar desta parcela em diante', () async {
    final planId = await fridge();
    expect(await db.transactionsDao.deleteInstallmentsFrom(planId, 2), 2);
    expect((await transactions()).single.installmentNumber, 1);
    expect(await db.transactionsDao.getInstallmentPlan(planId), isNotNull);

    await db.transactionsDao.deleteInstallmentsFrom(planId, 1);
    expect(await transactions(), isEmpty);
    expect(await db.transactionsDao.getInstallmentPlan(planId), isNull);
  });
}
