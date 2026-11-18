import 'package:desengastando/core/date/year_month.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_month_provider.g.dart';

/// Mês em foco no app, compartilhado entre Resumo e Lançamentos.
@Riverpod(keepAlive: true)
class SelectedMonth extends _$SelectedMonth {
  @override
  YearMonth build() => YearMonth.now();

  void previous() => state = state.previous;

  void next() => state = state.next;

  void goToCurrent() => state = YearMonth.now();
}
