import 'package:desengastando/features/dashboard/domain/expense_comparison.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int? percent(int current, int previous) => ExpenseComparison.between(
    currentCents: current,
    previousCents: previous,
  )?.percent;

  test('aumento, queda e igualdade em % arredondado', () {
    expect(percent(11200, 10000), 12);
    expect(percent(9150, 10000), -9); // -8,5% arredonda para -9
    expect(percent(10000, 10000), 0);
    expect(percent(0, 10000), -100);
  });

  test('sem gastos no mês anterior não há comparação', () {
    expect(percent(5000, 0), isNull);
  });
}
