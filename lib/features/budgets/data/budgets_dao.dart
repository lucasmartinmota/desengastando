import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/data/database/tables.dart';
import 'package:desengastando/features/budgets/domain/budget_with_category.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [Budgets, Categories])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.attachedDatabase);

  /// Orçamentos de categorias ativas, na ordem das categorias.
  Stream<List<BudgetWithCategory>> watchBudgets() {
    final query =
        select(budgets).join([
            innerJoin(categories, categories.id.equalsExp(budgets.categoryId)),
          ])
          ..where(categories.archived.equals(false))
          ..orderBy([
            OrderingTerm.asc(categories.sortOrder),
            OrderingTerm.asc(categories.name),
          ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          BudgetWithCategory(
            budget: row.readTable(budgets),
            category: row.readTable(categories),
          ),
      ],
    );
  }

  /// Define (ou substitui) o limite mensal de uma categoria de despesa.
  Future<void> setBudget({
    required int categoryId,
    required int limitCents,
  }) async {
    final category = await (select(
      categories,
    )..where((c) => c.id.equals(categoryId))).getSingle();
    if (category.type != TransactionType.expense) {
      throw ArgumentError.value(
        categoryId,
        'categoryId',
        'Orçamento só pode ser definido para categorias de despesa',
      );
    }
    await into(budgets).insertOnConflictUpdate(
      BudgetsCompanion.insert(
        categoryId: Value(categoryId),
        limitCents: limitCents,
      ),
    );
  }

  Future<int> removeBudget(int categoryId) =>
      (delete(budgets)..where((b) => b.categoryId.equals(categoryId))).go();
}
