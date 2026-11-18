import 'package:desengastando/data/database/default_categories.dart';
import 'package:desengastando/data/database/tables.dart';
import 'package:desengastando/features/budgets/data/budgets_dao.dart';
import 'package:desengastando/features/categories/data/categories_dao.dart';
import 'package:desengastando/features/transactions/data/transactions_dao.dart';
import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

export 'package:drift/drift.dart' show Value;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions, Budgets],
  daos: [CategoriesDao, TransactionsDao, BudgetsDao],
)
class AppDatabase extends _$AppDatabase {
  /// Sem [executor], abre o arquivo SQLite do app. Testes passam um banco
  /// em memória.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  static QueryExecutor _open() => driftDatabase(
    name: 'desengastando',
    // Fora de Documents para não aparecer no app Arquivos do iOS.
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await batch((b) => b.insertAll(categories, defaultCategories));
    },
    beforeOpen: (details) async {
      // SQLite vem com chaves estrangeiras desligadas por padrão.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
