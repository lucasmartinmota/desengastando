import 'package:intl/intl.dart';

/// Formata valores monetários em reais.
///
/// Convenção do projeto: dinheiro é sempre `int` em **centavos**.
/// A conversão para `double` acontece só aqui, na hora de exibir.
abstract final class CurrencyFormatter {
  static final NumberFormat _brl = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  );

  static String format(int cents) => _brl.format(cents / 100);
}
