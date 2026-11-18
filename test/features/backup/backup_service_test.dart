import 'dart:convert';

import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/backup/data/backup_service.dart';
import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late BackupService service;
  late Map<String, TransactionCategory> expense;

  setUp(() async {
    db = createTestDatabase();
    service = BackupService(db);
    expense = {
      for (final c
          in await db.categoriesDao
              .watchCategories(type: TransactionType.expense)
              .first)
        c.name: c,
    };
  });
  tearDown(() => db.close());

  Future<void> seed() async {
    await db.transactionsDao.addTransaction(
      TransactionsCompanion.insert(
        amountCents: 123456,
        date: DateTime(2026, 11, 3),
        categoryId: expense['Mercado']!.id,
        description: const Value('Feira; "grande"'),
        paymentMethod: const Value(PaymentMethod.pix),
      ),
    );
    await db.budgetsDao.setBudget(
      categoryId: expense['Mercado']!.id,
      limitCents: 80000,
    );
    await db.categoriesDao.setArchived(expense['Lazer']!.id, archived: true);
  }

  test('exporta e restaura tudo, inclusive ids e arquivadas', () async {
    await seed();
    final json = await service.exportJson();

    // Banco novo, já com as categorias padrão: a restauração substitui.
    final other = createTestDatabase();
    addTearDown(other.close);
    final restoreService = BackupService(other);
    await restoreService.restore(restoreService.parse(json));

    expect(
      await BackupService(other).exportJson(now: DateTime(2000)),
      await service.exportJson(now: DateTime(2000)),
    );
    final transactions = await other.select(other.transactions).get();
    expect(transactions.single.date, DateTime(2026, 11, 3));
    expect(transactions.single.paymentMethod, PaymentMethod.pix);
  });

  test('recusa arquivos que não são backup', () {
    expect(
      () => service.parse('não é json'),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => service.parse(jsonEncode({'app': 'outro'})),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => service.parse(jsonEncode({'app': 'desengastando', 'format': 99})),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => service.parse(jsonEncode({'app': 'desengastando', 'format': 1})),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('restauração com referência quebrada não altera nada', () async {
    await seed();
    final data = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
    (data['transactions'] as List).add({
      ...(data['transactions'] as List).first as Map<String, dynamic>,
      'id': 999,
      'categoryId': 12345,
    });
    final contents = service.parse(jsonEncode(data));

    final before = await service.exportJson(now: DateTime(2000));
    await expectLater(service.restore(contents), throwsA(anything));
    expect(await service.exportJson(now: DateTime(2000)), before);
  });

  test('CSV no padrão brasileiro, com aspas quando precisa', () async {
    await seed();
    final csv = await service.exportCsv();
    // `trim` removeria o BOM (para o Dart ele é espaço em branco).
    final lines = csv.substring(1).trimRight().split('\n');

    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(
      lines.first,
      'Data;Tipo;Categoria;Descrição;Forma de pagamento;Valor',
    );
    expect(
      lines[1],
      '03/11/2026;Despesa;Mercado;"Feira; ""grande""";Pix;-1234,56',
    );
  });
}
