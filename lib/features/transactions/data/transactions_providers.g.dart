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
