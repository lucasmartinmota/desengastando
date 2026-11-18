import 'package:desengastando/core/date/selected_month_provider.dart';
import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `‹ Novembro de 2026 ›` — troca o mês em foco do app.
///
/// Tocar no nome do mês volta para o mês atual.
class MonthSwitcher extends ConsumerWidget implements PreferredSizeWidget {
  const MonthSwitcher({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    final isCurrent = month == YearMonth.now();

    return SizedBox(
      height: preferredSize.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: notifier.previous,
          ),
          TextButton(
            onPressed: isCurrent ? null : notifier.goToCurrent,
            style: TextButton.styleFrom(
              disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            // Troca suave do rótulo ao mudar de mês.
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: Text(DateLabels.month(month), key: ValueKey(month)),
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: notifier.next,
          ),
        ],
      ),
    );
  }
}
