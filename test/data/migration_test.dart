import 'package:desengastando/data/database/app_database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated_migrations/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  // O app sempre migra até a versão atual; versões antigas são o ponto de
  // partida (o celular pode estar em qualquer uma delas).
  group('schema após migrar bate com o esperado', () {
    for (final (from, to) in [(1, 3), (2, 3)]) {
      test('v$from → v$to', () async {
        final connection = await verifier.startAt(from);
        final db = AppDatabase(connection);
        addTearDown(db.close);
        await verifier.migrateAndValidate(db, to);
      });
    }
  });

  test('v1 → v3 preserva os lançamentos', () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase
      ..execute(
        'INSERT INTO categories (id, name, icon_key, color, type, archived, '
        "sort_order) VALUES (1, 'Salário', 'payments', 0, 'income', 0, 0)",
      )
      ..execute(
        'INSERT INTO transactions (id, amount_cents, date, category_id, '
        'created_at) VALUES (7, 350000, 1793588400, 1, 1793588400)',
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);

    final transaction = (await db.select(db.transactions).get()).single;
    expect(transaction.id, 7);
    expect(transaction.amountCents, 350000);
    expect(transaction.recurrenceId, isNull);
    expect(transaction.installmentPlanId, isNull);
  });

  test('v2 → v3 preserva fixos e seus lançamentos (o celular hoje)', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase
      ..execute(
        'INSERT INTO categories (id, name, icon_key, color, type, archived, '
        "sort_order) VALUES (1, 'Salário', 'payments', 0, 'income', 0, 0)",
      )
      ..execute(
        'INSERT INTO recurrences (id, amount_cents, category_id, '
        'day_of_month, active, last_generated_month, created_at) '
        'VALUES (3, 350000, 1, 5, 1, 202611, 1793588400)',
      )
      ..execute(
        'INSERT INTO transactions (id, amount_cents, date, category_id, '
        'created_at, recurrence_id) '
        'VALUES (9, 350000, 1793588400, 1, 1793588400, 3)',
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);

    final recurrence = (await db.select(db.recurrences).get()).single;
    expect(recurrence.dayOfMonth, 5);
    expect(recurrence.lastGeneratedMonth, 202611);
    final transaction = (await db.select(db.transactions).get()).single;
    expect(transaction.recurrenceId, 3);
    expect(transaction.installmentNumber, isNull);
  });
}
