import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/core/widgets/empty_state.dart';
import 'package:desengastando/core/widgets/month_switcher.dart';
import 'package:desengastando/features/transactions/data/transactions_providers.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/presentation/transaction_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthSummaryProvider).value ?? MonthSummary.empty;
    final isEmpty = summary == MonthSummary.empty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo'),
        bottom: const MonthSwitcher(),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo lançamento',
        onPressed: () => TransactionFormSheet.show(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(summary: summary),
          if (isEmpty)
            const EmptyState(
              emoji: '😮‍💨',
              title: 'Nada por aqui ainda',
              message:
                  'Respira fundo: assim que você lançar seus gastos, '
                  'o resumo do mês aparece aqui.',
            ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final MonthSummary summary;

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
          ],
        ),
      ),
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
