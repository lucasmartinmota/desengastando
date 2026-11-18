import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Quarta-feira, 18/11/2026.
  final now = DateTime(2026, 11, 18, 15, 30);

  group('DateLabels.day', () {
    test('hoje e ontem ignoram o horário', () {
      expect(DateLabels.day(DateTime(2026, 11, 18, 0, 1), now: now), 'Hoje');
      expect(DateLabels.day(DateTime(2026, 11, 17, 23, 59), now: now), 'Ontem');
    });

    test('ontem atravessa a virada do mês', () {
      expect(
        DateLabels.day(DateTime(2026, 10, 31), now: DateTime(2026, 11)),
        'Ontem',
      );
    });

    test('outros dias do ano mostram dia da semana', () {
      expect(
        DateLabels.day(DateTime(2026, 11, 16), now: now),
        'seg., 16 de nov.',
      );
    });

    test('outro ano mostra o ano', () {
      expect(
        DateLabels.day(DateTime(2025, 12, 25), now: now),
        '25 de dez. de 2025',
      );
    });
  });

  test('DateLabels.month capitaliza o mês', () {
    expect(DateLabels.month(const YearMonth(2026, 11)), 'Novembro de 2026');
  });
}
