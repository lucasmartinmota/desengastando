import 'package:desengastando/app/router.dart';
import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:desengastando/core/widgets/empty_state.dart';
import 'package:desengastando/core/widgets/month_switcher.dart';
import 'package:desengastando/features/transactions/data/transactions_providers.dart';
import 'package:desengastando/features/transactions/domain/day_group.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/presentation/delete_with_undo.dart';
import 'package:desengastando/features/transactions/presentation/transaction_form_sheet.dart';
import 'package:desengastando/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  /// Ids removidos por swipe: somem na hora, antes do banco emitir a nova
  /// lista (o `Dismissible` exige sair da árvore imediatamente).
  final _hidden = <int>{};

  Future<void> _delete(TransactionWithCategory item) async {
    final id = item.transaction.id;
    setState(() => _hidden.add(id));
    await deleteTransactionWithUndo(
      messenger: ScaffoldMessenger.of(context),
      dao: ref.read(transactionsDaoProvider),
      transaction: item.transaction,
      onUndone: () {
        if (mounted) setState(() => _hidden.remove(id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Quando o banco confirma a exclusão (o id sumiu da lista), o id sai de
    // `_hidden`; senão, se o mesmo id voltasse (ex.: restaurar um backup),
    // a linha continuaria escondida.
    ref.listen(monthTransactionsProvider, (_, next) {
      final items = next.value;
      if (items == null || _hidden.isEmpty) return;
      final present = {for (final t in items) t.transaction.id};
      _hidden.removeWhere((id) => !present.contains(id));
    });
    final transactions = ref.watch(monthTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamentos'),
        actions: [
          IconButton(
            tooltip: 'Lançamentos fixos',
            icon: const Icon(Icons.event_repeat_rounded),
            onPressed: () => context.push(AppRoutes.recurrences),
          ),
          IconButton(
            tooltip: 'Categorias',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push(AppRoutes.categories),
          ),
        ],
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
      body: transactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Erro ao carregar lançamentos: $error')),
        data: (items) {
          final visible = [
            for (final item in items)
              if (!_hidden.contains(item.transaction.id)) item,
          ];
          if (visible.isEmpty) {
            return const EmptyState(
              emoji: '🧾',
              title: 'Nenhum lançamento neste mês',
              message: 'Respira fundo, tá tudo bem. Toque no + para registrar.',
            );
          }
          final groups = groupByDay(visible);
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: groups.length,
            itemBuilder: (context, index) => _DaySection(
              group: groups[index],
              onDismissed: _delete,
            ),
          );
        },
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.group, required this.onDismissed});

  final DayGroup group;
  final ValueChanged<TransactionWithCategory> onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(DateLabels.day(group.day), style: headerStyle),
              const Spacer(),
              Text(
                CurrencyFormatter.formatSigned(group.balanceCents),
                style: AppTheme.money(headerStyle),
              ),
            ],
          ),
        ),
        for (final item in group.items)
          Dismissible(
            key: ValueKey(item.transaction.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: context.finance.expense,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
              ),
            ),
            onDismissed: (_) => onDismissed(item),
            child: TransactionTile(
              item: item,
              onTap: () => TransactionFormSheet.show(context, initial: item),
            ),
          ),
      ],
    );
  }
}
