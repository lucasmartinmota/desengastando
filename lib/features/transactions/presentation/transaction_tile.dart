import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/features/categories/presentation/category_icons.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.item, required this.onTap, super.key});

  final TransactionWithCategory item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaction = item.transaction;
    final category = item.category;

    final description = transaction.description;
    final hasDescription = description != null && description.isNotEmpty;
    final subtitle = [
      if (hasDescription) category.name,
      if (item.installmentLabel case final label?) 'Parcela $label',
      if (transaction.paymentMethod case final method?) method.label,
      if (item.isScheduled()) 'Previsto',
    ].join(' · ');
    final kindIcon = transaction.installmentPlanId != null
        ? Icons.credit_card_rounded
        : transaction.recurrenceId != null
        ? Icons.event_repeat_rounded
        : null;
    final kindLabel = transaction.installmentPlanId != null
        ? 'Parcelado'
        : 'Fixo';

    final signed = item.signedCents;
    final amountColor = signed < 0
        ? context.finance.expense
        : context.finance.income;

    return ListTile(
      onTap: onTap,
      leading: CategoryAvatar(category: category),
      title: Text(
        hasDescription ? description : category.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle.isEmpty && kindIcon == null
          ? null
          : Text.rich(
              TextSpan(
                children: [
                  if (kindIcon != null) ...[
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        kindIcon,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                        semanticLabel: kindLabel,
                      ),
                    ),
                    TextSpan(text: subtitle.isEmpty ? ' $kindLabel' : ' '),
                  ],
                  TextSpan(text: subtitle),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Text(
        CurrencyFormatter.formatSigned(signed),
        style: AppTheme.money(
          theme.textTheme.titleSmall,
        ).copyWith(color: amountColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
