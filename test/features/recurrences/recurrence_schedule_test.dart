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

  test('horizon fica 12 meses à frente', () {
    expect(
      RecurrenceSchedule.horizon(DateTime(2026, 11, 18)),
      const YearMonth(2027, 11),
    );
  });

  test('pendingMonths vai do mês seguinte até o limite', () {
    expect(
      RecurrenceSchedule.pendingMonths(
        lastGenerated: const YearMonth(2026, 11),
        until: const YearMonth(2027, 2),
      ),
      [
        const YearMonth(2026, 12),
        const YearMonth(2027, 1),
        const YearMonth(2027, 2),
      ],
    );
    expect(
      RecurrenceSchedule.pendingMonths(
        lastGenerated: const YearMonth(2027, 2),
        until: const YearMonth(2027, 2),
      ),
      isEmpty,
    );
  });

  test('nextDate: hoje conta; se já passou, vai para o próximo mês', () {
    final today = DateTime(2026, 11, 18, 15);
    expect(RecurrenceSchedule.nextDate(18, today), DateTime(2026, 11, 18));
    expect(RecurrenceSchedule.nextDate(5, today), DateTime(2026, 12, 5));
    expect(RecurrenceSchedule.nextDate(25, today), DateTime(2026, 11, 25));
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
