import 'package:desengastando/app/router.dart';
import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:desengastando/core/widgets/empty_state.dart';
import 'package:desengastando/core/widgets/month_switcher.dart';
import 'package:desengastando/features/budgets/data/budgets_providers.dart';
import 'package:desengastando/features/budgets/domain/budget_progress.dart';
import 'package:desengastando/features/budgets/presentation/budget_tile.dart';
import 'package:desengastando/features/dashboard/domain/expense_comparison.dart';
import 'package:desengastando/features/dashboard/presentation/category_ranking.dart';
import 'package:desengastando/features/dashboard/presentation/monthly_expenses_chart.dart';
import 'package:desengastando/features/transactions/data/transactions_providers.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/presentation/transaction_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthSummaryProvider).value ?? MonthSummary.empty;
    final byCategory = ref.watch(expensesByCategoryProvider).value ?? const [];
    final monthly = ref.watch(monthlyExpensesProvider).value ?? const [];
    // Os estourados primeiro, depois os mais perto do limite.
    final alerts = [
      for (final b
          in ref.watch(budgetProgressProvider).value ??
              const <BudgetProgress>[])
        if (b.status != BudgetStatus.ok) b,
    ]..sort((a, b) => b.ratio.compareTo(a.ratio));

    // O penúltimo item da série é o mês anterior ao selecionado.
    final comparison = monthly.length >= 2
        ? ExpenseComparison.between(
            currentCents: summary.expenseCents,
            previousCents: monthly[monthly.length - 2].totalCents,
          )
        : null;
    final hasHistory = monthly.any((m) => m.totalCents > 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo'),
        bottom: const MonthSwitcher(),
      ),
      floatingActionButton: FloatingActionButton(
        // Sem Hero: as abas ficam montadas no IndexedStack e os FABs
        // conflitariam ao abrir uma tela por cima.
        heroTag: null,
        tooltip: 'Novo lançamento',
        onPressed: () => TransactionFormSheet.show(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _BalanceCard(
            summary: summary,
            comparison: comparison,
            previousMonthLabel: monthly.length >= 2
                ? DateLabels.monthName(monthly[monthly.length - 2].month)
                : null,
          ),
          if (alerts.isNotEmpty)
            _Section(
              title: 'Orçamentos em alerta',
              child: Column(
                children: [
                  for (final progress in alerts)
                    BudgetTile(
                      progress: progress,
                      onTap: () => context.go(AppRoutes.budgets),
                    ),
                ],
              ),
            ),
          if (byCategory.isNotEmpty)
            _Section(
              title: 'Gastos por categoria',
              child: CategoryRanking(totals: byCategory),
            )
          else if (summary == MonthSummary.empty)
            const EmptyState(
              emoji: '😮‍💨',
              title: 'Nada por aqui ainda',
              message:
                  'Respira fundo: assim que você lançar seus gastos, '
                  'o resumo do mês aparece aqui.',
            ),
          if (hasHistory)
            _Section(
              title: 'Despesas nos últimos 6 meses',
              child: MonthlyExpensesChart(months: monthly),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.summary,
    required this.comparison,
    required this.previousMonthLabel,
  });

  final MonthSummary summary;
  final ExpenseComparison? comparison;
  final String? previousMonthLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo do mês', style: muted),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(summary.balanceCents),
              style: AppTheme.money(
                theme.textTheme.headlineMedium,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Receitas',
                    cents: summary.incomeCents,
                    color: context.finance.income,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Despesas',
                    cents: summary.expenseCents,
                    color: context.finance.expense,
                  ),
                ),
              ],
            ),
            if (comparison != null && previousMonthLabel != null) ...[
              const SizedBox(height: 12),
              _ComparisonLine(
                comparison: comparison!,
                previousMonthLabel: previousMonthLabel!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `↑ 12% a mais de gastos que em outubro` — em tinta neutra: a seta e o
/// texto carregam o sentido, não a cor.
class _ComparisonLine extends StatelessWidget {
  const _ComparisonLine({
    required this.comparison,
    required this.previousMonthLabel,
  });

  final ExpenseComparison comparison;
  final String previousMonthLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final percent = comparison.percent;
    final (icon, text) = switch (percent) {
      0 => (Icons.drag_handle_rounded, 'Gastos iguais aos de'),
      > 0 => (Icons.arrow_upward_rounded, '$percent% a mais de gastos que em'),
      _ => (
        Icons.arrow_downward_rounded,
        '${-percent}% a menos de gastos que em',
      ),
    };

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$text $previousMonthLabel',
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.cents, required this.color});

  final String label;
  final int cents;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          CurrencyFormatter.format(cents),
          style: AppTheme.money(
            theme.textTheme.titleMedium,
          ).copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
