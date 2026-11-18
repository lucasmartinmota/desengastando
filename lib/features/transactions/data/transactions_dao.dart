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

  /// Despesas por mês nos [months] meses terminando em [last] (inclusive),
  /// do mais antigo ao mais recente, com zero nos meses sem gastos.
  ///
  /// O agrupamento é feito em Dart, com a data local: o `strftime` do SQLite
  /// trabalha em UTC e jogaria gastos da meia-noite para o mês errado em
  /// fusos positivos.
  Stream<List<MonthTotal>> watchMonthlyExpenses({
    required YearMonth last,
    int months = 6,
  }) {
    final range = [
      for (var m = last, i = 0; i < months; m = m.previous, i++) m,
    ].reversed.toList();

    final query =
        selectOnly(transactions).join([
            innerJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
              useColumns: false,
            ),
          ])
          ..addColumns([transactions.date, transactions.amountCents])
          ..where(
            categories.type.equalsValue(TransactionType.expense) &
                transactions.date.isBiggerOrEqualValue(range.first.start) &
                transactions.date.isSmallerThanValue(last.end),
          );

    return query.watch().map((rows) {
      final totals = {for (final m in range) m: 0};
      for (final row in rows) {
        final month = YearMonth.fromDate(row.read(transactions.date)!);
        totals.update(
          month,
          (sum) => sum + row.read(transactions.amountCents)!,
          ifAbsent: () => 0,
        );
      }
      return [
        for (final m in range) MonthTotal(month: m, totalCents: totals[m]!),
      ];
    });
  }

  Future<int> addTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> updateTransaction(Transaction transaction) =>
      update(transactions).replace(transaction);

  /// Reinsere um lançamento excluído com o mesmo id (para o "Desfazer").
  Future<int> restoreTransaction(Transaction transaction) =>
      into(transactions).insert(transaction);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();
}
