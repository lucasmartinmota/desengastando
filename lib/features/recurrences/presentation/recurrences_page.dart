import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:desengastando/core/widgets/empty_state.dart';
import 'package:desengastando/features/categories/presentation/category_icons.dart';
import 'package:desengastando/features/recurrences/data/recurrences_providers.dart';
import 'package:desengastando/features/recurrences/domain/recurrence_with_category.dart';
import 'package:desengastando/features/recurrences/presentation/recurrence_form_sheet.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lista de lançamentos fixos (receitas e contas que se repetem todo mês).
class RecurrencesPage extends ConsumerWidget {
  const RecurrencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurrences = ref.watch(recurrencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lançamentos fixos')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => RecurrenceFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo fixo'),
      ),
      body: recurrences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              emoji: '🔁',
              title: 'Nenhum lançamento fixo',
              message:
                  'Salário, aluguel, assinaturas... cadastre uma vez e o app '
                  'lança sozinho todo mês.',
            );
          }
          List<RecurrenceWithCategory> ofType(TransactionType type) => [
            for (final r in items)
              if (r.category.type == type) r,
          ];
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final type in [
                TransactionType.income,
                TransactionType.expense,
              ])
                if (ofType(type) case final list when list.isNotEmpty)
                  _Section(type: type, items: list),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.type, required this.items});

  final TransactionType type;
  final List<RecurrenceWithCategory> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthly = items
        .where((r) => r.recurrence.active)
        .fold(0, (sum, r) => sum + r.recurrence.amountCents);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Row(
            children: [
              Text(
                type == TransactionType.income
                    ? 'Receitas fixas'
                    : 'Contas fixas',
                style: headerStyle,
              ),
              const Spacer(),
              Text(
                '${CurrencyFormatter.format(monthly)} por mês',
                style: AppTheme.money(headerStyle),
              ),
            ],
          ),
        ),
        for (final item in items) _RecurrenceTile(item: item),
      ],
    );
  }
}

class _RecurrenceTile extends StatelessWidget {
  const _RecurrenceTile({required this.item});

  final RecurrenceWithCategory item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recurrence = item.recurrence;
    final description = recurrence.description;
    final isExpense = item.category.type == TransactionType.expense;
    final schedule = recurrence.active
        ? 'Todo dia ${recurrence.dayOfMonth} · próximo '
              '${DateLabels.day(item.nextDate).toLowerCase()}'
        : 'Pausado';

    final tile = ListTile(
      onTap: () => RecurrenceFormSheet.show(context, initial: item),
      leading: CategoryAvatar(category: item.category),
      title: Text(
        description == null || description.isEmpty
            ? item.category.name
            : description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(schedule),
      trailing: Text(
        CurrencyFormatter.formatSigned(
          isExpense ? -recurrence.amountCents : recurrence.amountCents,
        ),
        style: AppTheme.money(theme.textTheme.titleSmall).copyWith(
          fontWeight: FontWeight.w700,
          color: isExpense ? context.finance.expense : context.finance.income,
        ),
      ),
    );
    return recurrence.active ? tile : Opacity(opacity: 0.55, child: tile);
  }
}
