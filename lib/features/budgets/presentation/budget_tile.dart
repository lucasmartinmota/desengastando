import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/features/budgets/domain/budget_progress.dart';
import 'package:desengastando/features/categories/presentation/category_icons.dart';
import 'package:flutter/material.dart';

/// Visual de cada faixa: a cor nunca vem sozinha, sempre com ícone e texto.
extension BudgetStatusStyle on BudgetStatus {
  Color color(BuildContext context) => switch (this) {
    BudgetStatus.ok => Theme.of(context).colorScheme.primary,
    BudgetStatus.warning => context.finance.warning,
    BudgetStatus.over => context.finance.expense,
  };

  IconData get icon => switch (this) {
    BudgetStatus.ok => Icons.check_circle_outline_rounded,
    BudgetStatus.warning => Icons.warning_amber_rounded,
    BudgetStatus.over => Icons.error_outline_rounded,
  };
}

/// Frase de quanto sobra ou quanto passou.
String budgetRemainingLabel(int remainingCents) => remainingCents >= 0
    ? 'Restam ${CurrencyFormatter.format(remainingCents)}'
    : 'Passou ${CurrencyFormatter.format(-remainingCents)}';

/// Linha de um orçamento: categoria, gasto/limite, barra e situação.
class BudgetTile extends StatelessWidget {
  const BudgetTile({required this.progress, this.onTap, super.key});

  final BudgetProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = progress.status;
    final statusColor = status.color(context);
    final muted = AppTheme.money(
      theme.textTheme.bodySmall,
    ).copyWith(color: scheme.onSurfaceVariant);
    final spent = CurrencyFormatter.format(progress.spentCents);
    final limit = CurrencyFormatter.format(progress.limitCents);
    final remaining = budgetRemainingLabel(progress.remainingCents);
    // Curto para caber na linha; o ícone já sinaliza o alerta e o leitor
    // de tela recebe a frase completa.
    final statusText = progress.remainingCents == 0 ? 'No limite' : remaining;
    final statusSemantics = switch (status) {
      BudgetStatus.ok => statusText,
      BudgetStatus.warning => '$statusText, perto do limite',
      BudgetStatus.over => '$statusText, orçamento estourado',
    };

    return Semantics(
      label:
          '${progress.category.name}: $spent de $limit, '
          '${progress.percent}%. $statusSemantics',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              CategoryAvatar(category: progress.category, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            progress.category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${progress.percent}%',
                          style: AppTheme.money(
                            theme.textTheme.bodyMedium,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.ratio.clamp(0, 1),
                        minHeight: 8,
                        color: statusColor,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$spent de $limit',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (status != BudgetStatus.ok) ...[
                          Icon(status.icon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                        ],
                        Text(statusText, style: muted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
