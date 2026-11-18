import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/features/recurrences/domain/recurrence_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dueDate', () {
    test('usa o dia pedido', () {
      expect(
        RecurrenceSchedule.dueDate(const YearMonth(2026, 11), 5),
        DateTime(2026, 11, 5),
      );
    });
    test('dia 31 em mês curto vira o último dia', () {
      expect(
        RecurrenceSchedule.dueDate(const YearMonth(2027, 2), 31),
        DateTime(2027, 2, 28),
      );
      expect(
        RecurrenceSchedule.dueDate(const YearMonth(2028, 2), 30),
        DateTime(2028, 2, 29),
      );
    });
  });

  group('dueMonths', () {
    test('só o mês cuja data já chegou', () {
      expect(
        RecurrenceSchedule.dueMonths(
          lastGenerated: const YearMonth(2026, 10),
          dayOfMonth: 5,
          today: DateTime(2026, 11, 18, 9),
        ),
        [const YearMonth(2026, 11)],
      );
    });
    test('no próprio dia já lança; antes, não', () {
      expect(
        RecurrenceSchedule.dueMonths(
          lastGenerated: const YearMonth(2026, 10),
          dayOfMonth: 18,
          today: DateTime(2026, 11, 18, 0, 1),
        ),
        hasLength(1),
      );
      expect(
        RecurrenceSchedule.dueMonths(
          lastGenerated: const YearMonth(2026, 10),
          dayOfMonth: 19,
          today: DateTime(2026, 11, 18, 23, 59),
        ),
        isEmpty,
      );
    });
    test('preenche os meses em que o app não foi aberto', () {
      expect(
        RecurrenceSchedule.dueMonths(
          lastGenerated: const YearMonth(2026, 10),
          dayOfMonth: 10,
          today: DateTime(2027, 1, 10),
        ),
        [
          const YearMonth(2026, 11),
          const YearMonth(2026, 12),
          const YearMonth(2027, 1),
        ],
      );
    });
  });

  test('settledThrough: mês atual se a data já passou, senão o anterior', () {
    final today = DateTime(2026, 11, 18);
    expect(
      RecurrenceSchedule.settledThrough(5, today),
      const YearMonth(2026, 11),
    );
    expect(
      RecurrenceSchedule.settledThrough(25, today),
      const YearMonth(2026, 10),
    );
  });

  test('YearMonth.key ida e volta', () {
    expect(const YearMonth(2026, 11).key, 202611);
    expect(YearMonth.fromKey(202611), const YearMonth(2026, 11));
  });
}
