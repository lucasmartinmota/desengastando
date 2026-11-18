import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/core/widgets/empty_state.dart';
import 'package:desengastando/core/widgets/month_switcher.dart';
import 'package:desengastando/features/budgets/data/budgets_providers.dart';
import 'package:desengastando/features/budgets/domain/budget_progress.dart';
import 'package:desengastando/features/budgets/presentation/budget_form_sheet.dart';
import 'package:desengastando/features/budgets/presentation/budget_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProgressProvider);
    final hasBudgets = budgets.value?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
        bottom: const MonthSwitcher(),
      ),
      floatingActionButton: hasBudgets
          ? FloatingActionButton(
              // Sem Hero: abas montadas no IndexedStack (ver Resumo).
              heroTag: null,
              tooltip: 'Novo orçamento',
              onPressed: () => BudgetFormSheet.show(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Erro ao carregar orçamentos: $error')),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              emoji: '🐷',
              title: 'Sem orçamentos definidos',
              message:
                  'Defina limites por categoria e a gente avisa antes de '
                  'apertar.',
              action: FilledButton.icon(
                onPressed: () => BudgetFormSheet.show(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Definir orçamento'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _TotalsCard(items: items),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    children: [
                      for (final progress in items)
                        BudgetTile(
                          progress: progress,
                          onTap: () =>
                              BudgetFormSheet.show(context, initial: progress),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Visão geral: quanto foi orçado, gasto e quanto sobra no mês.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.items});

  final List<BudgetProgress> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totals = BudgetTotals.of(items);
    final alerts = items.where((b) => b.status != BudgetStatus.ok).length;
    final muted = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final ratio = totals.limitCents == 0
        ? 0.0
        : totals.spentCents / totals.limitCents;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              totals.remainingCents >= 0
                  ? 'Ainda dá para gastar'
                  : 'Acima do orçado',
              style: muted,
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(totals.remainingCents.abs()),
              style: AppTheme.money(
                theme.textTheme.headlineMedium,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 8,
                color: scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${CurrencyFormatter.format(totals.spentCents)} gastos de '
              '${CurrencyFormatter.format(totals.limitCents)} orçados',
              style: AppTheme.money(
                theme.textTheme.bodySmall,
              ).copyWith(color: scheme.onSurfaceVariant),
            ),
            if (alerts > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: BudgetStatus.warning.color(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alerts == 1
                        ? '1 categoria pede atenção'
                        : '$alerts categorias pedem atenção',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
