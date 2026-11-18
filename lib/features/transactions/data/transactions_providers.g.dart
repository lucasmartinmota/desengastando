// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionsDao)
final transactionsDaoProvider = TransactionsDaoProvider._();

final class TransactionsDaoProvider
    extends
        $FunctionalProvider<TransactionsDao, TransactionsDao, TransactionsDao>
    with $Provider<TransactionsDao> {
  TransactionsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionsDaoHash();

  @$internal
  @override
  $ProviderElement<TransactionsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TransactionsDao create(Ref ref) {
    return transactionsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionsDao>(value),
    );
  }
}

String _$transactionsDaoHash() => r'003d5609c112c77ff22952057c6cf2e07ccbddd1';

/// Lançamentos do mês selecionado.

@ProviderFor(monthTransactions)
final monthTransactionsProvider = MonthTransactionsProvider._();

/// Lançamentos do mês selecionado.

final class MonthTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TransactionWithCategory>>,
          List<TransactionWithCategory>,
          Stream<List<TransactionWithCategory>>
        >
    with
        $FutureModifier<List<TransactionWithCategory>>,
        $StreamProvider<List<TransactionWithCategory>> {
  /// Lançamentos do mês selecionado.
  MonthTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthTransactionsHash();

  @$internal
  @override
  $StreamProviderElement<List<TransactionWithCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TransactionWithCategory>> create(Ref ref) {
    return monthTransactions(ref);
  }
}

String _$monthTransactionsHash() => r'2d6fe94e5b1ab292ba330c36ef0e2fbacca68aff';

/// Totais do mês selecionado.

@ProviderFor(monthSummary)
final monthSummaryProvider = MonthSummaryProvider._();

/// Totais do mês selecionado.

final class MonthSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<MonthSummary>,
          MonthSummary,
          Stream<MonthSummary>
        >
    with $FutureModifier<MonthSummary>, $StreamProvider<MonthSummary> {
  /// Totais do mês selecionado.
  MonthSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthSummaryHash();

  @$internal
  @override
  $StreamProviderElement<MonthSummary> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MonthSummary> create(Ref ref) {
    return monthSummary(ref);
  }
}

String _$monthSummaryHash() => r'c79a2a490a94a086062ffd4d5433e478b33a200d';

/// Gastos do mês selecionado por categoria, do maior para o menor.

@ProviderFor(expensesByCategory)
final expensesByCategoryProvider = ExpensesByCategoryProvider._();

/// Gastos do mês selecionado por categoria, do maior para o menor.

final class ExpensesByCategoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategoryTotal>>,
          List<CategoryTotal>,
          Stream<List<CategoryTotal>>
        >
    with
        $FutureModifier<List<CategoryTotal>>,
        $StreamProvider<List<CategoryTotal>> {
  /// Gastos do mês selecionado por categoria, do maior para o menor.
  ExpensesByCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expensesByCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expensesByCategoryHash();

  @$internal
  @override
  $StreamProviderElement<List<CategoryTotal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CategoryTotal>> create(Ref ref) {
    return expensesByCategory(ref);
  }
}

String _$expensesByCategoryHash() =>
    r'4dfc3e1cd78afb15f4a5a987691f0a0b9004a604';

/// Despesas dos 6 meses que terminam no mês selecionado.

@ProviderFor(monthlyExpenses)
final monthlyExpensesProvider = MonthlyExpensesProvider._();

/// Despesas dos 6 meses que terminam no mês selecionado.

final class MonthlyExpensesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MonthTotal>>,
          List<MonthTotal>,
          Stream<List<MonthTotal>>
        >
    with $FutureModifier<List<MonthTotal>>, $StreamProvider<List<MonthTotal>> {
  /// Despesas dos 6 meses que terminam no mês selecionado.
  MonthlyExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyExpensesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyExpensesHash();

  @$internal
  @override
  $StreamProviderElement<List<MonthTotal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MonthTotal>> create(Ref ref) {
    return monthlyExpenses(ref);
  }
}

String _$monthlyExpensesHash() => r'2c01458d86ffdf05a29e16ea26a37f683443add5';
