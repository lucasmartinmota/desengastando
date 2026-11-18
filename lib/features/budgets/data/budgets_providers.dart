import 'package:desengastando/core/date/selected_month_provider.dart';
import 'package:desengastando/data/database/database_provider.dart';
import 'package:desengastando/features/budgets/data/budgets_dao.dart';
import 'package:desengastando/features/budgets/domain/budget_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// À mão, como em categories_providers: os tipos do Drift não são
// resolvidos pelo riverpod_generator na mesma passada.

final budgetsDaoProvider = Provider<BudgetsDao>(
  (ref) => ref.watch(appDatabaseProvider).budgetsDao,
);

/// Orçamentos com o gasto do mês selecionado.
final StreamProvider<List<BudgetProgress>> budgetProgressProvider =
    StreamProvider.autoDispose<List<BudgetProgress>>(
      (ref) => ref
          .watch(budgetsDaoProvider)
          .watchProgress(ref.watch(selectedMonthProvider)),
    );
