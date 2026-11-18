// Padrão do Drift: `check(coluna...)` referencia o próprio getter; o gerador
// lê essa expressão estaticamente, ela nunca é executada em recursão.
// ignore_for_file: recursive_getters

import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart';

/// Categorias de despesa ou receita.
///
/// O tipo vive só aqui: uma transação herda o tipo da sua categoria,
/// o que impede combinações inválidas (ex.: "despesa" em "Salário").
@DataClassName('TransactionCategory')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Chave do ícone (ex.: `restaurant`), resolvida para `IconData` na UI.
  TextColumn get iconKey => text()();

  /// Cor em ARGB 32 bits.
  IntColumn get color => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {name, type},
  ];
}

@DataClassName('Transaction')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Valor sempre positivo, em centavos. O sinal vem do tipo da categoria.
  IntColumn get amountCents =>
      integer().check(amountCents.isBiggerThanValue(0))();
  DateTimeColumn get date => dateTime()();

  /// `restrict`: não dá para apagar categoria com lançamentos (arquive-a).
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get description => text().withLength(max: 120).nullable()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Lançamento fixo que gerou este (nulo nos lançados à mão). Apagar a
  /// recorrência mantém os lançamentos já feitos.
  IntColumn get recurrenceId => integer().nullable().references(
    Recurrences,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Compra parcelada a que esta parcela pertence (nulo se não for).
  IntColumn get installmentPlanId => integer().nullable().references(
    InstallmentPlans,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Número desta parcela (1 = primeira), quando parcelada.
  IntColumn get installmentNumber => integer().nullable()();
}

/// Compra parcelada: agrupa as parcelas, que são [Transactions] normais,
/// uma por mês.
class InstallmentPlans extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Quantidade total de parcelas.
  IntColumn get count => integer().check(count.isBiggerOrEqualValue(2))();
  IntColumn get totalCents =>
      integer().check(totalCents.isBiggerThanValue(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Lançamento fixo mensal (salário, aluguel, assinaturas...). Cada mês vira
/// um [Transactions] normal quando a data chega.
class Recurrences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountCents =>
      integer().check(amountCents.isBiggerThanValue(0))();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get description => text().withLength(max: 120).nullable()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>().nullable()();

  /// Dia do mês (1–31); em meses mais curtos vale o último dia.
  IntColumn get dayOfMonth =>
      integer().check(dayOfMonth.isBetweenValues(1, 31))();

  /// Pausada: não gera novos lançamentos.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Último mês já gerado (ou dado como resolvido), em `aaaamm`. Garante
  /// que cada mês saia uma vez só, mesmo que o lançamento seja apagado.
  IntColumn get lastGeneratedMonth => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Limite mensal de gasto por categoria de despesa (vale para todo mês).
class Budgets extends Table {
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get limitCents =>
      integer().check(limitCents.isBiggerThanValue(0))();

  @override
  Set<Column> get primaryKey => {categoryId};
}
