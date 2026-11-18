// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_month_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mês em foco no app, compartilhado entre Resumo e Lançamentos.

@ProviderFor(SelectedMonth)
final selectedMonthProvider = SelectedMonthProvider._();

/// Mês em foco no app, compartilhado entre Resumo e Lançamentos.
final class SelectedMonthProvider
    extends $NotifierProvider<SelectedMonth, YearMonth> {
  /// Mês em foco no app, compartilhado entre Resumo e Lançamentos.
  SelectedMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedMonthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedMonthHash();

  @$internal
  @override
  SelectedMonth create() => SelectedMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(YearMonth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<YearMonth>(value),
    );
  }
}

String _$selectedMonthHash() => r'dfd5e27fac50ab58adb28624219116db87079cdb';

/// Mês em foco no app, compartilhado entre Resumo e Lançamentos.

abstract class _$SelectedMonth extends $Notifier<YearMonth> {
  YearMonth build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<YearMonth, YearMonth>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<YearMonth, YearMonth>,
              YearMonth,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
