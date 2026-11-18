import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/features/recurrences/domain/recurrence_schedule.dart';

/// Regras de compras parceladas.
abstract final class Installments {
  static const minCount = 2;
  static const maxCount = 48;

  /// Divide [totalCents] em [count] parcelas sem perder centavos: a sobra
  /// da divisão vai na primeira (como fazem as lojas).
  ///
  /// `split(10000, 3)` → `[3334, 3333, 3333]`.
  static List<int> split(int totalCents, int count) {
    final base = totalCents ~/ count;
    final remainder = totalCents - base * count;
    return [for (var i = 0; i < count; i++) i == 0 ? base + remainder : base];
  }

  /// Datas das parcelas: a primeira em [first] e as seguintes no mesmo dia
  /// dos meses seguintes (dia 31 vira o último dia em meses curtos).
  static List<DateTime> dates(DateTime first, int count) {
    var month = YearMonth.fromDate(first);
    final result = <DateTime>[];
    for (var i = 0; i < count; i++) {
      result.add(RecurrenceSchedule.dueDate(month, first.day));
      month = month.next;
    }
    return result;
  }
}
