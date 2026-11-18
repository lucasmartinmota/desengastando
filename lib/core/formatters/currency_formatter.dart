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

  static final NumberFormat _plain = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 2,
  );

  /// `R$ 1.234,56`
  static String format(int cents) => _brl.format(cents / 100);

  /// `1.234,56` (sem símbolo), para campos de entrada.
  static String formatPlain(int cents) => _plain.format(cents / 100);

  /// `+R$ 10,00` / `−R$ 10,00` (sinal de menos tipográfico); zero sem sinal.
  static final NumberFormat _compact = NumberFormat.compact(locale: 'pt_BR');

  /// `1,2 mil`, `350` — para eixos de gráfico (sem símbolo).
  static String formatCompact(int cents) => _compact.format(cents / 100);

  static String formatSigned(int cents) {
    if (cents == 0) return format(0);
    return cents < 0 ? '−${format(-cents)}' : '+${format(cents)}';
  }
}
