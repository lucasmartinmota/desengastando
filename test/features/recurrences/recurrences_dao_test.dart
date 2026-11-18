import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late int salario;
  late int moradia;
  final today = DateTime(2026, 11, 18);

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
    moradia = all.firstWhere((c) => c.name == 'Moradia').id;
  });
  tearDown(() => db.close());

  Future<List<Transaction>> transactions() => (db.select(
    db.transactions,
  )..orderBy([(t) => OrderingTerm.asc(t.date)])).get();

  Future<int> rent({
    int day = 10,
    bool includeCurrentMonth = true,
    DateTime? now,
  }) => db.recurrencesDao.createRecurrence(
    amountCents: 180000,
    categoryId: moradia,
    dayOfMonth: day,
    includeCurrentMonth: includeCurrentMonth,
    now: now ?? today,
  );

  test('addRepeating lança o primeiro e os 12 meses seguintes', () async {
    await db.recurrencesDao.addRepeating(
      TransactionsCompanion.insert(
        amountCents: 350000,
        date: DateTime(2026, 11, 5),
        categoryId: salario,
        description: const Value('Salário'),
        paymentMethod: const Value(PaymentMethod.bankTransfer),
      ),
      now: today,
    );

    final list = await transactions();
    expect(list, hasLength(13));
    expect(list.first.date, DateTime(2026, 11, 5));
    expect(list[2].date, DateTime(2027, 1, 5));
    expect(list.last.date, DateTime(2027, 11, 5));
    expect(list.every((t) => t.recurrenceId != null), isTrue);
    expect(list.last.paymentMethod, PaymentMethod.bankTransfer);
  });

  test('a janela anda com o tempo, sem duplicar', () async {
    await rent();
    expect(await transactions(), hasLength(13));
    expect(await db.recurrencesDao.generateDue(now: today), 0);

    expect(
      await db.recurrencesDao.generateDue(now: DateTime(2027, 1, 2)),
      2,
    );
    expect((await transactions()).last.date, DateTime(2028, 1, 10));
  });

  test('mês atual já vencido: entra só se pedir', () async {
    await rent(day: 5, includeCurrentMonth: false);
    expect((await transactions()).first.date, DateTime(2026, 12, 5));
  });

  test('mês atual ainda por vir entra sempre', () async {
    await rent(day: 25, includeCurrentMonth: false);
    expect((await transactions()).first.date, DateTime(2026, 11, 25));
  });

  test('lançamento apagado não volta', () async {
    await rent();
    final december = (await transactions())[1];
    await db.transactionsDao.deleteTransaction(december.id);
    await db.recurrencesDao.generateDue(now: DateTime(2026, 12, 20));
    expect(
      (await transactions()).where((t) => t.date == DateTime(2026, 12, 10)),
      isEmpty,
    );
  });

  test('editar refaz só os futuros', () async {
    final id = await rent();
    final recurrence = await (db.select(
      db.recurrences,
    )..where((r) => r.id.equals(id))).getSingle();
    await db.recurrencesDao.updateRecurrence(
      recurrence.copyWith(amountCents: 200000, dayOfMonth: 15),
      now: DateTime(2026, 12, 12),
    );

    final list = await transactions();
    // Em 12/12 a janela vai até dez./2027: nov./2026 + 13 meses.
    expect(list, hasLength(14));
    // Novembro e dezembro (já passaram) ficam como estavam.
    expect(list[0].amountCents, 180000);
    expect(list[1].date, DateTime(2026, 12, 10));
    expect(list[1].amountCents, 180000);
    expect(list[2].date, DateTime(2027, 1, 15));
    expect(list[2].amountCents, 200000);
  });

  test('pausar tira os futuros; reativar não lança para trás', () async {
    final id = await rent();
    await db.recurrencesDao.setActive(id, active: false, now: today);
    // O de 10/11 já passou e fica; os futuros saem.
    expect((await transactions()).single.date, DateTime(2026, 11, 10));

    await db.recurrencesDao.setActive(
      id,
      active: true,
      now: DateTime(2027, 2, 20),
    );
    final after = [
      for (final t in await transactions())
        if (t.date.isAfter(DateTime(2026, 11, 30))) t.date,
    ];
    // Dez. a fev. ficaram pausados; volta em março, até fev./2028.
    expect(after.first, DateTime(2027, 3, 10));
    expect(after, hasLength(12));
  });

  test('excluir mantém os que já passaram e apaga os futuros', () async {
    final id = await rent();
    await db.recurrencesDao.deleteRecurrence(id, now: DateTime(2026, 12, 15));

    final list = await transactions();
    expect(list.map((t) => t.date), [
      DateTime(2026, 11, 10),
      DateTime(2026, 12, 10),
    ]);
    expect(list.every((t) => t.recurrenceId == null), isTrue);
  });
}
