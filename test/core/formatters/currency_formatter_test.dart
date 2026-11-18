import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // O intl usa espaço não separável (U+00A0) entre o símbolo e o número.
  const nbsp = ' ';

  group('CurrencyFormatter.format', () {
    test('formata zero', () {
      expect(CurrencyFormatter.format(0), 'R\$${nbsp}0,00');
    });

    test('usa separador de milhar e vírgula decimal', () {
      expect(CurrencyFormatter.format(123456), 'R\$${nbsp}1.234,56');
    });

    test('formata centavos isolados', () {
      expect(CurrencyFormatter.format(5), 'R\$${nbsp}0,05');
    });

    test('formata valores negativos', () {
      expect(CurrencyFormatter.format(-1050), '-R\$${nbsp}10,50');
    });
  });
}
