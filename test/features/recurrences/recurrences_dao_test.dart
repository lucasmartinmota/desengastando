import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late int salario;
  late int aluguel;

  setUp(() async {
    db = createTestDatabase();
    final all = await db.categoriesDao
        .watchCategories(includeArchived: true)
        .first;
    salario = all
        .firstWhere(
          (c) => c.name == 'Salário' && c.type == TransactionType.income,
        )
        .id;
    aluguel = all.firstWhere((c) => c.name == 'Moradia').id;
  });
  tearDown(() => db.close());

  Future<List<Transaction>> transactions() => (db.select(
    db.transactions,
  )..orderBy([(t) => OrderingTerm.asc(t.date)])).get();

  test('addRepeating grava o primeiro e preenche até hoje', () async {
    await db.recurrencesDao.addRepeating(
      TransactionsCompanion.insert(
        amountCents: 350000,
        date: DateTime(2026, 9, 5),
        categoryId: salario,
        description: const Value('Salário'),
        paymentMethod: const Value(PaymentMethod.bankTransfer),
      ),
      now: DateTime(2026, 11, 18),
    );

    final list = await transactions();
    expect(list.map((t) => t.date), [
      DateTime(2026, 9, 5),
      DateTime(2026, 10, 5),
      DateTime(2026, 11, 5),
    ]);
    expect(list.every((t) => t.recurrenceId != null), isTrue);
    expect(list.last.paymentMethod, PaymentMethod.bankTransfer);
  });

  test('generateDue não duplica e respeita o dia', () async {
    await db.recurrencesDao.createRecurrence(
      amountCents: 180000,
      categoryId: aluguel,
      dayOfMonth: 20,
      includeCurrentMonth: true,
      now: DateTime(2026, 11, 18),
    );
    // Dia 20 ainda não chegou.
    expect(await transactions(), isEmpty);

    expect(await db.recurrencesDao.generateDue(now: DateTime(2026, 11, 20)), 1);
    expect(await db.recurrencesDao.generateDue(now: DateTime(2026, 11, 25)), 0);
    expect(await transactions(), hasLength(1));
  });

  test('mês atual já vencido: lança agora só se pedir', () async {
    await db.recurrencesDao.createRecurrence(
      amountCents: 100,
      categoryId: aluguel,
      dayOfMonth: 5,
      includeCurrentMonth: false,
      now: DateTime(2026, 11, 18),
    );
    expect(await transactions(), isEmpty);

    await db.recurrencesDao.createRecurrence(
      amountCents: 200,
      categoryId: aluguel,
      dayOfMonth: 5,
      includeCurrentMonth: true,
      now: DateTime(2026, 11, 18),
    );
    expect((await transactions()).single.amountCents, 200);
  });

  test('lançamento apagado não volta', () async {
    await db.recurrencesDao.createRecurrence(
      amountCents: 100,
      categoryId: aluguel,
      dayOfMonth: 1,
      includeCurrentMonth: true,
      now: DateTime(2026, 11, 18),
    );
    final generated = (await transactions()).single;
    await db.transactionsDao.deleteTransaction(generated.id);

    await db.recurrencesDao.generateDue(now: DateTime(2026, 11, 30));
    expect(await transactions(), isEmpty);
  });

  test('pausada não gera; ao reativar não lança para trás', () async {
    final id = await db.recurrencesDao.createRecurrence(
      amountCents: 100,
      categoryId: aluguel,
      dayOfMonth: 10,
      includeCurrentMonth: false,
      now: DateTime(2026, 9),
    );
    await db.recurrencesDao.setActive(id, active: false);
    await db.recurrencesDao.generateDue(now: DateTime(2026, 11, 18));
    expect(await transactions(), isEmpty);

    await db.recurrencesDao.setActive(
      id,
      active: true,
      now: DateTime(2026, 11, 18),
    );
    await db.recurrencesDao.generateDue(now: DateTime(2026, 11, 18));
    expect(await transactions(), isEmpty);
    await db.recurrencesDao.generateDue(now: DateTime(2026, 12, 10));
    expect((await transactions()).single.date, DateTime(2026, 12, 10));
  });

  test('apagar a recorrência mantém os lançamentos feitos', () async {
    final id = await db.recurrencesDao.createRecurrence(
      amountCents: 100,
      categoryId: aluguel,
      dayOfMonth: 1,
      includeCurrentMonth: true,
      now: DateTime(2026, 11, 18),
    );
    await db.recurrencesDao.deleteRecurrence(id);

    final list = await transactions();
    expect(list, hasLength(1));
    expect(list.single.recurrenceId, isNull);
  });
}
