import 'package:flutter/foundation.dart';

/// Um mês específico (ex.: novembro/2026), unidade básica dos resumos.
@immutable
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month)
    : assert(month >= 1 && month <= 12, 'month deve estar entre 1 e 12');

  factory YearMonth.fromDate(DateTime date) => YearMonth(date.year, date.month);

  factory YearMonth.now() => YearMonth.fromDate(DateTime.now());

  final int year;
  final int month;

  /// Primeiro instante do mês (inclusivo).
  DateTime get start => DateTime(year, month);

  /// Primeiro instante do mês seguinte (exclusivo).
  DateTime get end => DateTime(year, month + 1);

  YearMonth get next => YearMonth.fromDate(DateTime(year, month + 1));

  YearMonth get previous => YearMonth.fromDate(DateTime(year, month - 1));

  bool contains(DateTime date) => date.year == year && date.month == month;

  @override
  int compareTo(YearMonth other) => year != other.year
      ? year.compareTo(other.year)
      : month.compareTo(other.month);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

extension DateOnlyX on DateTime {
  /// Mesmo dia, à meia-noite (horário local).
  DateTime get dateOnly => DateTime(year, month, day);
}
