import 'package:desengastando/core/date/selected_month_provider.dart';
import 'package:desengastando/data/database/database_provider.dart';
import 'package:desengastando/features/transactions/data/transactions_dao.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transactions_providers.g.dart';

@Riverpod(keepAlive: true)
TransactionsDao transactionsDao(Ref ref) =>
    ref.watch(appDatabaseProvider).transactionsDao;

/// Lançamentos do mês selecionado.
@riverpod
Stream<List<TransactionWithCategory>> monthTransactions(Ref ref) => ref
    .watch(transactionsDaoProvider)
    .watchByMonth(ref.watch(selectedMonthProvider));

/// Totais do mês selecionado.
@riverpod
Stream<MonthSummary> monthSummary(Ref ref) => ref
    .watch(transactionsDaoProvider)
    .watchMonthSummary(ref.watch(selectedMonthProvider));
