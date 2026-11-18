import 'package:desengastando/features/dashboard/presentation/monthly_expenses_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('niceStep arredonda para 1, 2 ou 5 × 10ⁿ', () {
    expect(niceStep(1013), 2000);
    expect(niceStep(800), 1000);
    expect(niceStep(150), 200);
    expect(niceStep(30), 50);
    expect(niceStep(1000), 1000);
    expect(niceStep(0), 1);
  });
}
