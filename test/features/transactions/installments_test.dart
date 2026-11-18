import 'package:desengastando/features/transactions/domain/installments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('split distribui a sobra na primeira parcela', () {
    expect(Installments.split(10000, 3), [3334, 3333, 3333]);
    expect(Installments.split(120000, 10), List.filled(10, 12000));
    expect(Installments.split(10000, 3).reduce((a, b) => a + b), 10000);
  });

  test('dates mantém o dia e ajusta meses curtos', () {
    expect(Installments.dates(DateTime(2026, 12, 31), 3), [
      DateTime(2026, 12, 31),
      DateTime(2027, 1, 31),
      DateTime(2027, 2, 28),
    ]);
  });
}
