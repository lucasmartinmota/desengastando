import 'package:desengastando/core/date/year_month.dart';

/// Regras de calendário de um lançamento fixo mensal.
///
/// Os lançamentos ficam criados com antecedência ([monthsAhead] meses à
/// frente), para os meses futuros já mostrarem salário, aluguel etc. A
/// janela anda sozinha: a cada abertura do app, completa até o novo limite.
abstract final class RecurrenceSchedule {
  /// Quantos meses depois do atual ficam lançados.
  static const monthsAhead = 12;

  /// Último mês que deve estar lançado, contando a partir de [today].
  static YearMonth horizon(DateTime today) {
    var month = YearMonth.fromDate(today);
    for (var i = 0; i < monthsAhead; i++) {
      month = month.next;
    }
    return month;
  }

  /// Data do lançamento em [month]. Dias que o mês não tem viram o último
  /// dia (dia 31 em fevereiro → 28 ou 29).
  static DateTime dueDate(YearMonth month, int dayOfMonth) => DateTime(
    month.year,
    month.month,
    dayOfMonth.clamp(1, month.daysInMonth),
  );

  /// Meses depois de [lastGenerated] até [until] (inclusive), do mais antigo
  /// ao mais recente.
  static List<YearMonth> pendingMonths({
    required YearMonth lastGenerated,
    required YearMonth until,
  }) => [
    for (
      var month = lastGenerated.next;
      month.compareTo(until) <= 0;
      month = month.next
    )
      month,
  ];

  /// Último mês que conta como "já resolvido" ao (re)ativar uma recorrência
  /// sem lançar nada para trás: o mês atual se a data dele já passou, senão
  /// o anterior.
  static YearMonth settledThrough(int dayOfMonth, DateTime today) {
    final current = YearMonth.fromDate(today);
    return dueDate(current, dayOfMonth).isAfter(today.dateOnly)
        ? current.previous
        : current;
  }

  /// Próxima data do lançamento a partir de hoje (inclusive).
  static DateTime nextDate(int dayOfMonth, DateTime today) {
    final current = YearMonth.fromDate(today);
    final thisMonth = dueDate(current, dayOfMonth);
    return thisMonth.isBefore(today.dateOnly)
        ? dueDate(current.next, dayOfMonth)
        : thisMonth;
  }
}
