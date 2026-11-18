import 'dart:math' as math;

import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Colunas com as despesas dos últimos meses; o último (mês selecionado)
/// fica em destaque. Tocar numa coluna fixa o valor; tocar de novo esconde.
class MonthlyExpensesChart extends StatefulWidget {
  const MonthlyExpensesChart({required this.months, super.key});

  final List<MonthTotal> months;

  @override
  State<MonthlyExpensesChart> createState() => _MonthlyExpensesChartState();
}

class _MonthlyExpensesChartState extends State<MonthlyExpensesChart> {
  int? _selected;

  List<MonthTotal> get months => widget.months;

  static final _monthAbbr = DateFormat('MMM', 'pt_BR');

  String _abbr(MonthTotal m) =>
      _monthAbbr.format(m.month.start).replaceAll('.', '');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final axisStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final maxReais = months.map((m) => m.totalCents).fold(0, math.max) / 100;
    final step = niceStep(maxReais / 3);
    final maxY = math.max(step, (maxReais / step).ceil() * step);

    final description = months
        .map(
          (m) =>
              '${DateLabels.month(m.month)}: '
              '${CurrencyFormatter.format(m.totalCents)}',
        )
        .join('; ');

    return Semantics(
      label: 'Despesas por mês. $description',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.7,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: step,
              getDrawingHorizontalLine: (_) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  interval: step,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      CurrencyFormatter.formatCompact((value * 100).round()),
                      maxLines: 1,
                      softWrap: false,
                      style: axisStyle,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(_abbr(months[value.toInt()]), style: axisStyle),
                  ),
                ),
              ),
            ),
            barTouchData: BarTouchData(
              // Toque fixa o tooltip (no celular não há hover).
              handleBuiltInTouches: false,
              touchCallback: (event, response) {
                if (event is! FlTapUpEvent) return;
                final index = response?.spot?.touchedBarGroupIndex;
                setState(() => _selected = index == _selected ? null : index);
              },
              touchTooltipData: BarTouchTooltipData(
                fitInsideVertically: true,
                fitInsideHorizontally: true,
                getTooltipColor: (_) => scheme.inverseSurface,
                tooltipBorderRadius: BorderRadius.circular(8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                      '${DateLabels.month(months[groupIndex].month)}\n',
                      theme.textTheme.labelSmall!.copyWith(
                        color: scheme.onInverseSurface,
                      ),
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.format(
                            months[groupIndex].totalCents,
                          ),
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: scheme.onInverseSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
            barGroups: [
              for (final (index, month) in months.indexed)
                BarChartGroupData(
                  x: index,
                  showingTooltipIndicators: index == _selected
                      ? const [0]
                      : const [],
                  barRods: [
                    BarChartRodData(
                      toY: month.totalCents / 100,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      // Mesmo tom; o mês em foco mais forte.
                      color: index == months.length - 1
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.4),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Passo "redondo" (1, 2 ou 5 × 10ⁿ) mais próximo acima de [raw], para
/// eixos com rótulos legíveis (ex.: 0, 1 mil, 2 mil, 3 mil).
double niceStep(double raw) {
  if (raw <= 0) return 1;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final normalized = raw / magnitude;
  final nice = normalized <= 1
      ? 1
      : normalized <= 2
      ? 2
      : normalized <= 5
      ? 5
      : 10;
  return nice * magnitude;
}
