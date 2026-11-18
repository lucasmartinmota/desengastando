import 'package:desengastando/core/date/year_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YearMonth', () {
    test('start é inclusivo e end é o início do mês seguinte', () {
      const m = YearMonth(2026, 11);
      expect(m.start, DateTime(2026, 11));
      expect(m.end, DateTime(2026, 12));
    });

    test('dezembro vira o ano em end e next', () {
      const m = YearMonth(2026, 12);
      expect(m.end, DateTime(2027));
      expect(m.next, const YearMonth(2027, 1));
    });

    test('janeiro volta o ano em previous', () {
      expect(const YearMonth(2027, 1).previous, const YearMonth(2026, 12));
    });

    test('contains respeita os limites do mês', () {
      const m = YearMonth(2026, 2);
      expect(m.contains(DateTime(2026, 2, 28, 23, 59)), isTrue);
      expect(m.contains(DateTime(2026, 3)), isFalse);
      expect(m.contains(DateTime(2025, 2, 10)), isFalse);
    });

    test('ordena cronologicamente', () {
      final list = [
        const YearMonth(2027, 1),
        const YearMonth(2026, 3),
        const YearMonth(2026, 12),
      ]..sort();
      expect(list, const [
        YearMonth(2026, 3),
        YearMonth(2026, 12),
        YearMonth(2027, 1),
      ]);
    });
  });
}
