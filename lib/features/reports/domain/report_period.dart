import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Intervalo de datas de um relatório: um mês fechado ou um período livre.
@immutable
class ReportPeriod {
  const ReportPeriod._(this.start, this.end, this.month);

  factory ReportPeriod.month(YearMonth month) =>
      ReportPeriod._(month.start, month.end, month);

  /// De [first] a [last], ambos inclusivos (só a data conta, a hora não).
  /// Se o intervalo cobrir exatamente um mês, ele é tratado como esse mês.
  factory ReportPeriod.range(DateTime first, DateTime last) {
    var from = first.dateOnly;
    var to = last.dateOnly;
    if (to.isBefore(from)) (from, to) = (to, from);
    final month = YearMonth.fromDate(from);
    final end = DateTime(to.year, to.month, to.day + 1);
    final isWholeMonth = from == month.start && end == month.end;
    return ReportPeriod._(from, end, isWholeMonth ? month : null);
  }

  /// Primeiro dia (inclusivo), à meia-noite.
  final DateTime start;

  /// Dia seguinte ao último (exclusivo), à meia-noite.
  final DateTime end;

  /// O mês, quando o período é um mês fechado.
  final YearMonth? month;

  /// Último dia do período (inclusivo).
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  static final _day = DateFormat('dd/MM/yyyy');
  static final _fileDay = DateFormat('yyyy-MM-dd');

  /// `01/11/2026 a 30/11/2026`, sempre com as datas.
  String get dates => '${_day.format(start)} a ${_day.format(lastDay)}';

  /// `Novembro de 2026` ou `01/11/2026 a 15/12/2026`.
  String get label => switch (month) {
    final month? => DateLabels.month(month),
    null => dates,
  };

  /// Trecho do nome do arquivo: `2026-11` ou `2026-11-01_a_2026-12-15`.
  String get fileSuffix => switch (month) {
    final month? => month.toString(),
    null => '${_fileDay.format(start)}_a_${_fileDay.format(lastDay)}',
  };

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ReportPeriod($dates)';
}
