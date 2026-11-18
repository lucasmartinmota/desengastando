/// Forma de pagamento/recebimento de uma transação.
///
/// Persistido como texto (`name`): renomear um valor exige migração.
enum PaymentMethod {
  pix('Pix'),
  debitCard('Débito'),
  creditCard('Crédito'),
  cash('Dinheiro'),
  bankTransfer('Transferência'),
  other('Outro');

  const PaymentMethod(this.label);

  final String label;
}
