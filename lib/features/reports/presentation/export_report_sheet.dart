import 'package:desengastando/core/date/selected_month_provider.dart';
import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:desengastando/features/backup/data/backup_providers.dart';
import 'package:desengastando/features/reports/data/report_service.dart';
import 'package:desengastando/features/reports/domain/report_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Mode { month, range }

/// Escolhe o período (um mês ou um intervalo livre), gera o relatório em
/// PDF e abre a folha de compartilhar.
class ExportReportSheet extends ConsumerStatefulWidget {
  const ExportReportSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const ExportReportSheet(),
  );

  @override
  ConsumerState<ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends ConsumerState<ExportReportSheet> {
  _Mode _mode = _Mode.month;
  late YearMonth _month;
  late DateTimeRange _range;
  bool _working = false;
  String? _error;

  ReportPeriod get _period => switch (_mode) {
    _Mode.month => ReportPeriod.month(_month),
    _Mode.range => ReportPeriod.range(_range.start, _range.end),
  };

  @override
  void initState() {
    super.initState();
    // Começa no mês que a pessoa está vendo no app.
    _month = ref.read(selectedMonthProvider);
    _range = DateTimeRange(
      start: _month.start,
      end: DateTime(_month.year, _month.month, _month.daysInMonth),
    );
  }

  void _update(VoidCallback change) => setState(() {
    change();
    _error = null;
  });

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Período do relatório',
    );
    if (picked != null) _update(() => _range = picked);
  }

  Future<void> _generate(BuildContext buttonContext) async {
    // O iPad ancora a folha de compartilhar no botão.
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final navigator = Navigator.of(context);
    final period = _period;
    setState(() {
      _working = true;
      _error = null;
    });

    void fail(String message) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = message;
      });
    }

    try {
      final service = ref.read(reportServiceProvider);
      final data = await service.load(period);
      if (data.isEmpty) {
        return fail('Nenhum lançamento nesse período.');
      }
      final bytes = await service.buildPdf(data);
      await ref
          .read(backupFilesProvider)
          .shareBytes(
            fileName: 'desengastando-relatorio-${period.fileSuffix}.pdf',
            bytes: bytes,
            mimeType: 'application/pdf',
            origin: origin,
          );
      navigator.pop();
    } on Exception {
      fail('Não foi possível gerar o PDF.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exportar PDF',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumo, gastos por categoria e todos os lançamentos do '
            'período, prontos para salvar, enviar ou imprimir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_Mode>(
            key: const Key('reportModeSelector'),
            segments: const [
              ButtonSegment(
                value: _Mode.month,
                label: Text('Mês'),
                icon: Icon(Icons.calendar_month_outlined),
              ),
              ButtonSegment(
                value: _Mode.range,
                label: Text('Período'),
                icon: Icon(Icons.date_range_outlined),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: _working
                ? null
                : (s) => _update(() => _mode = s.single),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: switch (_mode) {
              _Mode.month => Row(
                children: [
                  IconButton(
                    tooltip: 'Mês anterior',
                    onPressed: _working
                        ? null
                        : () => _update(() => _month = _month.previous),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      DateLabels.month(_month),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Próximo mês',
                    onPressed: _working
                        ? null
                        : () => _update(() => _month = _month.next),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              _Mode.range => OutlinedButton.icon(
                key: const Key('reportRangeButton'),
                onPressed: _working ? null : _pickRange,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: Text(ReportPeriod.range(_range.start, _range.end).dates),
              ),
            },
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Builder(
            builder: (buttonContext) => FilledButton.icon(
              onPressed: _working ? null : () => _generate(buttonContext),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _working
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_working ? 'Gerando...' : 'Gerar PDF'),
            ),
          ),
        ],
      ),
    );
  }
}
