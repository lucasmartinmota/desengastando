import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/core/widgets/progress_bar.dart';
import 'package:desengastando/features/categories/presentation/category_icons.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:flutter/material.dart';

/// Gastos por categoria como barras horizontais ranqueadas.
///
/// Barras num único tom (a identidade da categoria está no ícone e no nome);
/// o comprimento é a fatia do total do mês, rotulada em % e em reais.
class CategoryRanking extends StatelessWidget {
  const CategoryRanking({required this.totals, super.key});

  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    final sum = totals.fold(0, (acc, t) => acc + t.totalCents);
    return Column(
      children: [
        for (final total in totals)
          _RankRow(total: total, share: sum == 0 ? 0 : total.totalCents / sum),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.total, required this.share});

  final CategoryTotal total;
  final double share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = '${(share * 100).round()}%';
    final amount = CurrencyFormatter.format(total.totalCents);

    return Semantics(
      label: '${total.category.name}: $amount, $percent dos gastos',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CategoryAvatar(category: total.category, radius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          total.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        amount,
                        style: AppTheme.money(
                          theme.textTheme.bodyMedium,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          percent,
                          textAlign: TextAlign.end,
                          style: AppTheme.money(
                            theme.textTheme.bodySmall,
                          ).copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ProgressBar(value: share, color: scheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
