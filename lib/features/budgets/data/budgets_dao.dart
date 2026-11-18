import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/data/database/tables.dart';
import 'package:desengastando/features/budgets/domain/budget_progress.dart';
import 'package:desengastando/features/budgets/domain/budget_with_category.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [Budgets, Categories, Transactions])
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

  /// Orçamentos ativos com o gasto de cada um em [month], na ordem das
  /// categorias. Com [categoryId], só o daquela categoria.
  JoinedSelectStatement<HasResultSet, dynamic> _progressQuery(
    YearMonth month, {
    int? categoryId,
  }) {
    final spent = transactions.amountCents.sum();
    final query =
        select(budgets).join([
            innerJoin(categories, categories.id.equalsExp(budgets.categoryId)),
            // Condição do mês no ON (e não no WHERE) para manter orçamentos
            // ainda sem gasto, com soma nula.
            leftOuterJoin(
              transactions,
              transactions.categoryId.equalsExp(budgets.categoryId) &
                  transactions.date.isBiggerOrEqualValue(month.start) &
                  transactions.date.isSmallerThanValue(month.end),
              useColumns: false,
            ),
          ])
          ..addColumns([spent])
          ..where(
            categories.archived.equals(false) &
                (categoryId == null
                    ? const Constant(true)
                    : budgets.categoryId.equals(categoryId)),
          )
          ..groupBy([budgets.categoryId])
          ..orderBy([
            OrderingTerm.asc(categories.sortOrder),
            OrderingTerm.asc(categories.name),
          ]);
    return query;
  }

  BudgetProgress _readProgress(TypedResult row) => BudgetProgress(
    category: row.readTable(categories),
    limitCents: row.readTable(budgets).limitCents,
    spentCents: row.read(transactions.amountCents.sum()) ?? 0,
  );

  Stream<List<BudgetProgress>> watchProgress(YearMonth month) => _progressQuery(
    month,
  ).watch().map((rows) => [for (final row in rows) _readProgress(row)]);

  /// Progresso do orçamento de uma categoria, ou `null` se ela não tem.
  Future<BudgetProgress?> getProgress(int categoryId, YearMonth month) async {
    final row = await _progressQuery(
      month,
      categoryId: categoryId,
    ).getSingleOrNull();
    return row == null ? null : _readProgress(row);
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
