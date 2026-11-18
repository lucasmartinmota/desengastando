import 'package:desengastando/data/database/app_database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated_migrations/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v1 → v2 bate com o schema esperado', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('v1 → v2 preserva os lançamentos (como no celular)', () async {
    final schema = await verifier.schemaAt(1);
    // Banco v1 com uma categoria e um lançamento, sem passar pelo app.
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
    await verifier.migrateAndValidate(db, 2);

    final transactions = await db.select(db.transactions).get();
    expect(transactions.single.id, 7);
    expect(transactions.single.amountCents, 350000);
    expect(transactions.single.recurrenceId, isNull);
    expect(await db.select(db.recurrences).get(), isEmpty);
  });
}
