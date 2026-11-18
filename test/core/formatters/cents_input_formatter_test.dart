import 'package:desengastando/core/formatters/cents_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final formatter = CentsInputFormatter();

  /// Simula o usuário digitando [input] sobre o texto [from].
  String type(String input, {String from = ''}) => formatter
      .formatEditUpdate(
        TextEditingValue(text: from),
        TextEditingValue(text: '$from$input'),
      )
      .text;

  group('CentsInputFormatter', () {
    test('dígitos entram pela direita', () {
      var text = '';
      final steps = <String>[];
      for (final digit in ['1', '2', '5', '0']) {
        text = type(digit, from: text);
        steps.add(text);
      }
      expect(steps, ['0,01', '0,12', '1,25', '12,50']);
    });

    test('aplica separador de milhar', () {
      expect(type('123456789'), '1.234.567,89');
    });

    test('apagar remove o último dígito', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '12,50'),
        const TextEditingValue(text: '12,5'),
      );
      expect(result.text, '1,25');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('apagar tudo deixa o campo vazio', () {
      expect(type('', from: '0,0'), '');
    });

    test('ignora caracteres que não são dígitos', () {
      expect(type('1a2-3'), '1,23');
    });

    test('recusa além do limite de dígitos', () {
      final limited = CentsInputFormatter(maxDigits: 3);
      final result = limited.formatEditUpdate(
        const TextEditingValue(text: '1,23'),
        const TextEditingValue(text: '1,234'),
      );
      expect(result.text, '1,23');
    });

    test('parse e format são inversos', () {
      expect(CentsInputFormatter.parse('1.234,56'), 123456);
      expect(CentsInputFormatter.parse(''), 0);
      expect(CentsInputFormatter.format(123456), '1.234,56');
      expect(CentsInputFormatter.format(0), '');
    });
  });
}
