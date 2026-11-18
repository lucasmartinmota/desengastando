/// Natureza de uma categoria (e, por consequência, das transações nela).
///
/// Persistido como texto (`name`): renomear um valor exige migração.
enum TransactionType {
  expense('Despesa'),
  income('Receita');

  const TransactionType(this.label);

  final String label;
}
