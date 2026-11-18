import 'package:desengastando/core/date/year_month.dart';

/// Regras de calendário de um lançamento fixo mensal.
///
/// O lançamento de cada mês só é criado quando a data dele chega (salário
/// do dia 5 aparece no dia 5), para o saldo do mês não contar dinheiro que
/// ainda não entrou nem conta que ainda não venceu.
abstract final class RecurrenceSchedule {
  /// Data do lançamento em [month]. Dias que o mês não tem viram o último
  /// dia (dia 31 em fevereiro → 28 ou 29).
  static DateTime dueDate(YearMonth month, int dayOfMonth) => DateTime(
    month.year,
    month.month,
    dayOfMonth.clamp(1, month.daysInMonth),
  );

  /// Meses depois de [lastGenerated] cuja data já chegou até [today],
  /// do mais antigo ao mais recente (preenche meses em que o app não abriu).
  static List<YearMonth> dueMonths({
    required YearMonth lastGenerated,
    required int dayOfMonth,
    required DateTime today,
  }) {
    final limit = today.dateOnly;
    return [
      for (
        var month = lastGenerated.next;
        !dueDate(month, dayOfMonth).isAfter(limit);
        month = month.next
      )
        month,
    ];
  }

  /// Último mês que conta como "já resolvido" ao (re)ativar uma recorrência
  /// sem lançar nada para trás: o mês atual se a data dele já passou, senão
  /// o anterior.
  static YearMonth settledThrough(int dayOfMonth, DateTime today) {
    final current = YearMonth.fromDate(today);
    return dueDate(current, dayOfMonth).isAfter(today.dateOnly)
        ? current.previous
        : current;
  }

  /// Próxima data do lançamento depois de [lastGenerated].
  static DateTime nextDate(YearMonth lastGenerated, int dayOfMonth) =>
      dueDate(lastGenerated.next, dayOfMonth);
}
