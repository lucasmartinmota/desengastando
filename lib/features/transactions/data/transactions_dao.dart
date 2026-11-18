import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/data/database/tables.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  Expression<bool> _inMonth(YearMonth month) =>
      transactions.date.isBiggerOrEqualValue(month.start) &
      transactions.date.isSmallerThanValue(month.end);

  /// Lançamentos do mês, do mais recente para o mais antigo.
  Stream<List<TransactionWithCategory>> watchByMonth(YearMonth month) {
    final query =
        select(transactions).join([
            innerJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
          ])
          ..where(_inMonth(month))
          ..orderBy([
            OrderingTerm.desc(transactions.date),
            OrderingTerm.desc(transactions.id),
          ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          TransactionWithCategory(
            transaction: row.readTable(transactions),
            category: row.readTable(categories),
          ),
      ],
    );
  }

  /// Total de receitas e despesas do mês.
  Stream<MonthSummary> watchMonthSummary(YearMonth month) {
    final total = transactions.amountCents.sum();
    final query =
        selectOnly(transactions).join([
            innerJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
              useColumns: false,
            ),
          ])
          ..addColumns([categories.type, total])
          ..where(_inMonth(month))
          ..groupBy([categories.type]);

    return query.watch().map((rows) {
      var income = 0;
      var expense = 0;
      for (final row in rows) {
        final value = row.read(total) ?? 0;
        switch (row.readWithConverter(categories.type)) {
          case TransactionType.income:
            income = value;
          case TransactionType.expense:
            expense = value;
          case null:
            break;
        }
      }
      return MonthSummary(incomeCents: income, expenseCents: expense);
    });
  }

  /// Gastos do mês agrupados por categoria, do maior para o menor.
  Stream<List<CategoryTotal>> watchExpensesByCategory(YearMonth month) {
    final total = transactions.amountCents.sum();
    final query =
        select(categories).join([
            innerJoin(
              transactions,
              transactions.categoryId.equalsExp(categories.id),
              useColumns: false,
            ),
          ])
          ..addColumns([total])
          ..where(
            categories.type.equalsValue(TransactionType.expense) &
                _inMonth(month),
          )
          ..groupBy([categories.id])
          ..orderBy([OrderingTerm.desc(total)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          CategoryTotal(
            category: row.readTable(categories),
            totalCents: row.read(total) ?? 0,
          ),
      ],
    );
  }

  Future<int> addTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> updateTransaction(Transaction transaction) =>
      update(transactions).replace(transaction);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();
}
