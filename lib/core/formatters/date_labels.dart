import 'package:desengastando/core/date/year_month.dart';
import 'package:intl/intl.dart';

abstract final class DateLabels {
  /// `Hoje`, `Ontem` ou `seg., 16 de nov.` (com ano se não for o atual).
  static String day(DateTime date, {DateTime? now}) {
    final today = (now ?? DateTime.now()).dateOnly;
    final day = date.dateOnly;
    if (day == today) return 'Hoje';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Ontem';
    }
    final pattern = day.year == today.year
        ? "EEE, d 'de' MMM"
        : "d 'de' MMM 'de' y";
    return DateFormat(pattern, 'pt_BR').format(day);
  }

  /// `outubro` (só o nome, minúsculo)
  static String monthName(YearMonth month) =>
      DateFormat('MMMM', 'pt_BR').format(month.start);

  /// `Novembro de 2026`
  static String month(YearMonth month) {
    final text = DateFormat("MMMM 'de' y", 'pt_BR').format(month.start);
    return text[0].toUpperCase() + text.substring(1);
  }
}
