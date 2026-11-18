import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:flutter/services.dart';

/// Campo de valor no estilo de app de banco: os dígitos entram pela direita.
///
/// Digitar `1`, `2`, `5`, `0` resulta em `12,50`.
class CentsInputFormatter extends TextInputFormatter {
  CentsInputFormatter({this.maxDigits = 11});

  /// 11 dígitos = até 999.999.999,99.
  final int maxDigits;

  static final _nonDigits = RegExp(r'\D');
  static final _leadingZeros = RegExp('^0+');

  /// Centavos representados pelo texto do campo (0 se vazio).
  static int parse(String text) =>
      int.tryParse(text.replaceAll(_nonDigits, '')) ?? 0;

  /// Texto do campo para um valor em centavos (vazio se 0).
  static String format(int cents) =>
      cents <= 0 ? '' : CurrencyFormatter.formatPlain(cents);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text
        .replaceAll(_nonDigits, '')
        .replaceFirst(_leadingZeros, '');
    if (digits.length > maxDigits) return oldValue;

    final text = format(int.tryParse(digits) ?? 0);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
